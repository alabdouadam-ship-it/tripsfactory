import 'package:tripsfactory/core/config/app_routes.dart';
import 'package:tripsfactory/core/config/auth_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/features/auth/data/auth_service.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:tripsfactory/core/utils/error_utils.dart';
import 'package:tripsfactory/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:tripsfactory/core/services/notification_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  double _passwordStrength = 0.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

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

    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = _calculatePasswordStrength(_passwordController.text);
    });
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    double strength = 0.0;
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    return strength.clamp(0.0, 1.0);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final bool exists = await ref
          .read(authServiceProvider)
          .checkUserExists(email);

      if (exists) {
        throw Exception("User already registered");
      }

      await ref
          .read(authServiceProvider)
          .signUp(
            email: email,
            password: _passwordController.text,
            fullName: name,
          );

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(localizations.accountCreatedTitle),
            content: Text(localizations.accountCreatedMessage),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop();
                  context.go(AppRoutes.login);
                },
                child: Text(localizations.ok),
              ),
            ],
          ),
        );
      }
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
            stops: const [0.0, 0.35, 0.35],
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
                    child: _buildSignupCard(context, localizations),
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

  Widget _buildSignupCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.createAccount,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.joinRevolution,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            TripsFactoryAuthTextField(
              controller: _nameController,
              label: localizations.fullName,
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.nameRequired;
                }
                return null;
              },
            ),

            TripsFactoryAuthTextField(
              controller: _emailController,
              label: localizations.email,
              icon: Icons.email_outlined,
              isEmail: true,
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.passwordRequired;
                }
                if (value.length < 6) {
                  return localizations.passwordTooShort;
                }
                return null;
              },
            ),

            if (_passwordController.text.isNotEmpty)
              _PasswordStrengthIndicator(strength: _passwordStrength),

            const SizedBox(height: 24),

            TripsFactoryAuthButton(
              text: localizations.signUp,
              onPressed: _signUp,
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
            _LoginLink(
              onTap: () => context.go(AppRoutes.login),
              label: localizations.alreadyHaveAccount,
              actionLabel: localizations.signIn,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final double strength;

  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final color = strength < 0.3
        ? Colors.red
        : strength < 0.6
        ? Colors.orange
        : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strength < 0.3
              ? localizations.weak
              : strength < 0.6
              ? localizations.medium
              : localizations.strong,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _LoginLink extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final String actionLabel;

  const _LoginLink({
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
