import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/services/email_service.dart';
import 'package:yavuz_lock/ui/theme.dart';

/// In-app, email-verified password reset.
///
///  Step 1: enter account email → the app emails a 6-digit code (its own SMTP).
///  Step 2: enter the code + a new password → the code is checked, then the
///          TTLock cloud `resetPassword` is called.
///
/// This is fully invisible (no TTLock page) for accounts created through this
/// app. If the API cannot reset the account (e.g. a pre-existing real TTLock
/// account) or email can't be sent, it falls back to TTLock's reset portal in
/// an in-app browser.
class ForgotPasswordPage extends StatefulWidget {
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
  final _emailService = EmailService();

  int _step = 1;
  String? _sentCode;
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

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context)!;
    // In step 2 the email form is no longer in the tree; validate the value directly.
    if (_emailFormKey.currentState != null) {
      if (!_emailFormKey.currentState!.validate()) return;
    } else if (!_isValidEmail(_emailController.text)) {
      _snack(l10n.invalidEmail, error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final code = _emailService.generateVerificationCode();
      final sent = await _emailService.sendVerificationEmail(
          _emailController.text.trim(), code);
      if (!mounted) return;
      if (sent) {
        setState(() {
          _sentCode = code;
          _step = 2;
        });
        _snack(l10n.codeSentTo(_emailController.text.trim()));
      } else {
        // SMTP not configured or send failed → can't verify; offer fallback.
        await _offerTtlockFallback(l10n.codeSendFailed);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_resetFormKey.currentState!.validate()) return;
    if (_codeController.text.trim() != _sentCode) {
      _snack(l10n.invalidCode, error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _api.resetPassword(
        username: _emailController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _snack(l10n.resetPasswordSuccess);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) await _offerTtlockFallback(l10n.resetCouldNotAuto);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _offerTtlockFallback(String message) async {
    final l10n = AppLocalizations.of(context)!;
    final go = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.forgotPasswordTitle),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.openTtlockResetBtn)),
        ],
      ),
    );
    if (go != true) return;
    final uri = Uri.parse('https://lock2.ttlock.com/');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
        await launchUrl(uri);
      }
    } catch (_) {
      _snack(l10n.urlOpenError(uri.toString()), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
              if (v.length < 8) return l10n.passwordMinLength;
              if (!RegExp(r'[0-9]').hasMatch(v)) return l10n.passwordDigitRequired;
              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) return l10n.passwordSymbolRequired;
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
          const SizedBox(height: 24),
          _primaryButton(
              label: l10n.resetPasswordBtn, onPressed: _resetPassword),
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

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget seg(bool active) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
    return Row(children: [seg(true), seg(step >= 2)]);
  }
}
