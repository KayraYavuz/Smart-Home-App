import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/ui/theme.dart';

/// In-app password reset, handled entirely through the TTLock cloud API
/// (getResetPasswordCode + resetPassword) — no redirect to the TTLock website.
///
/// Step 1: enter account email → a verification code is emailed.
/// Step 2: enter the code + a new password → the password is reset.
class ForgotPasswordPage extends StatefulWidget {
  /// Optional email to pre-fill (e.g. whatever the user typed on login).
  final String? initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // 1 = request code, 2 = verify + reset
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
    _codeController.dispose();
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

  String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst(
            'apiResetPasswordFailed:',
            '',
          );

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _api.getResetPasswordCode(username: _emailController.text.trim());
      if (!mounted) return;
      setState(() => _step = 2);
      _snack(l10n.codeSentTo(_emailController.text.trim()));
    } catch (e) {
      _snack(l10n.errorWithMsg(_clean(e)), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _api.resetPassword(
        username: _emailController.text.trim(),
        newPassword: _newPasswordController.text,
        verifyCode: _codeController.text.trim(),
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(step: _step),
              const SizedBox(height: 28),
              const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
              const SizedBox(height: 20),
              if (_step == 1) _buildStep1(l10n) else _buildStep2(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(AppLocalizations l10n) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.forgotPasswordSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: l10n.emailOrPhone,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.usernameRequired;
              if (!_isValidEmail(v)) return l10n.invalidEmail;
              return null;
            },
            onFieldSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 24),
          _primaryButton(label: l10n.sendResetCode, onPressed: _sendCode),
        ],
      ),
    );
  }

  Widget _buildStep2(AppLocalizations l10n) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.enterCodeAndNewPassword,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(l10n.codeSentTo(_emailController.text.trim()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: l10n.verificationCode,
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.usernameRequired : null,
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
                icon: Icon(
                    _obscureNew ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
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
          ),
          const SizedBox(height: 24),
          _primaryButton(label: l10n.resetPasswordBtn, onPressed: _resetPassword),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isLoading ? null : _sendCode,
            child: Text(l10n.resendCode),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(
      {required String label, required VoidCallback onPressed}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.black),
              )
            : Text(label),
      ),
    );
  }
}

/// Two-segment progress indicator for the reset flow.
class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget segment(bool active) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
    return Row(children: [segment(true), segment(step >= 2)]);
  }
}
