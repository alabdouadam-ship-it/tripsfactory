import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/core/services/app_config_service.dart';
import 'package:tripship/core/services/preferences_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Wraps a child and shows the admin-configured first-launch popup once per
/// version per device. Targeted by the [FirstLaunchPopup.target] field.
class FirstLaunchPopupGate extends ConsumerStatefulWidget {
  final Widget child;
  final bool isDriver;
  final bool isCompany;
  final bool isNewUser;

  const FirstLaunchPopupGate({
    super.key,
    required this.child,
    this.isDriver = false,
    this.isCompany = false,
    this.isNewUser = false,
  });

  @override
  ConsumerState<FirstLaunchPopupGate> createState() =>
      _FirstLaunchPopupGateState();
}

class _FirstLaunchPopupGateState extends ConsumerState<FirstLaunchPopupGate> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_shown) return;
    final config = ref.read(appConfigProvider).valueOrNull;
    final popup = config?.firstLaunchPopup;
    if (popup == null || !popup.active) return;

    // Audience targeting
    final target = popup.target;
    final matches = switch (target) {
      'all' => true,
      'individuals' => !widget.isDriver && !widget.isCompany,
      'drivers' => widget.isDriver,
      'companies' => widget.isCompany,
      'new_users' => widget.isNewUser,
      _ => true,
    };
    if (!matches) return;

    final prefs = ref.read(preferencesServiceProvider);
    final lastVersion = await prefs.getInt('first_launch_popup_seen_version');
    if (lastVersion != null && lastVersion >= popup.version) return;

    if (!mounted) return;
    _shown = true;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final title =
        (isArabic ? popup.titleAr : popup.title) ??
        popup.title ??
        popup.titleAr ??
        '';
    final body =
        (isArabic ? popup.bodyAr : popup.body) ??
        popup.body ??
        popup.bodyAr ??
        '';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (popup.imageUrl != null && popup.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      popup.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, st) => const SizedBox.shrink(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(body, style: Theme.of(ctx).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                      if (popup.actionUrl != null &&
                          popup.actionUrl!.isNotEmpty)
                        FilledButton(
                          onPressed: () async {
                            final url = Uri.tryParse(popup.actionUrl!);
                            if (url != null) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          },
                          child: const Text('Open'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await prefs.setInt('first_launch_popup_seen_version', popup.version);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
