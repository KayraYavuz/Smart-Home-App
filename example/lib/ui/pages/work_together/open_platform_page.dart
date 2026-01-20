import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenPlatformPage extends StatelessWidget {
  const OpenPlatformPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.openPlatform,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoSection(
            context,
            title: 'APP SDK',
            icon: Icons.smartphone,
            description: l10n.appSdkDesc,
            platforms: ['Android', 'iOS', 'Flutter'],
            url: 'https://open.ttlock.com/doc/sdk/download',
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            context,
            title: 'Cloud API',
            icon: Icons.cloud_queue,
            description: l10n.cloudApiDesc,
            platforms: ['RESTful', 'Webhooks'],
            url: 'https://open.ttlock.com/doc/api/keyList',
          ),
          const SizedBox(height: 16),
          _buildInfoSection(
            context,
            title: 'Windows/Desktop SDK',
            icon: Icons.desktop_windows,
            description: l10n.desktopSdkDesc,
            platforms: ['DLL', 'C#', 'Java'],
            url: 'https://open.ttlock.com/doc/sdk/desktop',
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(height: 8),
                Text(
                  l10n.developerPortalInfo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _launchURL('https://open.ttlock.com'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text(l10n.visitPortal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required List<String> platforms,
    required String url,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: platforms.map((p) => Chip(
                label: Text(p, style: const TextStyle(fontSize: 10)),
                backgroundColor: Colors.grey[850],
                labelStyle: const TextStyle(color: Colors.blue),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            const Divider(color: Colors.grey, height: 24),
            TextButton.icon(
              onPressed: () => _launchURL(url),
              icon: const Icon(Icons.description, size: 18),
              label: Text(AppLocalizations.of(context)!.viewDocumentation),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
