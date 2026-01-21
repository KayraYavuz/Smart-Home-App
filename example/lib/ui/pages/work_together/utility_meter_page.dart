import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class UtilityMeterPage extends StatefulWidget {
  const UtilityMeterPage({super.key});

  @override
  _UtilityMeterPageState createState() => _UtilityMeterPageState();
}

class _UtilityMeterPageState extends State<UtilityMeterPage> {
  // Demo data for utility meters
  final List<Map<String, dynamic>> _meters = [
    {
      'id': '1',
      'name': 'Daire 5 - Elektrik',
      'type': 'electricity',
      'reading': 1450.5,
      'unit': 'kWh',
      'lastUpdated': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '2',
      'name': 'Daire 5 - Su',
      'type': 'water',
      'reading': 420.3,
      'unit': 'm³',
      'lastUpdated': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.utilityMeter,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddMeterDialog,
          ),
        ],
      ),
      body: _meters.isEmpty
          ? Center(
              child: Text(
                l10n.noMetersFound,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _meters.length,
              itemBuilder: (context, index) {
                final meter = _meters[index];
                return _buildMeterCard(meter, l10n);
              },
            ),
    );
  }

  Widget _buildMeterCard(Map<String, dynamic> meter, AppLocalizations l10n) {
    IconData icon;
    Color color;

    if (meter['type'] == 'electricity') {
      icon = Icons.electrical_services;
      color = Colors.orange;
    } else {
      icon = Icons.water_drop;
      color = Colors.blue;
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meter['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.lastReading}: ${meter['reading']} ${meter['unit']}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showAddMeterDialog() {
    // Demo dialog
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(l10n.addMeter, style: const TextStyle(color: Colors.white)),
          content: Text(
            l10n.featureComingSoon,
            style: const TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok, style: const TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
