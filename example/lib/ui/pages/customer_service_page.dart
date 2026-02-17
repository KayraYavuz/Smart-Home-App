import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.customerService,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E90FF).withAlpha(204),
                const Color(0xFF4169E1).withAlpha(204),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E90FF).withValues(alpha: 0.1),
                    const Color(0xFF4169E1).withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF1E90FF).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 48,
                    color: Color(0xFF1E90FF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.support247,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.contactUsOnIssues,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact items
            _buildAnimatedContactItem(
              context,
              AppLocalizations.of(context)!.emailSupport,
              'service@ttlock.com',
              Icons.email,
              Icons.copy,
              onTap: () => _copyToClipboard(context, 'service@ttlock.com'),
              delay: 0,
            ),
            _buildAnimatedContactItem(
              context,
              AppLocalizations.of(context)!.salesCooperation,
              'sales@ttlock.com',
              Icons.business,
              Icons.copy,
              onTap: () => _copyToClipboard(context, 'sales@ttlock.com'),
              delay: 100,
            ),
            _buildAnimatedContactItem(
              context,
              AppLocalizations.of(context)!.officialWebsite,
              'www.ttlock.com',
              Icons.web,
              Icons.open_in_new,
              onTap: () => _launchURL(context, 'https://www.ttlock.com'),
              delay: 200,
            ),
            _buildAnimatedContactItem(
              context,
              AppLocalizations.of(context)!.webAdminSystem,
              'lock.ttlock.com',
              Icons.admin_panel_settings,
              Icons.open_in_new,
              onTap: () => _launchURL(context, 'https://lock.ttlock.com'),
              delay: 300,
            ),
            _buildAnimatedContactItem(
              context,
              AppLocalizations.of(context)!.hotelAdminSystem,
              'hotel.ttlock.com',
              Icons.hotel,
              Icons.open_in_new,
              onTap: () => _launchURL(context, 'https://hotel.ttlock.com'),
              delay: 400,
            ),
            _buildAnimatedContactItem(
              context,
              AppLocalizations.of(context)!.apartmentSystem,
              'ttrenting.ttlock.com',
              Icons.apartment,
              Icons.open_in_new,
              onTap: () => _launchURL(context, 'https://ttrenting.ttlock.com'),
              delay: 500,
            ),
            _buildAnimatedContactItem(
              context,
              AppLocalizations.of(context)!.userManual,
              'ttlockdoc.ttlock.com',
              Icons.menu_book,
              Icons.open_in_new,
              onTap: () => _launchURL(context, 'https://ttlockdoc.ttlock.com/en/'),
              delay: 600,
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showChatDialog(context),
          backgroundColor: const Color(0xFF1E90FF),
          elevation: 8,
          icon: const Icon(Icons.chat_bubble, color: Colors.white),
          label: Text(
            AppLocalizations.of(context)!.liveSupport,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }


  Future<void> _copyToClipboard(BuildContext context, String text) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(l10n.copiedToClipboardMsg(text))),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(l10n.urlOpenError(url)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMsg(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAnimatedContactItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData leadingIcon,
    IconData? trailingIcon, {
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: const Color(0xFF1E90FF).withValues(alpha: 0.1),
            highlightColor: const Color(0xFF1E90FF).withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E90FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      leadingIcon,
                      color: const Color(0xFF1E90FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailingIcon != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        trailingIcon,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.info, color: Color(0xFF1E90FF)),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.customerService,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.customerServiceDescription,
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: Color(0xFF1E90FF))),
          ),
        ],
      ),
    );
  }

  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.chat, color: Color(0xFF1E90FF)),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.liveSupport,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.liveChatSoon,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _copyToClipboard(context, 'service@ttlock.com');
              },
              icon: const Icon(Icons.email),
              label: Text(AppLocalizations.of(context)!.sendEmail),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E90FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok, style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }
}

