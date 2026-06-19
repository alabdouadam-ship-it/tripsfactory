import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/profile/data/profile_service.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/config/registration_requirements.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/features/profile/presentation/widgets/registration_widgets.dart';

class CompanyRegistrationScreen extends ConsumerStatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  ConsumerState<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState
    extends ConsumerState<CompanyRegistrationScreen> {
  static const String _logTag = 'CompanyRegistrationScreen';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _crNumberController = TextEditingController();

  // Mocked File URL
  String? _crUrl;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _crNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(Function(String) onPicked) async {
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

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${localizations.uploading}...')));
    }

    try {
      final url = await ref
          .read(profileServiceProvider)
          .uploadFile(file, user.id);

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
      StructuredLogger.error(_logTag, 'File upload failed', e);
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

    if (RegistrationRequirements.missingCompanyDoc(hasCr: _crUrl != null) !=
        null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseUploadCRDocument),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      await ref
          .read(profileServiceProvider)
          .submitCompanyApplication(
            userId: user.id,
            companyName: _nameController.text,
            companyAddress: _addressController.text,
            crNumber: _crNumberController.text,
            crUrl: _crUrl!,
            phoneNumber: _phoneController.text.trim(),
          );

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.applicationSubmitted)),
        );
        context.pop(); // Go back to profile
      }
    } catch (e) {
      StructuredLogger.error(
        _logTag,
        'Company application submission failed',
        e,
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(e, l10n.unexpectedError, context),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.companyRegistration)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.companyInfo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: localizations.companyName,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? localizations.fieldRequired : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: localizations.companyAddress,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? localizations.fieldRequired : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _crNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: localizations.crNumber,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return localizations.fieldRequired;
                  // Defense in depth: paste/autofill can bypass the formatter.
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return localizations.crNumberDigitsOnly;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: localizations.phoneNumber,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v!.isEmpty ? localizations.fieldRequired : null,
              ),

              const SizedBox(height: 24),
              Text(
                localizations.documents,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              RegistrationUploadButton(
                label: localizations.uploadCR,
                url: _crUrl,
                onTap: () => _pickFile((url) => setState(() => _crUrl = url)),
              ),

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
