import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerServicePage extends StatefulWidget {
  @override
  _CustomerServicePageState createState() => _CustomerServicePageState();
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
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'Müşteri Servisi',
          style: TextStyle(
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
                Color(0xFF1E90FF).withValues(alpha: 0.8),
                Color(0xFF4169E1).withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
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
          padding: EdgeInsets.all(16),
          children: [
            // Header section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E90FF).withValues(alpha: 0.1),
                    Color(0xFF4169E1).withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: Color(0xFF1E90FF).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 48,
                    color: Color(0xFF1E90FF),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '7/24 Destek',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Herhangi bir sorun yaşadığınızda bize ulaşın',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Contact items
            _buildAnimatedContactItem(
              context,
              'E-posta Desteği',
              'service@ttlock.com',
              Icons.email,
              Icons.copy,
              onTap: () => _copyToClipboard(context, 'service@ttlock.com'),
              delay: 0,
            ),
            _buildAnimatedContactItem(
              context,
              'Satış ve İş Birliği',
              'sales@ttlock.com',
              Icons.business,
              Icons.copy,
              onTap: () => _copyToClipboard(context, 'sales@ttlock.com'),
              delay: 100,
            ),
            _buildAnimatedContactItem(
              context,
              'Resmi Web Sitesi',
              'www.ttlock.com',
              Icons.web,
              Icons.open_in_new,
              onTap: () => _launchURL(context, 'https://www.ttlock.com'),
              delay: 200,
            ),
            _buildAnimatedContactItem(
              context,
              'Web Yönetim Sistemi',
              'lock.ttlock.com',
              Icons.admin_panel_settings,
              Icons.open_in_new,
              onTap: () => _launchURL(context, 'https://lock.ttlock.com'),
              delay: 300,
            ),
            _buildAnimatedContactItem(
              context,
              'Otel Yönetim Sistemi',
              'hotel.ttlock.com',
              Icons.hotel,
              Icons.open_in_new,
              onTap: () => _launchURL(context, 'https://hotel.ttlock.com'),
              delay: 400,
            ),
            _buildAnimatedContactItem(
              context,
              'Apartman Sistemi',
              'ttrenting.ttlock.com',
              Icons.apartment,
              Icons.open_in_new,
              onTap: () => _launchURL(context, 'https://ttrenting.ttlock.com'),
              delay: 500,
            ),
            _buildAnimatedContactItem(
              context,
              'Kullanım Kılavuzu',
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
          backgroundColor: Color(0xFF1E90FF),
          elevation: 8,
          icon: Icon(Icons.chat_bubble, color: Colors.white),
          label: Text(
            'Canlı Destek',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }


  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Panoya kopyalandı: $text')),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL açılamadı: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        margin: EdgeInsets.only(bottom: 12),
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
            splashColor: Color(0xFF1E90FF).withValues(alpha: 0.1),
            highlightColor: Color(0xFF1E90FF).withValues(alpha: 0.05),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E90FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      leadingIcon,
                      color: Color(0xFF1E90FF),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
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
                      padding: EdgeInsets.all(8),
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
            Icon(Icons.info, color: Color(0xFF1E90FF)),
            SizedBox(width: 12),
            Text(
              'Müşteri Servisi',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Herhangi bir teknik sorun, özellik talebi veya genel soru için bizimle iletişime geçebilirsiniz. '
          'En hızlı şekilde size yardımcı olmaya çalışacağız.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tamam', style: TextStyle(color: Color(0xFF1E90FF))),
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
            Icon(Icons.chat, color: Color(0xFF1E90FF)),
            SizedBox(width: 12),
            Text(
              'Canlı Destek',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Canlı destek sohbeti yakında aktif olacak. '
              'Şimdilik e-posta yoluyla bize ulaşabilirsiniz.',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _copyToClipboard(context, 'service@ttlock.com');
              },
              icon: Icon(Icons.email),
              label: Text('E-posta Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E90FF),
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
            child: Text('Kapat', style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }
}

