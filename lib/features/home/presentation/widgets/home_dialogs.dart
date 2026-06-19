import 'package:tripship/core/config/app_routes.dart';
import 'package:tripship/core/config/domain_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tripship/core/widgets/tripship_dialog.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

/// Centralized dialog helpers for the HomeScreen.
/// Extracted to reduce HomeScreen line count.
class HomeDialogs {
  HomeDialogs._();

  /// Shows dialog when user tries to switch to driver mode but isn't registered.
  static void showRegistrationRequired(BuildContext context, {String? status}) {
    final l10n = AppLocalizations.of(context)!;
    
    // Check if application is pending
    if (status == DomainConfig.statusPending) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.applicationPending),
          content: Text(l10n.waitAdminApproval),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    // Check if application was rejected
    if (status == DomainConfig.statusRejected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.applicationRejected),
          content: Text(l10n.cannotReapply),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    // Show registration dialog for 'none' status
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.driverAccessRestricted),
        content: Text(l10n.mustBeVerifiedTraveler),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              context.push(AppRoutes.travelerRegistration);
            },
            child: Text(l10n.registerNow),
          ),
        ],
      ),
    );
  }

  /// Shows dialog when traveler application is still pending.
  static void showApplicationPending(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.applicationPending),
        content: Text(l10n.waitAdminApproval),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  /// Shows dialog when a feature requires company approval.
  static void showCompanyOnly(BuildContext context, {String? status}) {
    final l10n = AppLocalizations.of(context)!;
    
    // Check if application is pending
    if (status == DomainConfig.statusPending) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.applicationPending),
          content: Text(l10n.waitAdminApproval),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    // Check if application was rejected
    if (status == DomainConfig.statusRejected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.applicationRejected),
          content: Text(l10n.cannotReapply),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    // Show registration dialog for 'none' status
    TripShipDialog.show(
      context,
      title: l10n.companyOnlyFeatureTitle,
      content: l10n.companyOnlyFeatureBody,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.registerNow,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        Navigator.pop(context);
        context.push(AppRoutes.companyRegistration);
      },
      icon: Icons.business_center_outlined,
    );
  }

  /// Shows dialog when a feature requires driver (with vehicle) registration.
  static void showDriverOnly(BuildContext context, {String? status}) {
    final l10n = AppLocalizations.of(context)!;
    
    // Check if application is pending
    if (status == DomainConfig.statusPending) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.applicationPending),
          content: Text(l10n.waitAdminApproval),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    // Check if application was rejected
    if (status == DomainConfig.statusRejected) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.applicationRejected),
          content: Text(l10n.cannotReapply),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    // Show registration dialog for 'none' status
    TripShipDialog.show(
      context,
      title: l10n.driverOnlyFeatureTitle,
      content: l10n.driverOnlyFeatureBody,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.registerNow,
      onCancel: () => Navigator.pop(context),
      onConfirm: () {
        Navigator.pop(context);
        context.push(AppRoutes.travelerRegistration, extra: true);
      },
      icon: Icons.local_shipping_outlined,
    );
  }

  /// Shows confirm dialog for mode switching.
  static Future<bool?> showSwitchModeConfirm(
    BuildContext context, {
    required bool toClientMode,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmSwitchMode),
        content: Text(
          toClientMode ? l10n.switchToClient : l10n.switchToTraveler,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }
}
