import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class CardEncoderPage extends StatefulWidget {
  const CardEncoderPage({super.key});

  @override
  _CardEncoderPageState createState() => _CardEncoderPageState();
}

class _CardEncoderPageState extends State<CardEncoderPage> {
  bool _isScanning = false;
  bool _isConnected = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.cardEncoder,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cihaz Durumu İkonu
            Icon(
              _isConnected ? Icons.usb : Icons.usb_off,
              size: 80,
              color: _isConnected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            
            // Durum Mesajı
            Text(
              _statusMessage ?? (_isConnected ? l10n.encoderConnected : l10n.encoderNotConnected),
              style: TextStyle(
                color: _isConnected ? Colors.green : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Bağlan Butonu
            if (!_isConnected)
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _connectEncoder,
                icon: _isScanning 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bluetooth_searching),
                label: Text(_isScanning ? l10n.scanning : l10n.connectEncoder),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

            // İşlem Butonları (Bağlıysa görünür)
            if (_isConnected) ...[
              _buildActionButton(
                icon: Icons.add_card,
                label: l10n.issueCard,
                color: Colors.blue,
                onTap: () => _performAction(l10n.issueCard),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.contactless,
                label: l10n.readCard,
                color: Colors.orange,
                onTap: () => _performAction(l10n.readCard),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                icon: Icons.cleaning_services,
                label: l10n.clearCard,
                color: Colors.red,
                onTap: () => _performAction(l10n.clearCard),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: _disconnectEncoder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.disconnect),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _connectEncoder() async {
    setState(() {
      _isScanning = true;
      _statusMessage = AppLocalizations.of(context)!.scanning;
    });

    // Simüle edilmiş bağlantı gecikmesi
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _isConnected = true;
        _statusMessage = null;
      });
    }
  }

  void _disconnectEncoder() {
    setState(() {
      _isConnected = false;
      _statusMessage = null;
    });
  }

  void _performAction(String actionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionName...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
