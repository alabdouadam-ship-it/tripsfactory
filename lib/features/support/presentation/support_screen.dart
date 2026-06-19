import 'package:tripship/core/config/app_routes.dart';
import 'package:tripship/core/config/brand_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/features/support/data/support_service.dart';
import 'package:tripship/features/support/presentation/widgets/support_ticket_item.dart';
import 'package:tripship/core/utils/l10n_context.dart';
import 'package:tripship/core/services/app_config_service.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

const _kFaqUrl = 'https://tripship.example.com/faq';

class SupportScreen extends ConsumerStatefulWidget {
  final bool showNewTicket;
  final String? focusTicketId;

  const SupportScreen({
    super.key,
    this.showNewTicket = false,
    this.focusTicketId,
  });

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  bool _isLoading = true;
  List<SupportTicket> _tickets = [];
  bool _focusHandled = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
    if (widget.showNewTicket) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNewTicketDialog();
      });
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await ref.read(supportServiceProvider).getMyTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
        _openFocusedTicketIfNeeded(tickets);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final loc = localizationsOf(context, ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(e, loc.unexpectedError, context),
            ),
          ),
        );
      }
    }
  }

  void _openFocusedTicketIfNeeded(List<SupportTicket> tickets) {
    final focusTicketId = widget.focusTicketId;
    if (_focusHandled || focusTicketId == null) return;
    final matches = tickets.where((ticket) => ticket.id == focusTicketId);
    if (matches.isEmpty) return;
    _focusHandled = true;
    final ticket = matches.first;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.push(AppRoutes.supportChat, extra: ticket);
      if (mounted) _loadTickets();
    });
  }

  Future<void> _openFaq() async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(_kFaqUrl);
    if (await canLaunchUrl(uri)) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        StructuredLogger.error(
          'SupportScreen',
          'Could not silently launch URL: $uri',
          null,
          null,
        );
      }
    }
  }

  Future<void> _contactWhatsApp() async {
    HapticFeedback.selectionClick();
    final configAsync = ref.read(appConfigProvider);
    final phoneNumber =
        configAsync.value?.supportWhatsApp ?? BrandConfig.supportWhatsAppFallback; // Fallback
    final url =
        'https://wa.me/${phoneNumber.replaceAll('+', '').replaceAll(' ', '')}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        StructuredLogger.error(
          'SupportScreen',
          'Could not silently launch WhatsApp: $uri',
          null,
          null,
        );
      }
    }
  }

  void _showNewTicketDialog() async {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    final loc = localizationsOf(context, ref);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.newTicket),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: InputDecoration(hintText: loc.subject),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(hintText: loc.supportMessage),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final subject = subjectController.text.trim();
              final message = messageController.text.trim();
              if (subject.isEmpty || message.isEmpty) return;

              Navigator.pop(context);
              _createTicket(subject, message);
            },
            child: Text(loc.createTicket),
          ),
        ],
      ),
    );
    subjectController.dispose();
    messageController.dispose();
  }

  Future<void> _createTicket(String subject, String message) async {
    try {
      final ticket = await ref
          .read(supportServiceProvider)
          .createTicket(subject: subject, message: message);
      if (mounted) {
        _loadTickets();
        context.push(AppRoutes.supportChat, extra: ticket);
      }
    } catch (e) {
      if (mounted) {
        final loc = localizationsOf(context, ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(e, loc.unexpectedError, context),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = localizationsOf(context, ref);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.helpAndSupport),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _openFaq,
            tooltip: loc.faq,
          ),
          if (ref.watch(appConfigProvider).value?.supportWhatsApp?.isNotEmpty ??
              false)
            IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: _contactWhatsApp,
              tooltip: 'WhatsApp',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.support_agent,
                            size: 64,
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(loc.noTicketsFound),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showNewTicketDialog,
                            icon: const Icon(Icons.add),
                            label: Text(loc.newTicket),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        return SupportTicketItem(
                          ticket: _tickets[index],
                          onTap: () async {
                            await context.push(
                              AppRoutes.supportChat,
                              extra: _tickets[index],
                            );
                            _loadTickets(); // Refresh list to update unread counts/dates
                          },
                        );
                      },
                    ),
            ),
      floatingActionButton: _tickets.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showNewTicketDialog,
              icon: const Icon(Icons.add),
              label: Text(loc.newTicket),
            )
          : null,
    );
  }
}
