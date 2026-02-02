import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/ui/pages/work_together/query_lock_page.dart';
import 'package:yavuz_lock/ui/pages/work_together/utility_meter_page.dart';
import 'package:yavuz_lock/ui/pages/work_together/card_encoder_page.dart';
import 'package:yavuz_lock/ui/pages/work_together/hotel_pms_page.dart';
import 'package:yavuz_lock/ui/pages/work_together/third_party_device_page.dart';
import 'package:yavuz_lock/ui/pages/work_together/tt_renting_page.dart';
import 'package:yavuz_lock/ui/pages/work_together/open_platform_page.dart';

class WorkTogetherPage extends StatelessWidget {
  const WorkTogetherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu tema
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.workTogetherTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _buildPartnerService(
              icon: Icons.search,
              iconColor: Colors.blue,
              title: l10n.queryLock,
              description: l10n.queryLockDesc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QueryLockPage()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildPartnerService(
              icon: Icons.contactless,
              iconColor: Colors.green,
              title: l10n.cardEncoder,
              description: l10n.cardEncoderDesc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CardEncoderPage()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildPartnerService(
              icon: Icons.code,
              iconColor: Colors.red,
              title: l10n.openPlatform,
              description: l10n.openPlatformDesc,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OpenPlatformPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerService({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
          size: 20,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}