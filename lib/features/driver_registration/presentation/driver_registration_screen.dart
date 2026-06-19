import 'package:tripship/core/config/app_routes.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/profile/data/profile_service.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/core/config/registration_requirements.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/features/profile/presentation/widgets/registration_widgets.dart';

class TravelerRegistrationScreen extends ConsumerStatefulWidget {
  final bool isUpgrade;

  const TravelerRegistrationScreen({super.key, this.isUpgrade = false});

  @override
  ConsumerState<TravelerRegistrationScreen> createState() =>
      _TravelerRegistrationScreenState();
}

class _TravelerRegistrationScreenState
    extends ConsumerState<TravelerRegistrationScreen> {
  static const String _logTag = 'TravelerRegistrationScreen';
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();

  TravelerType? _selectedTravelerType;
  IdentityType? _selectedIdentityType;
  VehicleType? _selectedVehicleType;
  bool _isVehicleRented = false;

  // Mocked File Paths/URLs
  String? _identityUrl;
  String? _licenseUrl;
  String? _vehiclePhotoUrl;
  String? _registrationDocUrl;
  String? _rentalContractUrl;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isUpgrade) {
      _selectedTravelerType = TravelerType.withVehicle;
    }
  }

  Future<void> _pickFile(String type, Function(String) onPicked) async {
    final picker = ImagePicker();
    final localizations = AppLocalizations.of(context)!;

    // Show Bottom Sheet to choose Camera or Gallery
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

    if (source == null) {
      return;
    }

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      StructuredLogger.warning(_logTag, 'PickFile: No user logged in');
      return;
    }

    // Show loading indicator or toast
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${localizations.uploading}...')));
    }

    try {
      final url = await ref
          .read(profileServiceProvider)
          .uploadFile(
            file,
            user.id, // Use userId as the folder path
          );

      if (url != null) {
        onPicked(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.fileSelected),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw TripShipException.withKey('upload_failed', 'Upload failed');
      }
    } catch (e) {
      StructuredLogger.error(_logTag, 'File upload failed: $type', e);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final localizations = AppLocalizations.of(context)!;

    // Document requirements are defined declaratively in RegistrationRequirements
    // (the fork seam). This preserves the exact previous validation behavior.
    final missing = RegistrationRequirements.missingTravelerDoc(
      isUpgrade: widget.isUpgrade,
      withVehicle: _selectedTravelerType == TravelerType.withVehicle,
      isVehicleRented: _isVehicleRented,
      hasIdentity: _identityUrl != null,
      hasLicense: _licenseUrl != null,
      hasVehiclePhoto: _vehiclePhotoUrl != null,
      hasVehicleRegistration: _registrationDocUrl != null,
      hasRentalContract: _rentalContractUrl != null,
    );
    if (missing != null) {
      _showError(_missingDocMessage(missing, localizations));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      Map<String, dynamic>? vehicleData;
      if (_selectedTravelerType == TravelerType.withVehicle) {
        vehicleData = {
          'vehicle_type': _selectedVehicleType?.name,
          'make': _makeController.text,
          'model': _modelController.text,
          'year': int.tryParse(_yearController.text) ?? 2024,
          'plate_number': _plateController.text,
          'vehicle_photo_url': _vehiclePhotoUrl,
          'registration_doc_url': _registrationDocUrl,
        };
      }

      await ref
          .read(profileServiceProvider)
          .submitTravelerApplication(
            userId: user.id,
            travelerType: _selectedTravelerType!,
            identityType: widget.isUpgrade ? null : _selectedIdentityType,
            identityDocUrl: widget.isUpgrade ? null : _identityUrl,
            licenseUrl: _licenseUrl,
            rentalContractUrl: _rentalContractUrl,
            vehicleData: vehicleData,
            phoneNumber: widget.isUpgrade ? null : _phoneController.text.trim(),
          );

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.applicationSubmitted)),
        );
        context.go(AppRoutes.home);
      }
    } catch (e) {
      StructuredLogger.error(
        _logTag,
        'Traveler application submission failed',
        e,
      );
      if (mounted) {
        _showError(
          getUserFriendlyMessage(e, localizations.unexpectedError, context),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Maps a [MissingDocPrompt] to its localized message (copy stays in ARB).
  String _missingDocMessage(MissingDocPrompt prompt, AppLocalizations l10n) {
    switch (prompt) {
      case MissingDocPrompt.identity:
        return l10n.pleaseUploadIdentityProof;
      case MissingDocPrompt.vehicleDocuments:
        return l10n.pleaseUploadVehicleDocuments;
      case MissingDocPrompt.rentalContract:
        return l10n.pleaseUploadRentalContract;
      case MissingDocPrompt.companyCr:
        return l10n.pleaseUploadCRDocument;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.travelerRegistration)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isUpgrade) ...[
                Text(
                  localizations.travelerType,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<TravelerType>(
                  initialValue: _selectedTravelerType,
                  decoration: InputDecoration(
                    labelText: localizations.travelerType,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: TravelerType.withVehicle,
                      child: Text(localizations.travelerWithVehicle),
                    ),
                    DropdownMenuItem(
                      value: TravelerType.noVehicle,
                      child: Text(localizations.normalTraveler),
                    ),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedTravelerType = val;
                  }),
                  validator: (v) =>
                      v == null ? localizations.fieldRequired : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: localizations.phoneNumber,
                    prefixIcon: const Icon(Icons.phone),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      v!.isEmpty ? localizations.fieldRequired : null,
                ),
                const SizedBox(height: 24),

                Text(
                  localizations.identityProof,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<IdentityType>(
                  initialValue: _selectedIdentityType,
                  decoration: InputDecoration(
                    labelText: localizations.identityProof,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: IdentityType.idCard,
                      child: Text(localizations.nationalIdUrl),
                    ),
                    DropdownMenuItem(
                      value: IdentityType.passport,
                      child: Text(localizations.passport),
                    ),
                    DropdownMenuItem(
                      value: IdentityType.iqama,
                      child: Text(localizations.iqama),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedIdentityType = val),
                ),
                const SizedBox(height: 16),
                RegistrationUploadButton(
                  label: localizations.uploadIdentityProof,
                  url: _identityUrl,
                  onTap: () => _pickFile(
                    localizations.identityProof,
                    (url) => setState(() => _identityUrl = url),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Conditional Vehicle Section
              if (_selectedTravelerType == TravelerType.withVehicle) ...[
                Text(
                  localizations.vehicleInfo,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<VehicleType>(
                  initialValue: _selectedVehicleType,
                  decoration: InputDecoration(
                    labelText: localizations.selectVehicleType,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: VehicleType.tractorTrailer,
                      child: Text(localizations.tractorTrailer),
                    ),
                    DropdownMenuItem(
                      value: VehicleType.largeCar,
                      child: Text(localizations.largeCar),
                    ),
                    DropdownMenuItem(
                      value: VehicleType.mediumCar,
                      child: Text(localizations.mediumCar),
                    ),
                    DropdownMenuItem(
                      value: VehicleType.smallCar,
                      child: Text(localizations.smallCar),
                    ),
                    DropdownMenuItem(
                      value: VehicleType.refrigerated,
                      child: Text(localizations.refrigerated),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedVehicleType = val),
                  validator: (v) =>
                      v == null ? localizations.fieldRequired : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _makeController,
                  decoration: InputDecoration(
                    labelText: localizations.make,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? localizations.fieldRequired
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _modelController,
                  decoration: InputDecoration(
                    labelText: localizations.model,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? localizations.fieldRequired
                      : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: InputDecoration(
                          labelText: localizations.year,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => (v == null || v.isEmpty)
                            ? localizations.fieldRequired
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _plateController,
                        decoration: InputDecoration(
                          labelText: localizations.plateNumber,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? localizations.fieldRequired
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SwitchListTile(
                  title: Text(localizations.isVehicleRented),
                  value: _isVehicleRented,
                  onChanged: (val) => setState(() => _isVehicleRented = val),
                ),

                const SizedBox(height: 16),
                /* Documents Grid for Vehicle */
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    RegistrationUploadButton(
                      label: localizations.uploadLicense,
                      url: _licenseUrl,
                      onTap: () => _pickFile(
                        localizations.uploadLicense,
                        (url) => setState(() => _licenseUrl = url),
                      ),
                    ),
                    RegistrationUploadButton(
                      label: localizations.uploadVehiclePhoto,
                      url: _vehiclePhotoUrl,
                      onTap: () => _pickFile(
                        localizations.uploadVehiclePhoto,
                        (url) => setState(() => _vehiclePhotoUrl = url),
                      ),
                    ),
                    RegistrationUploadButton(
                      label: localizations.uploadRegistration,
                      url: _registrationDocUrl,
                      onTap: () => _pickFile(
                        localizations.uploadRegistration,
                        (url) => setState(() => _registrationDocUrl = url),
                      ),
                    ),
                    if (_isVehicleRented)
                      RegistrationUploadButton(
                        label: localizations.uploadRentalContract,
                        url: _rentalContractUrl,
                        onTap: () => _pickFile(
                          localizations.uploadRentalContract,
                          (url) => setState(() => _rentalContractUrl = url),
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        localizations.submitApplication,
                        style: const TextStyle(fontSize: 18),
                      ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
