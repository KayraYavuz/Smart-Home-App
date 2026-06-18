import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/ui/theme.dart';

/// In-app password reset, handled through the TTLock cloud API — no redirect
/// to the TTLock website.
///
/// The TTLock Open API has no email-verification-code reset endpoint
/// (`getResetPasswordCode` returns 404). It only exposes `/v3/user/resetPassword`,
/// which lets the app reset one of its users' passwords directly with the
/// client credentials — so this is a single-step flow: enter the account email
/// and a new password.
class ForgotPasswordPage extends StatefulWidget {
  /// Optional email to pre-fill (e.g. whatever the user typed on login).
  final String? initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  ApiService get _api => context.read<ApiService>();

  bool _isValidEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _clean(Object e) => e
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('apiResetPasswordFailed:', '');

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _api.resetPassword(
        username: _emailController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _snack(l10n.resetPasswordSuccess);
      Navigator.of(context).pop();
    } catch (e) {
      _snack(l10n.errorWithMsg(_clean(e)), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
                const SizedBox(height: 20),
                Text(l10n.forgotPasswordSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.emailOrPhone,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l10n.usernameRequired;
                    }
                    if (!_isValidEmail(v)) return l10n.invalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  enabled: !_isLoading,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.passwordRequired;
                    if (v.length < 6) return l10n.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.passwordRequired;
                    if (v != _newPasswordController.text) {
                      return l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _resetPassword(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.black),
                          )
                        : Text(l10n.resetPasswordBtn),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
