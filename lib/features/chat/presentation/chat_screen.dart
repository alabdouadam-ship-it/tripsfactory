import 'package:tripship/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tripship/features/chat/data/chat_model.dart';
import 'package:tripship/features/chat/data/chat_message_paging.dart';
import 'package:tripship/features/chat/data/chat_service.dart';
import 'package:tripship/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:tripship/features/safety/data/safety_service.dart';
import 'package:tripship/core/services/notification_service.dart';
import 'package:tripship/core/providers/app_localizations_provider.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/utils/input_validators.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/core/utils/format_utils.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tripship/features/chat/presentation/widgets/signed_chat_image.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/chat/presentation/widgets/audio_message_bubble.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/core/widgets/platform_secure_banner.dart';
import 'package:tripship/features/trips/data/trip_model.dart';
import 'package:tripship/features/trips/data/trip_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? bookingId;
  final String? tripId;
  final String? driverId;
  final String otherUserName;
  final String otherUserId;

  const ChatScreen({
    super.key,
    this.bookingId,
    this.tripId,
    this.driverId,
    required this.otherUserName,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const String _logTag = 'ChatScreen';
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  String?
  _bookingId; // May be set after first message (when opening without existing booking)
  List<ChatMessage> _serverMessages = [];
  final List<ChatMessage> _pendingMessages = [];

  final ScrollController _scrollController = ScrollController();
  // Pagination: load older history above the live (capped) realtime window.
  bool _isLoadingOlder = false;
  bool _hasMoreOlder = true;

  StreamSubscription<List<ChatMessage>>? _messageStreamSubscription;
  StreamSubscription<bool>? _isBlockedBySubscription;
  StreamSubscription<bool>? _hasBlockedSubscription;

  bool _isLoading = true;
  bool _isLocationSharing = false;
  bool _isBlockedByOther = false;
  bool _hasBlockedOther = false;

  // Audio Recording State
  bool _isRecording = false;
  Timer? _recordTimer;
  int _recordDuration = 0;
  String? _recordPath;

  // Booking status: image send allowed only when booking is approved (accepted or later)
  BookingStatus? _bookingStatus;
  // Trip context for the banner
  Trip? _tripContext;

  String? get _effectiveBookingId => _bookingId ?? widget.bookingId;

  /// True when the user can send images (only after booking is approved, not when inCommunication).
  bool get _canSendImages {
    if (_bookingStatus == null) return false;
    switch (_bookingStatus!) {
      case BookingStatus.accepted:
      case BookingStatus.inTransit:
      case BookingStatus.delivered:
      case BookingStatus.completed:
        return true;
      case BookingStatus.pending:
      case BookingStatus.inCommunication:
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _scrollController.addListener(_onScroll);
    if (_effectiveBookingId != null) {
      _subscribeToMessageStream();
      _loadBookingStatus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatServiceProvider).markMessagesAsRead(_effectiveBookingId!);
      });
    } else {
      _isLoading = false;
    }
    _loadTripContext();

    final safetyService = ref.read(safetyServiceProvider);
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

  void _subscribeToMessageStream() {
    final bid = _effectiveBookingId;
    if (bid == null) return;
    _messageStreamSubscription?.cancel();
    _messageStreamSubscription = ref
        .read(chatServiceProvider)
        .getMessages(bid)
        .listen(
          (List<ChatMessage> newMessages) {
            if (!mounted) return;
            final prevCount = _serverMessages.length;
            final hadNewFromOther =
                _serverMessages.isNotEmpty &&
                newMessages.isNotEmpty &&
                !newMessages.first.isMe &&
                !_serverMessages.any((m) => m.id == newMessages.first.id);
            setState(() {
              // Upsert into the accumulated set (keyed by id, newest first) so a
              // shifting live window never drops already-seen messages, and any
              // paged-in older history merges without gaps or duplicates.
              _serverMessages = upsertMessagesDesc(_serverMessages, newMessages);
              _isLoading = false;
              // Remove optimistic pending when server confirms (new message from
              // me arrived and the accumulated set grew).
              if (_pendingMessages.isNotEmpty &&
                  newMessages.isNotEmpty &&
                  newMessages.first.isMe &&
                  _serverMessages.length > prevCount) {
                _pendingMessages.removeAt(0);
              }
            });
            if (hadNewFromOther) {
              SystemSound.play(SystemSoundType.alert);
            }
            _loadBookingStatus();
          },
          onError: (e) {
            if (mounted) setState(() => _isLoading = false);
            StructuredLogger.error(_logTag, 'Chat message stream error', e);
          },
        );
  }

  /// Triggers loading older history as the user scrolls toward the top of the
  /// (reversed) list, i.e. near maxScrollExtent.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder || !_hasMoreOlder) return;
    final bid = _effectiveBookingId;
    if (bid == null || _serverMessages.isEmpty) return;
    setState(() => _isLoadingOlder = true);
    try {
      final cursor = _serverMessages.last.createdAt;
      final older = await ref
          .read(chatServiceProvider)
          .fetchOlderMessages(bid, before: cursor, limit: kChatPageSize);
      if (!mounted) return;
      setState(() {
        _serverMessages = upsertMessagesDesc(_serverMessages, older);
        if (older.length < kChatPageSize) _hasMoreOlder = false;
        _isLoadingOlder = false;
      });
    } catch (e) {
      StructuredLogger.error(_logTag, 'Chat loadOlderMessages error', e);
      if (mounted) setState(() => _isLoadingOlder = false);
    }
  }

  Future<void> _loadBookingStatus() async {
    try {
      final bid = _effectiveBookingId!;
      final statusResult = await ref
          .read(bookingRepositoryProvider)
          .getBookingStatus(bid);
      final status = statusResult.fold((s) => s, (e) => null);

      if (mounted) {
        setState(() {
          _bookingStatus = status;
        });
      }
    } catch (e) {
      StructuredLogger.error(_logTag, 'Chat getBookingStatus error', e);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.unexpectedError),
          ),
        );
      }
    }
  }

  Future<String?> _getRecipientRole(String bookingId) async {
    final roleResult = await ref
        .read(bookingRepositoryProvider)
        .getRecipientRoleForUser(bookingId, widget.otherUserId);
    return roleResult.fold((role) => role, (error) => throw error);
  }

  Future<String> _createBookingWithFirstMessage({
    required String tripId,
    required String driverId,
    required String firstMessageContent,
    String? type,
    Map<String, dynamic>? metadata,
  }) async {
    final result = await ref
        .read(bookingRepositoryProvider)
        .createBookingWithFirstMessage(
          tripId: tripId,
          driverId: driverId,
          firstMessageContent: firstMessageContent,
          type: type,
          metadata: metadata,
        );
    return result.fold((id) => id, (error) => throw error);
  }

  Future<void> _loadTripContext() async {
    final tripId = widget.tripId;
    if (tripId == null || tripId.isEmpty) return;
    try {
      final trip = await ref.read(tripServiceProvider).getTripById(tripId);
      if (mounted && trip != null) {
        setState(() => _tripContext = trip);
      }
    } catch (e) {
      StructuredLogger.error(_logTag, 'Chat loadTripContext error', e);
    }
  }

  @override
  void dispose() {
    _messageStreamSubscription?.cancel();
    _isBlockedBySubscription?.cancel();
    _hasBlockedSubscription?.cancel();
    _audioRecorder.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _recordTimer?.cancel();
    super.dispose();
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
      StructuredLogger.error(_logTag, 'Error starting recording', e);
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    setState(() => _isRecording = false);

    try {
      final path = await _audioRecorder.stop();
      if (path != null && _recordDuration > 0) {
        // Send the audio message
        await _sendAudioMessage(path, _recordDuration);
      }
    } catch (e) {
      StructuredLogger.error(_logTag, 'Error stopping recording', e);
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
      StructuredLogger.error(_logTag, 'Error cancelling recording', e);
    }
  }

  String _formatDuration(int duration) {
    return FormatUtils.formatDuration(duration);
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickAndSendImage() async {
    if (!_canSendImages || _effectiveBookingId == null) return;
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null || !mounted) return;
      final path = picked.path;
      final file = File(path);
      if (!await file.exists()) return;

      final bid = _effectiveBookingId!;
      final tempId = 'temp_img_${DateTime.now().millisecondsSinceEpoch}';
      final tempMsg = ChatMessage(
        id: tempId,
        bookingId: bid,
        senderId: 'me',
        content: path,
        createdAt: DateTime.now(),
        type: 'image',
        metadata: {},
        isMe: true,
        isRead: false,
      );
      setState(() => _pendingMessages.insert(0, tempMsg));

      final publicUrl = await ref.read(chatServiceProvider).uploadImage(file);
      if (!mounted) return;
      await ref
          .read(chatServiceProvider)
          .sendMessage(bid, publicUrl, type: 'image');

      final l10n = ref.read(appLocalizationsProvider);
      final recipientRole = await _getRecipientRole(bid);
      final me = ref.read(authServiceProvider).currentUser;
      final myName = me?.userMetadata?['full_name'] as String? ?? l10n.unknown;
      ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: widget.otherUserId,
            title: l10n.notifNewMessage,
            body: '📷 Image',
            data: {
              'type': 'new_message',
              'booking_id': bid,
              'trip_id': widget.tripId,
              'traveler_id': widget.driverId,
              'other_user_name': myName,
              'other_user_id': me?.id ?? '',
            },
            recipientRole: recipientRole,
          )
          .catchError(
            (e) => StructuredLogger.error(
              _logTag,
              'Chat image notification failed',
              e,
            ),
          );

      // Realtime stream will update _serverMessages; pending removed in stream listener
      if (mounted) setState(() => _pendingMessages.remove(tempMsg));
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingMessages.removeWhere((m) => m.id.startsWith('temp_img_'));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.unexpectedError),
          ),
        );
      }
    }
  }

  Future<void> _sendLocation() async {
    if (!_canSendImages || _effectiveBookingId == null || _isLocationSharing) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLocationSharing = true);

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
      final bid = _effectiveBookingId!;
      final content = '${position.latitude},${position.longitude}';

      final tempId = 'temp_loc_${DateTime.now().millisecondsSinceEpoch}';
      final tempMsg = ChatMessage(
        id: tempId,
        bookingId: bid,
        senderId: 'me',
        content: content,
        createdAt: DateTime.now(),
        type: 'location',
        metadata: {},
        isMe: true,
        isRead: false,
      );
      setState(() => _pendingMessages.insert(0, tempMsg));

      await ref
          .read(chatServiceProvider)
          .sendMessage(bid, content, type: 'location');
      if (!mounted) return;

      // Notify recipient
      final recipientRole = await _getRecipientRole(bid);
      final me = ref.read(authServiceProvider).currentUser;
      final myName = me?.userMetadata?['full_name'] as String? ?? l10n.unknown;

      ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: widget.otherUserId,
            title: l10n.notifNewMessage,
            body: '📍 ${l10n.locationShared}',
            data: {
              'type': 'new_message',
              'booking_id': bid,
              'trip_id': widget.tripId,
              'traveler_id': widget.driverId,
              'other_user_name': myName,
              'other_user_id': me?.id ?? '',
            },
            recipientRole: recipientRole,
          )
          .catchError(
            (e) => StructuredLogger.error(
              _logTag,
              'Chat location notification failed',
              e,
            ),
          );

      if (mounted) setState(() => _pendingMessages.remove(tempMsg));
    } catch (e) {
      if (mounted) {
        setState(() {
          _pendingMessages.removeWhere((m) => m.id.startsWith('temp_loc_'));
        });
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
      if (mounted) setState(() => _isLocationSharing = false);
    }
  }

  void _showMediaMenu() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                title: Text(l10n.sendImage),
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
                title: Text(l10n.shareLocation),
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

  Future<void> _sendAudioMessage(String path, int duration) async {
    String? bid = _effectiveBookingId;
    final tripId = widget.tripId;
    final driverId = widget.driverId;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessage(
      id: tempId,
      bookingId: bid ?? '',
      senderId: 'me',
      content: path, // Local path for now
      createdAt: DateTime.now(),
      type: 'audio',
      metadata: {'duration': duration},
      isMe: true,
      isRead: false,
    );

    setState(() {
      _pendingMessages.insert(0, tempMsg);
    });

    try {
      final file = File(path);
      final publicUrl = await ref.read(chatServiceProvider).uploadAudio(file);

      final l10n = ref.read(appLocalizationsProvider);
      final me = ref.read(authServiceProvider).currentUser;
      final myName = me?.userMetadata?['full_name'] as String? ?? l10n.unknown;

      if (bid == null && tripId != null && driverId != null) {
        bid = await _createBookingWithFirstMessage(
          tripId: tripId,
          driverId: driverId,
          firstMessageContent: publicUrl,
          type: 'audio',
          metadata: {'duration': duration},
        );
        if (mounted) {
          setState(() {
            _bookingId = bid;
            _pendingMessages.clear();
            _serverMessages = [];
            _hasMoreOlder = true;
          });
          _subscribeToMessageStream();
          _loadBookingStatus();
          ref.read(chatServiceProvider).markMessagesAsRead(bid);

          final recipientRole = await _getRecipientRole(bid);
          ref
              .read(notificationServiceProvider)
              .sendNotificationToUser(
                userId: widget.otherUserId,
                title: l10n.notifNewMessage,
                body:
                    "🎤 ${l10n.voiceMessage}", // Just use emoji and localized test for push notification
                data: {
                  'type': 'new_message',
                  'booking_id': bid,
                  'trip_id': widget.tripId,
                  'traveler_id': widget.driverId,
                  'other_user_name': myName,
                  'other_user_id': me?.id ?? '',
                },
                recipientRole: recipientRole,
              )
              .catchError((e) => debugPrint('Chat notification failed: $e'));
        }
      } else if (bid != null) {
        await ref
            .read(chatServiceProvider)
            .sendMessage(
              bid,
              publicUrl,
              type: 'audio',
              metadata: {'duration': duration},
            );

        if (!mounted) return;

        final recipientRole = await _getRecipientRole(bid);
        ref
            .read(notificationServiceProvider)
            .sendNotificationToUser(
              userId: widget.otherUserId,
              title: l10n.notifNewMessage,
              body: "🎤 ${l10n.voiceMessage}",
              data: {
                'type': 'new_message',
                'booking_id': bid,
                'trip_id': widget.tripId,
                'traveler_id': widget.driverId,
                'other_user_name': myName,
                'other_user_id': me?.id ?? '',
              },
              recipientRole: recipientRole,
            )
            .catchError(
              (e) => StructuredLogger.error(
                _logTag,
                'Chat audio notification failed',
                e,
              ),
            );

        if (mounted) setState(() => _pendingMessages.remove(tempMsg));
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _pendingMessages.remove(tempMsg));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${l10n.failedToSendMessage}: $e")),
      );
    }
  }

  Future<void> _sendMessage() async {
    final raw = _controller.text;
    final text = validateMessage(raw);
    if (text == null || text.isEmpty) return;

    String? bid = _effectiveBookingId;
    final tripId = widget.tripId;
    final driverId = widget.driverId;

    // First message without booking: create booking + message
    if (bid == null && tripId != null && driverId != null) {
      setState(() {
        _pendingMessages.insert(
          0,
          ChatMessage(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            bookingId: '',
            senderId: 'me',
            content: text,
            createdAt: DateTime.now(),
            isMe: true,
            isRead: false,
          ),
        );
        _controller.clear();
      });
      try {
        bid = await _createBookingWithFirstMessage(
          tripId: tripId,
          driverId: driverId,
          firstMessageContent: text,
        );
        if (mounted) {
          setState(() {
            _bookingId = bid;
            _pendingMessages.clear();
            _serverMessages = [];
            _hasMoreOlder = true;
          });
          _subscribeToMessageStream();
          _loadBookingStatus();
          ref.read(chatServiceProvider).markMessagesAsRead(bid);
          final l10n = ref.read(appLocalizationsProvider);
          final recipientRole = await _getRecipientRole(bid);
          final me = ref.read(authServiceProvider).currentUser;
          final myName =
              me?.userMetadata?['full_name'] as String? ?? l10n.unknown;
          ref
              .read(notificationServiceProvider)
              .sendNotificationToUser(
                userId: widget.otherUserId,
                title: l10n.notifNewMessage,
                body: text.length > 50 ? '${text.substring(0, 50)}...' : text,
                data: {
                  'type': 'new_message',
                  'booking_id': bid,
                  'trip_id': widget.tripId,
                  'traveler_id': widget.driverId,
                  'other_user_name': myName,
                  'other_user_id': me?.id ?? '',
                },
                recipientRole: recipientRole,
              )
              .catchError((e) => debugPrint('Chat notification failed: $e'));
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() => _pendingMessages.clear());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                getUserFriendlyMessage(
                  e,
                  AppLocalizations.of(context)!.unexpectedError,
                  context,
                ),
              ),
            ),
          );
        }
        return;
      }
    }

    if (bid == null) return;

    final tempMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bid,
      senderId: 'me',
      content: text,
      createdAt: DateTime.now(),
      isMe: true,
      isRead: false,
    );

    setState(() {
      _pendingMessages.insert(0, tempMsg);
      _controller.clear();
    });

    try {
      await ref.read(chatServiceProvider).sendMessage(bid, text);
      // Notify recipient (المتلقي) — not the sender
      final l10n = ref.read(appLocalizationsProvider);
      final recipientRole = await _getRecipientRole(bid);
      final me = ref.read(authServiceProvider).currentUser;
      final myName = me?.userMetadata?['full_name'] as String? ?? l10n.unknown;
      ref
          .read(notificationServiceProvider)
          .sendNotificationToUser(
            userId: widget.otherUserId,
            title: l10n.notifNewMessage,
            body: text.length > 50 ? '${text.substring(0, 50)}...' : text,
            data: {
              'type': 'new_message',
              'booking_id': bid,
              'trip_id': widget.tripId,
              'traveler_id': widget.driverId,
              'other_user_name': myName,
              'other_user_id': me?.id ?? '',
            },
            recipientRole: recipientRole,
          )
          .catchError(
            (e, st) => StructuredLogger.error(
              _logTag,
              'Chat notification failed: $e',
              e,
              st,
            ),
          );
      // Realtime stream will update _serverMessages; pending removed in stream listener
    } catch (e) {
      if (mounted) {
        setState(() => _pendingMessages.remove(tempMsg));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(
                e,
                AppLocalizations.of(context)!.unexpectedError,
                context,
              ),
            ),
          ),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.reportUser),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.reportUserDescription),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.reportReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              context.pop();
              try {
                final result = await ref
                    .read(safetyServiceProvider)
                    .reportUser(
                      reportedId: widget.otherUserId,
                      reason: reason,
                      comment: 'Booking ID: ${widget.bookingId}',
                    );

                if (context.mounted) {
                  final loc = AppLocalizations.of(context)!;
                  final message = result == ReportResult.reportedAndBlocked
                      ? loc.reportSubmittedBlocked
                      : loc.reportSubmittedCannotBlock;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        getUserFriendlyMessage(
                          e,
                          AppLocalizations.of(context)!.unexpectedError,
                          context,
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.send),
          ),
        ],
      ),
    );
    reasonController.dispose();
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.blockUser),
        content: Text(AppLocalizations.of(context)!.blockUserConfirm),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(safetyServiceProvider)
                    .blockUser(widget.otherUserId);
                if (context.mounted) {
                  setState(() {
                    _hasBlockedOther = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.userBlockedSuccess),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop(); // Close dialog
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        getUserFriendlyMessage(
                          e,
                          AppLocalizations.of(context)!.unexpectedError,
                          context,
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.blockUser),
          ),
        ],
      ),
    );
  }

  bool get _canSendMessage {
    if (_isBlockedByOther || _hasBlockedOther) {
      return false; // Chat disabled if blocked
    }
    if (_bookingStatus == null) {
      return true; // Default to true if not loaded yet (or no booking context)
    }
    switch (_bookingStatus!) {
      case BookingStatus.pending:
      case BookingStatus.inCommunication:
      case BookingStatus.accepted:
      case BookingStatus.inTransit:
      case BookingStatus.delivered:
        return true;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
      case BookingStatus.completed:
        return false;
    }
  }

  String _getDisabledMessage(AppLocalizations loc) {
    if (_isBlockedByOther || _hasBlockedOther) return loc.chatDisabledGeneric;
    if (_bookingStatus == null) return loc.chatDisabledGeneric;
    switch (_bookingStatus!) {
      case BookingStatus.rejected:
        return loc.chatDisabledRejected;
      case BookingStatus.cancelled:
        return loc.chatDisabledCancelled;
      case BookingStatus.completed:
        return loc.chatDisabledCompleted;
      default:
        return loc.chatDisabledGeneric;
    }
  }

  Widget _buildTripContextCard(BuildContext context) {
    final trip = _tripContext!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final loc = AppLocalizations.of(context)!;

    final originLoc = trip.originLocation;
    final destLoc = trip.destLocation;
    final origin = originLoc?.formatLabel(isArabic) ?? loc.unknown;
    final dest = destLoc?.formatLabel(isArabic) ?? loc.unknown;
    final fmtDate = DateFormat.MMMd().add_jm().format(trip.departureTime);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.tripDetails, extra: trip),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$origin → $dest',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmtDate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_canSendMessage)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getDisabledMessage(l10n),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_canSendImages && !_isRecording)
                    IconButton(
                      onPressed: _showMediaMenu,
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: l10n.add,
                    ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _isRecording
                          ? Row(
                              children: [
                                const Icon(
                                      Icons.mic,
                                      color: Colors.red,
                                      size: 20,
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(),
                                    )
                                    .shimmer(duration: 1.seconds),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDuration(_recordDuration),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _cancelRecording,
                                  child: Text(
                                    l10n.cancel,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : TextField(
                              controller: _controller,
                              maxLines: 5,
                              minLines: 1,
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: l10n.typeAMessage,
                                border: InputBorder.none,
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    child: FloatingActionButton.small(
                      onPressed: () {
                        if (_controller.text.trim().isNotEmpty) {
                          _sendMessage();
                        }
                      },
                      elevation: 0,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: const CircleBorder(),
                      child: Icon(
                        _isRecording
                            ? Icons.stop
                            : (_controller.text.isEmpty
                                  ? Icons.mic
                                  : Icons.send),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final displayMessages = [..._pendingMessages, ..._serverMessages];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (!context.mounted) return;
              if (value == 'report') {
                _showReportDialog(context);
              } else if (value == 'block') {
                _showBlockDialog(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(l10n.reportUser),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.blockUser),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          PlatformSecureBanner.chat(context),
          if (_tripContext != null) _buildTripContextCard(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noMessagesYet,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        displayMessages.length + (_isLoadingOlder ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Loader sits at the top of the reversed list (oldest end).
                      if (index >= displayMessages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final msg = displayMessages[index];
                      final nextMsg = index > 0
                          ? displayMessages[index - 1]
                          : null;
                      final prevMsg = index < displayMessages.length - 1
                          ? displayMessages[index + 1]
                          : null;

                      final isFirstInGroup =
                          prevMsg == null || prevMsg.senderId != msg.senderId;
                      final isLastInGroup =
                          nextMsg == null || nextMsg.senderId != msg.senderId;

                      return _buildEnhancedMessageBubble(
                        msg,
                        isFirstInGroup,
                        isLastInGroup,
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEnhancedMessageBubble(
    ChatMessage msg,
    bool isFirstInGroup,
    bool isLastInGroup,
  ) {
    final isMe = msg.isMe;
    final timeStr = DateFormat.jm().format(msg.createdAt.toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (isFirstInGroup) const SizedBox(height: 8),
          Container(
            margin: EdgeInsets.only(
              top: isFirstInGroup ? 4 : 2,
              bottom: isLastInGroup ? 4 : 2,
              left: isMe ? 64 : 0,
              right: isMe ? 0 : 64,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  isMe || (!isMe && isFirstInGroup) ? 16 : 4,
                ),
                topRight: Radius.circular(
                  !isMe || (isMe && isFirstInGroup) ? 16 : 4,
                ),
                bottomLeft: Radius.circular(
                  isMe || (!isMe && isLastInGroup) ? 16 : 4,
                ),
                bottomRight: Radius.circular(
                  !isMe || (isMe && isLastInGroup) ? 16 : 4,
                ),
              ),
              boxShadow: isMe
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
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
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: isMe ? Colors.white : Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.locationShared,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                    if (isMe && msg.id.startsWith('temp_')) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.access_time,
                        size: 10,
                        color: Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 200.ms).slideX(begin: isMe ? 0.1 : -0.1, end: 0);
  }
}
