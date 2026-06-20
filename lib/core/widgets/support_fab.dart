import 'package:tripsfactory/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/core/services/app_config_service.dart';
import 'package:tripsfactory/core/utils/l10n_context.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportFab extends ConsumerWidget {
  const SupportFab({super.key});

  Future<void> _contactWhatsApp(WidgetRef ref, String phoneNumber) async {
    HapticFeedback.selectionClick();
    final url =
        'https://wa.me/${phoneNumber.replaceAll('+', '').replaceAll(' ', '')}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSupportOptions(
    BuildContext context,
    WidgetRef ref,
    String whatsAppNumber,
  ) {
    final loc = localizationsOf(context, ref);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.howCanWeHelp,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.confirmation_number_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(loc.openSupportTicket),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.support, extra: {'showNewTicket': true});
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366), // WhatsApp Green
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_outlined, color: Colors.white),
                ),
                title: Text(loc.chatOnWhatsApp),
                onTap: () {
                  Navigator.pop(context);
                  _contactWhatsApp(ref, whatsAppNumber);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider).valueOrNull;
    final whatsAppNumber = config?.supportWhatsApp;
    final theme = Theme.of(context);

    return FloatingActionButton(
      heroTag: 'support_fab',
      onPressed: () {
        HapticFeedback.lightImpact();
        if (whatsAppNumber != null && whatsAppNumber.isNotEmpty) {
          _showSupportOptions(context, ref, whatsAppNumber);
        } else {
          context.push(AppRoutes.support, extra: {'showNewTicket': true});
        }
      },
      backgroundColor: theme.colorScheme.secondaryContainer,
      foregroundColor: theme.colorScheme.onSecondaryContainer,
      child: const Icon(Icons.support_agent),
    );
  }
}
