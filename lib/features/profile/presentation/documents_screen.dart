import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tripship/core/providers/app_mode_provider.dart';
import 'package:tripship/core/config/domain_config.dart';

import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/profile/data/profile_service.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/utils/l10n_context.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final localizations = localizationsOf(context, ref);
    final isClientMode = ref.watch(isClientModeProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.documents), centerTitle: true),
      body: Stack(
        children: [
          profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return Center(child: Text(localizations.errorLoadingProfile));
              }

              final List<Widget> children = [];

              final service = ref.read(profileServiceProvider);
              final userId = profile.id;

              // Client Documents (Sender / Company)
              if (isClientMode) {
                // Identity Proof (Optional for all clients)
                children.add(
                  _buildDocumentItem(
                    localizations,
                    '${localizations.identityProof} (${localizations.optional})',
                    profile.identityDocUrl,
                    profile.identityDocUrlPending,
                    (url) => service.updateDocumentUrl(
                      userId,
                      'identity_doc_url_pending',
                      url,
                    ),
                    isVerified: profile.identityDocUrl != null,
                  ),
                );

                // Company CR (Mandatory for companies)
                // Show CR Document if user is a company (approved or pending)
                final isVerifiedCompany =
                    profile.accountType == DomainConfig.accountCompany &&
                    profile.companyStatus == DomainConfig.statusApproved;
                if (isVerifiedCompany ||
                    profile.accountType == DomainConfig.accountCompany ||
                    profile.companyStatus != DomainConfig.statusNone ||
                    profile.companyName != null) {
                  children.add(
                    _buildDocumentItem(
                      localizations,
                      '${localizations.crDocument} (${localizations.fieldRequired})',
                      profile.companyCrUrl,
                      profile.companyCrUrlPending,
                      (url) => service.updateDocumentUrl(
                        userId,
                        'company_cr_url_pending',
                        url,
                      ),
                    ),
                  );
                }
              }
              // Traveler Documents (Normal Traveler / Driver)
              else {
                // Identity Proof (Required for all travelers)
                children.add(
                  _buildDocumentItem(
                    localizations,
                    '${localizations.identityProof} (${localizations.fieldRequired})',
                    profile.identityDocUrl,
                    profile.identityDocUrlPending,
                    (url) => service.updateDocumentUrl(
                      userId,
                      'identity_doc_url_pending',
                      url,
                    ),
                    isVerified: profile.identityDocUrl != null,
                  ),
                );

                // Driver (Approved, Pending, or with vehicle)
                if (profile.travelerType == DomainConfig.travelerWithVehicle ||
                    profile.isDriver ||
                    profile.driverLicenseUrl != null ||
                    profile.travelerLicenseUrlPending != null) {
                  // Driver License (Mandatory)
                  children.add(
                    _buildDocumentItem(
                      localizations,
                      '${localizations.driverLicense} (${localizations.fieldRequired})',
                      profile.driverLicenseUrl,
                      profile.travelerLicenseUrlPending,
                      (url) => service.updateDocumentUrl(
                        userId,
                        'traveler_license_url_pending',
                        url,
                      ),
                      isVerified: profile.driverLicenseUrl != null,
                    ),
                  );

                  // Vehicle Docs (Show even if no vehicle record exists yet for drivers)
                  final vehicle = profile.vehicles.isNotEmpty
                      ? profile.vehicles.first
                      : null;

                  // Vehicle Photo (Mandatory)
                  children.add(
                    _buildDocumentItem(
                      localizations,
                      '${localizations.uploadVehiclePhoto} (${localizations.fieldRequired})',
                      vehicle?.photoUrl,
                      vehicle?.vehiclePhotoUrlPending,
                      (url) async {
                        final vId =
                            vehicle?.id ??
                            await service.getOrCreateVehicleId(userId);
                        await service.updateVehicleDocument(
                          vId,
                          'vehicle_photo_url_pending',
                          url,
                        );
                      },
                      isVerified: vehicle?.photoUrl != null,
                    ),
                  );

                  // Vehicle Registration (Mandatory) - "ميكانيك السيارة" in Arabic
                  children.add(
                    _buildDocumentItem(
                      localizations,
                      '${localizations.uploadRegistration} (${localizations.fieldRequired})',
                      vehicle?.registrationDocUrl,
                      vehicle?.registrationDocUrlPending,
                      (url) async {
                        final vId =
                            vehicle?.id ??
                            await service.getOrCreateVehicleId(userId);
                        await service.updateVehicleDocument(
                          vId,
                          'registration_doc_url_pending',
                          url,
                        );
                      },
                      isVerified: vehicle?.registrationDocUrl != null,
                    ),
                  );

                  // Rental Contract (If Rented)
                  children.add(
                    _buildDocumentItem(
                      localizations,
                      '${localizations.rentalContract} (${localizations.isVehicleRented})',
                      profile.rentalContractUrl,
                      profile.rentalContractUrlPending,
                      (url) => service.updateDocumentUrl(
                        userId,
                        'rental_contract_url_pending',
                        url,
                      ),
                      isVerified: profile.rentalContractUrl != null,
                    ),
                  );
                }
              }

              if (children.isEmpty) {
                children.add(Text(localizations.noDocumentsFound));
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: children,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text(localizations.errorLoadingProfile)),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
    AppLocalizations localizations,
    String label,
    String? activeUrl,
    String? pendingUrl,
    Future<void> Function(String url) onUpdate, {
    bool isVerified = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label header for better clarity if needed, but card has label inside.

        // Active Document Row
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.description,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              if (activeUrl != null)
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () => _viewDocument(activeUrl),
                  tooltip: localizations.view,
                ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () => _replaceDocument(localizations, onUpdate),
                tooltip: localizations.replace,
              ),
            ],
          ),
        ),

        // Pending Document Row
        if (pendingUrl != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$label (${localizations.statusPending})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.underReview,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.orange),
                  onPressed: () => _viewDocument(pendingUrl),
                  tooltip: localizations.view,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _replaceDocument(localizations, onUpdate),
                  tooltip: localizations.replace,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Resolves a stored document reference to a signed URL (for the private
  /// user_documents bucket) before opening it.
  Future<void> _viewDocument(String stored) async {
    final resolved = await ref
        .read(profileServiceProvider)
        .resolveDocumentUrl(stored);
    await _launchUrl(resolved);
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        StructuredLogger.error(
          'DocumentsScreen',
          'Could not launch URL: $url',
          null,
          null,
        );
      }
    } catch (e, st) {
      StructuredLogger.error('DocumentsScreen', 'Failed to launch URL', e, st);
    }
  }

  Future<void> _replaceDocument(
    AppLocalizations localizations,
    Future<void> Function(String url) onUpdate,
  ) async {
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

    setState(() => _isLoading = true);

    try {
      final url = await ref
          .read(profileServiceProvider)
          .uploadFile(file, user.id);

      if (url != null) {
        await onUpdate(url);

        // Invalidate provider to refresh UI
        ref.invalidate(currentUserProfileProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.profileUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw TripShipException('upload_failed');
      }
    } catch (e, st) {
      StructuredLogger.error(
        'DocumentsScreen',
        'Failed to upload document',
        e,
        st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.uploadFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
