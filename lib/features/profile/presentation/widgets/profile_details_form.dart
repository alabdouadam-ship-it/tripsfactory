import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

class ProfileDetailsForm extends StatelessWidget {
  final User? user;
  final AppLocalizations localizations;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController bioController;

  const ProfileDetailsForm({
    super.key,
    required this.user,
    required this.localizations,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.bioController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user?.email != null) ...[
            TextFormField(
              initialValue: user!.email!,
              decoration: InputDecoration(
                labelText: localizations.email,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
              ),
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: localizations.fullName,
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[50],
            ),
            validator: (value) => value == null || value.isEmpty
                ? localizations.pleaseEnterName
                : null,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: localizations.phoneNumber,
              prefixIcon: const Icon(Icons.phone_iphone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[50],
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: bioController,
            decoration: InputDecoration(
              labelText: localizations.bio,
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[50],
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
