import 'package:tripsfactory/core/config/app_routes.dart';
import 'package:tripsfactory/core/config/auth_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/core/services/preferences_service.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:tripsfactory/core/utils/error_utils.dart';
import 'package:tripsfactory/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:tripsfactory/core/services/notification_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = ref.read(preferencesServiceProvider);
    try {
      final savedEmail = await prefs.getString('saved_email');
      final rememberMe = await prefs.getBool('remember_me') ?? false;

      if (mounted && savedEmail != null && rememberMe) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = rememberMe;
        });
      }
    } catch (e) {
      // Ignore errors during load
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = ref.read(preferencesServiceProvider);
    if (_rememberMe) {
      final email = _emailController.text.trim().toLowerCase();
      // Only save the email — passwords are never stored in plaintext
      await prefs.saveEmail(email);
      await prefs.setString('saved_email', email);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove(
        'saved_password',
      ); // clean up any legacy stored password
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _signIn() async {
    HapticFeedback.mediumImpact();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _saveCredentials();

      await ref
          .read(authServiceProvider)
          .signIn(
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
          );

      // Trigger token storage after successful login
      ref.read(notificationServiceProvider).updateToken();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(
                e,
                AppLocalizations.of(context)!.unexpectedError,
                context,
              ),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // Trigger token storage after successful login
      ref.read(notificationServiceProvider).updateToken();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(
                e,
                AppLocalizations.of(context)!.unexpectedError,
                context,
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor,
              theme.primaryColor.withValues(alpha: 0.7),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const AuthHeader(),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginCard(context, localizations),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Semantics(
        label:
            '${localizations.welcomeBack}. ${localizations.loginToYourAccount}',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.welcomeBack,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                localizations.loginToYourAccount,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              TripsFactoryAuthTextField(
                controller: _emailController,
                label: localizations.email,
                icon: Icons.email_outlined,
                isEmail: true,
                autofillHints: const [AutofillHints.email],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.emailRequired;
                  }
                  if (!RegExp(
                    r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$',
                  ).hasMatch(value.trim())) {
                    return localizations.invalidEmail;
                  }
                  return null;
                },
              ),

              TripsFactoryAuthTextField(
                controller: _passwordController,
                label: localizations.password,
                icon: Icons.lock_outline,
                isPassword: true,
                obscurePassword: _obscurePassword,
                onToggleVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                autofillHints: const [AutofillHints.password],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.passwordRequired;
                  }
                  return null;
                },
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RememberMeCheckbox(
                    value: _rememberMe,
                    label: localizations.rememberMe,
                    onChanged: (val) => setState(() => _rememberMe = val),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: Text(
                      localizations.forgotPassword,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              TripsFactoryAuthButton(
                text: localizations.signIn,
                onPressed: _signIn,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),
              if (AuthConfig.showSocialSignIn) ...[
                const AuthDivider(),
                const SizedBox(height: 16),
                AuthSocialButtons(
                  onGoogleTap: _signInWithGoogle,
                  onAppleTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.comingSoon)),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 24),
              _SignUpLink(
                onTap: () => context.push(AppRoutes.signup),
                label: localizations.dontHaveAccount,
                actionLabel: localizations.signUp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RememberMeCheckbox extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const _RememberMeCheckbox({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) => onChanged(val ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _SignUpLink extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final String actionLabel;

  const _SignUpLink({
    required this.onTap,
    required this.label,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(width: 4),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
