import 'package:tripship/core/config/app_routes.dart';
import 'package:tripship/core/config/domain_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/profile/data/profile_service.dart';
import 'package:tripship/core/widgets/tripship_dialog.dart';
import 'package:tripship/core/widgets/account_suspended_banner.dart';
import 'package:tripship/features/profile/data/profile_model.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/features/profile/presentation/widgets/profile_details_form.dart';
import 'package:tripship/core/providers/app_mode_provider.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/core/widgets/notification_bell_button.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  String _companyStatus = 'none';
  Profile? _profileData;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final profileService = ref.read(profileServiceProvider);
      final profile = await profileService.getProfile(user.id);
      final status = await profileService.getCompanyStatus(user.id);

      if (profile != null) {
        if (mounted) {
          setState(() {
            _nameController.text = profile.fullName;
            _phoneController.text = profile.phoneNumber ?? '';
            _bioController.text = profile.bio ?? '';
            // Account Type is now derived from status or legacy value
            _companyStatus = status;
            _profileData = profile;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(
                e,
                AppLocalizations.of(context)!.errorLoadingProfile,
                context,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final user = ref.read(authServiceProvider).currentUser;
    final localizations = AppLocalizations.of(context)!;

    if (user != null) {
      try {
        await ref
            .read(profileServiceProvider)
            .updateProfile(
              userId: user.id,
              fullName: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              bio: _bioController.text.trim(),
              accountType: _companyStatus == DomainConfig.statusApproved
                  ? DomainConfig.accountCompany
                  : DomainConfig.accountIndividual, // Legacy support
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.profileUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, st) {
        StructuredLogger.error('ProfileScreen', 'Profile save error', e, st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                getUserFriendlyMessage(
                  e,
                  AppLocalizations.of(context)!.errorSavingProfile,
                  context,
                ),
              ),
            ),
          );
        }
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _confirmLogout() async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => TripShipDialog(
        title: localizations.logout,
        content: localizations.logoutConfirmation,
        cancelLabel: localizations.cancel,
        confirmLabel: localizations.logout,
        isDestructive: true,
        icon: Icons.logout,
        onCancel: () => Navigator.pop(context, false),
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed == true) {
      ref.read(authServiceProvider).signOut();
    }
  }

  Future<void> _handleCompanyUpgrade() async {
    final localizations = AppLocalizations.of(context)!;
    
    // Check current status
    if (_companyStatus == DomainConfig.statusPending) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.applicationPending),
          content: Text(localizations.waitAdminApproval),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    if (_companyStatus == DomainConfig.statusRejected) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.applicationRejected),
          content: Text(localizations.cannotReapply),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    if (_companyStatus == DomainConfig.statusApproved) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.alreadyApproved),
          content: Text(localizations.alreadyCompanyAccount),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    // Navigate to registration
    if (mounted) {
      context
          .push(AppRoutes.companyRegistration)
          .then((_) => _loadProfile());
    }
  }

  Future<void> _handleDriverUpgrade() async {
    final localizations = AppLocalizations.of(context)!;
    
    if (_profileData == null) return;
    
    // Check current status
    if (_profileData!.travelerStatus == DomainConfig.statusPending) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.applicationPending),
          content: Text(localizations.waitAdminApproval),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    if (_profileData!.travelerStatus == DomainConfig.statusRejected) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.applicationRejected),
          content: Text(localizations.cannotReapply),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    if (_profileData!.travelerStatus == DomainConfig.statusApproved && _profileData!.isDriver) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.alreadyApproved),
          content: Text(localizations.alreadyDriverAccount),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    // Navigate to registration
    if (mounted) {
      context
          .push(
            AppRoutes.travelerRegistration,
            extra: true,
          )
          .then((_) => _loadProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          localizations.myProfile,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (ref.watch(isClientModeProvider))
            NotificationBellButton(iconColor: Colors.white),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(authServiceProvider).currentUser;

    return Stack(
      children: [
        // Gradient Background
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColorDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Icon(
                  Icons.person,
                  size: 150,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),

        // Main Content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              children: [
                if (_profileData != null &&
                    (_profileData!.isSuspended ||
                        (ref.read(isClientModeProvider)
                            ? _companyStatus == DomainConfig.statusSuspended
                            : _profileData!.travelerStatus == DomainConfig.statusSuspended)))
                  const AccountSuspendedBanner(),

                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _updateAvatar,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            backgroundImage:
                                (_profileData?.avatarUrl != null &&
                                    _profileData!.avatarUrl!.trim().isNotEmpty)
                                ? CachedNetworkImageProvider(
                                    _profileData!.avatarUrl!,
                                  )
                                : null,
                            child:
                                (_profileData?.avatarUrl == null ||
                                    _profileData!.avatarUrl!.trim().isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context).primaryColor,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale().fadeIn(),
                ),
                if (_profileData?.identityDocUrl != null &&
                    _companyStatus != DomainConfig.statusApproved) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: Colors.green,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          localizations.identityVerified,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(),
                ],
                const SizedBox(height: 24),

                // Profile Form Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ProfileDetailsForm(
                        user: user,
                        localizations: localizations,
                        formKey: _formKey,
                        nameController: _nameController,
                        phoneController: _phoneController,
                        bioController: _bioController,
                      ),

                      const SizedBox(height: 24),

                      _buildRatingsSection(localizations),

                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                localizations.save,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      // --- Account Upgrade / Status Section ---
                      if (ref.watch(isClientModeProvider)) ...[
                        // SENDER MODE: Company Upgrade
                        if (_companyStatus == DomainConfig.statusApproved) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.business, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    localizations.verifiedCompanyAccount,
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ] else if (_companyStatus == DomainConfig.statusPending) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.hourglass_empty,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    localizations.applicationPending,
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_companyStatus == DomainConfig.statusRejected) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    localizations.applicationRejected,
                                    style: TextStyle(
                                      color: Colors.red[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Company Upgrade Button
                          OutlinedButton.icon(
                            onPressed: () => _handleCompanyUpgrade(),
                            icon: const Icon(Icons.business),
                            label: Text(localizations.upgradeToBusiness),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        // TRAVELER MODE: Driver Upgrade
                        if (_profileData != null &&
                            !_profileData!.isDriver) ...[
                          if (_profileData!.travelerStatus == DomainConfig.statusPending) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.hourglass_empty,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      localizations.applicationPending,
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_profileData!.travelerStatus == DomainConfig.statusRejected) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      localizations.applicationRejected,
                                      style: TextStyle(
                                        color: Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            OutlinedButton.icon(
                              onPressed: () => _handleDriverUpgrade(),
                              icon: const Icon(Icons.drive_eta),
                              label: Text(
                                localizations.upgradeToDriver,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],

                      // Driver Validity Section
                      if (_profileData?.subscriptionExpiresAt != null ||
                          _profileData?.licenseExpiresAt != null) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          localizations.travelerStatus,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_profileData?.subscriptionExpiresAt != null)
                          _buildValidityItem(
                            icon: Icons.subscriptions,
                            label: localizations.subscriptionExpiry,
                            date: _profileData!.subscriptionExpiresAt!,
                          ),
                        const SizedBox(height: 8),
                        if (_profileData?.licenseExpiresAt != null)
                          _buildValidityItem(
                            icon: Icons.badge,
                            label: localizations.licenseExpiry,
                            date: _profileData!.licenseExpiresAt!,
                          ),
                      ],

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Settings, My Alerts (sender only), Logout
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: Text(localizations.settings),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.push(AppRoutes.settings),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      if (ref.watch(isClientModeProvider))
                        ListTile(
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          title: Text(localizations.myAlerts),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => context.push(AppRoutes.myAlerts),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        )
                      else
                        ListTile(
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          title: Text(localizations.myShipmentAlerts),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => context.push(AppRoutes.myShipmentAlerts),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: Text(
                          localizations.logout,
                          style: const TextStyle(color: Colors.red),
                        ),
                        onTap: _confirmLogout,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsSection(AppLocalizations localizations) {
    final isClientMode = ref.watch(isClientModeProvider);
    final profileData = _profileData;

    if (profileData == null) return const SizedBox.shrink();

    // Get ratings based on mode
    final double rating;
    final int count;

    if (isClientMode) {
      rating = (profileData.clientRatingAvg ?? 0.0).toDouble();
      count = profileData.clientRatingCount ?? 0;
    } else {
      rating = (profileData.travelerRatingAvg ?? 0.0).toDouble();
      count = profileData.travelerRatingCount ?? 0;
    }

    final title = isClientMode
        ? localizations.clientRating
        : localizations.driverRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.ratings,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            // Navigate to ratings detail screen
            context.push(
              '/ratings-detail',
              extra: {
                'userId': ref.read(authServiceProvider).currentUser?.id,
                'isClient': isClientMode,
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: _buildRatingCard(context, title, rating, count),
        ),
      ],
    );
  }

  Widget _buildRatingCard(
    BuildContext context,
    String title,
    dynamic rating,
    dynamic count,
  ) {
    final double? avg = rating != null
        ? (rating is int ? rating.toDouble() : rating)
        : 0.0;
    final int cnt = count ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                avg?.toStringAsFixed(1) ?? "0.0",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "$cnt ${AppLocalizations.of(context)!.reviews}",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildValidityItem({
    required IconData icon,
    required String label,
    required DateTime date,
  }) {
    final isExpired = date.isBefore(DateTime.now());
    final color = isExpired ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  date.toString().split(' ')[0],
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          if (isExpired)
            const Icon(Icons.warning_amber, color: Colors.red, size: 20),
        ],
      ),
    );
  }

  Future<void> _updateAvatar() async {
    final localizations = AppLocalizations.of(context)!;

    // Check restriction
    if (_profileData != null && !_profileData!.canUpdateAvatar) {
      final days = _profileData!.daysUntilNextAvatarUpdate;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${localizations.avatarUpdateRestricted} $days ${localizations.days}.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(localizations.camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(localizations.gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localizations.uploadingAvatar)));
    }

    try {
      final url = await ref
          .read(profileServiceProvider)
          .updateAvatar(user.id, file);

      if (url != null) {
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.profileUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.uploadFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
