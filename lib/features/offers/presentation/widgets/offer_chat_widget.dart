import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/chat/data/chat_model.dart';
import 'package:tripship/features/chat/data/chat_message_paging.dart';
import 'package:tripship/features/chat/data/chat_service.dart';
import 'package:tripship/features/safety/data/safety_service.dart';
import 'package:tripship/features/offers/data/offer_providers.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tripship/features/chat/presentation/widgets/signed_chat_image.dart';
import 'package:tripship/features/chat/presentation/widgets/audio_message_bubble.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/utils/error_utils.dart';

/// Inline offer-thread chat widget embedded in shipment/offer details.
/// Handles open (sent/accepted) and closed (rejected/cancelled) states.
class OfferChatWidget extends ConsumerStatefulWidget {
  final String offerId;
  final OfferStatus offerStatus;
  final String otherUserId;

  const OfferChatWidget({
    super.key,
    required this.offerId,
    required this.offerStatus,
    required this.otherUserId,
  });

  @override
  ConsumerState<OfferChatWidget> createState() => _OfferChatWidgetState();
}

class _OfferChatWidgetState extends ConsumerState<OfferChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isSending = false;

  bool _isRecording = false;
  Timer? _recordTimer;
  int _recordDuration = 0;
  String? _recordPath;
  bool _isSendingLocation = false;
  final ImagePicker _imagePicker = ImagePicker();

  StreamSubscription<bool>? _isBlockedBySubscription;
  StreamSubscription<bool>? _hasBlockedSubscription;
  bool _isBlockedByOther = false;
  bool _hasBlockedOther = false;

  // Pagination: live window comes from the (capped) provider; older history is
  // paged in locally and merged.
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _olderMessages = [];
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;

  bool get _isChatActive =>
      (widget.offerStatus == OfferStatus.sent ||
          widget.offerStatus == OfferStatus.accepted) &&
      !_isBlockedByOther &&
      !_hasBlockedOther;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final safetyService = ref.read(safetyServiceProvider);
    if (widget.otherUserId.isNotEmpty) {
      _isBlockedBySubscription = safetyService
          .watchIsBlockedBy(widget.otherUserId)
          .listen((isBlocked) {
            if (mounted) setState(() => _isBlockedByOther = isBlocked);
          });
      _hasBlockedSubscription = safetyService
          .watchHasBlocked(widget.otherUserId)
          .listen((hasBlocked) {
            if (mounted) setState(() => _hasBlockedOther = hasBlocked);
          });
    }
  }

  @override
  void dispose() {
    _isBlockedBySubscription?.cancel();
    _hasBlockedSubscription?.cancel();
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Loads older history as the user scrolls toward the top of the reversed list.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder || !_hasMoreOlder) return;
    final live =
        ref.read(offerMessagesProvider(widget.offerId)).valueOrNull ??
        const <ChatMessage>[];
    final current = upsertMessagesDesc(_olderMessages, live);
    if (current.isEmpty) return;
    setState(() => _isLoadingOlder = true);
    try {
      final cursor = current.last.createdAt;
      final older = await ref
          .read(chatServiceProvider)
          .fetchOlderOfferMessages(
            widget.offerId,
            before: cursor,
            limit: kChatPageSize,
          );
      if (!mounted) return;
      setState(() {
        _olderMessages = upsertMessagesDesc(_olderMessages, older);
        if (older.length < kChatPageSize) _hasMoreOlder = false;
        _isLoadingOlder = false;
      });
    } catch (e) {
      StructuredLogger.error('OfferChatWidget', 'loadOlderMessages error', e);
      if (mounted) setState(() => _isLoadingOlder = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/audio_${const Uuid().v4()}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordPath = path;
          _recordDuration = 0;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
          setState(() => _recordDuration++);
        });
      }
    } catch (e) {
      StructuredLogger.error('OfferChatWidget', 'Error starting recording', e);
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    setState(() => _isRecording = false);
    try {
      final path = await _audioRecorder.stop();
      if (path != null && _recordDuration > 0) {
        await _sendAudioMessage(path, _recordDuration);
      }
    } catch (e) {
      StructuredLogger.error('OfferChatWidget', 'Error stopping recording', e);
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    setState(() => _isRecording = false);
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
      if (_recordPath != null) {
        final file = File(_recordPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      StructuredLogger.error(
        'OfferChatWidget',
        'Error cancelling recording',
        e,
      );
    }
  }

  String _formatDuration(int duration) {
    final minutes = (duration ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _sendAudioMessage(String path, int duration) async {
    setState(() => _isSending = true);
    try {
      final file = File(path);
      final publicUrl = await ref.read(chatServiceProvider).uploadAudio(file);
      await ref
          .read(chatServiceProvider)
          .sendOfferMessage(
            widget.offerId,
            publicUrl,
            type: 'audio',
            metadata: {'duration': duration},
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${AppLocalizations.of(context)!.failedToSendMessage}: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    // Only available when accepted
    if (widget.offerStatus != OfferStatus.accepted) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      if (!await file.exists()) return;

      setState(() => _isSending = true);
      final publicUrl = await ref.read(chatServiceProvider).uploadImage(file);
      await ref
          .read(chatServiceProvider)
          .sendOfferMessage(widget.offerId, publicUrl, type: 'image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.unexpectedError ??
                  'Error sending image',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendLocation() async {
    if (widget.offerStatus != OfferStatus.accepted || _isSendingLocation) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSendingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw l10n.locationServiceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw l10n.locationPermissionDenied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw l10n.locationPermissionDenied;
      }

      final position = await Geolocator.getCurrentPosition();
      final content = '${position.latitude},${position.longitude}';

      await ref
          .read(chatServiceProvider)
          .sendOfferMessage(widget.offerId, content, type: 'location');
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(e, localizations.unexpectedError, context),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingLocation = false);
    }
  }

  void _showMediaMenu() {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image_outlined, color: Colors.blue),
                ),
                title: Text(isArabic ? 'إرسال صورة' : 'Send Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.green,
                  ),
                ),
                title: Text(isArabic ? 'مشاركة الموقع' : 'Share Location'),
                onTap: () {
                  Navigator.pop(context);
                  _sendLocation();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final messagesAsync = ref.watch(offerMessagesProvider(widget.offerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Closed banner
        if (!_isChatActive) _buildClosedBanner(theme, isArabic),

        // ── Messages list
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              final display = upsertMessagesDesc(_olderMessages, messages);
              if (display.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: theme.hintColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isArabic ? 'لا توجد رسائل بعد' : 'No messages yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                reverse: true,
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: _isChatActive
                      ? 8
                      : 8 + MediaQuery.paddingOf(context).bottom,
                ),
                itemCount: display.length + (_isLoadingOlder ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= display.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return _buildMessageBubble(display[index], theme);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                isArabic ? 'خطأ في تحميل الرسائل' : 'Error loading messages',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ),
        ),

        // ── Input field (only when chat is active)
        if (_isChatActive) _buildInputBar(theme, isArabic),
      ],
    );
  }

  Widget _buildClosedBanner(ThemeData theme, bool isArabic) {
    String bannerText;
    switch (widget.offerStatus) {
      case OfferStatus.rejected:
        bannerText = isArabic
            ? 'تم إغلاق المحادثة لأن العرض تم رفضه'
            : 'Chat closed because the offer was rejected';
        break;
      case OfferStatus.completed:
        bannerText = isArabic
            ? 'تم إغلاق المحادثة لأن الشحنة اكتملت'
            : 'Chat closed because the shipment was completed';
        break;
      case OfferStatus.cancelled:
        bannerText = isArabic
            ? 'تم إغلاق المحادثة لأن العرض تم إلغاؤه'
            : 'Chat closed because the offer was cancelled';
        break;
      default:
        bannerText = isArabic ? 'تم إغلاق المحادثة' : 'Chat closed';
    }

    if (_isBlockedByOther || _hasBlockedOther) {
      bannerText = isArabic
          ? 'المحادثة غير متاحة (مستخدم محظور)'
          : 'Chat unavailable (user blocked)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.shade50,
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bannerText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ThemeData theme) {
    final isMe = msg.isMe;
    final timeStr = DateFormat.Hm().format(msg.createdAt.toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (msg.type == 'audio')
              AudioMessageBubble(
                url: msg.content,
                isMe: isMe,
                duration: msg.metadata['duration'] != null
                    ? Duration(seconds: msg.metadata['duration'] as int)
                    : null,
              )
            else if (msg.type == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 240,
                    maxHeight: 280,
                  ),
                  child: msg.content.startsWith('http')
                      ? SignedChatImage(stored: msg.content)
                      : Image.file(File(msg.content), fit: BoxFit.cover),
                ),
              )
            else if (msg.type == 'location')
              InkWell(
                onTap: () async {
                  final coords = msg.content.split(',');
                  if (coords.length != 2) return;
                  final lat = coords[0];
                  final lng = coords[1];
                  final url =
                      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.black.withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.1)
                          : theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: isMe ? Colors.white : theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.locationShared,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isMe
                              ? Colors.white
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text(
                msg.content,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, bool isArabic) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: _isRecording
              ? Row(
                  children: [
                    const Icon(
                      Icons.mic,
                      color: Colors.red,
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recording... ${_formatDuration(_recordDuration)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelRecording,
                      child: Text(
                        isArabic ? 'إلغاء' : 'Cancel',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        isArabic ? 'إرسال' : 'Send',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    if (widget.offerStatus == OfferStatus.accepted) ...[
                      (_isSending || _isSendingLocation)
                          ? const SizedBox(
                              width: 48,
                              height: 48,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _showMediaMenu,
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                              tooltip: isArabic ? 'إرسال وسائط' : 'Send Media',
                            ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (val) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: isArabic
                              ? 'اكتب رسالتك...'
                              : 'Type a message...',
                          hintStyle: TextStyle(
                            color: theme.hintColor,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_controller.text.trim().isEmpty)
                      GestureDetector(
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressEnd: (_) => _stopRecording(),
                        onLongPressCancel: () => _cancelRecording(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                          child: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    else
                      _isSending
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _sendMessage,
                              icon: Icon(
                                Icons.send_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await ref
          .read(chatServiceProvider)
          .sendOfferMessage(widget.offerId, text);
      _controller.clear();
    } catch (_) {
      // Silently fail — message will not appear in stream
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
