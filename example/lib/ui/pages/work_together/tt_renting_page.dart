import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class TTRentingPage extends StatefulWidget {
  const TTRentingPage({Key? key}) : super(key: key);

  @override
  _TTRentingPageState createState() => _TTRentingPageState();
}

class _TTRentingPageState extends State<TTRentingPage> {
  // Demo data for rental properties
  final List<Map<String, dynamic>> _properties = [
    {
      'id': '1',
      'name': 'Daire 5 - Kadıköy',
      'tenant': 'Kiracı A',
      'status': 'rented',
      'rentAmount': 15000,
      'dueDate': DateTime.now().add(const Duration(days: 5)),
      'isPaid': false,
    },
    {
      'id': '2',
      'name': 'Daire 12 - Beşiktaş',
      'tenant': null,
      'status': 'vacant',
      'rentAmount': 18000,
      'dueDate': null,
      'isPaid': null,
    },
    {
      'id': '3',
      'name': 'Yazlık - Bodrum',
      'tenant': 'Kiracı B',
      'status': 'rented',
      'rentAmount': 25000,
      'dueDate': DateTime.now().subtract(const Duration(days: 2)),
      'isPaid': true,
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
          l10n.ttRenting,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_home, color: Colors.white),
            onPressed: _showAddPropertyDialog,
          ),
        ],
      ),
      body: _properties.isEmpty
          ? Center(
              child: Text(
                l10n.noPropertiesFound,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _properties.length,
              itemBuilder: (context, index) {
                final property = _properties[index];
                return _buildPropertyCard(property, l10n);
              },
            ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property, AppLocalizations l10n) {
    bool isRented = property['status'] == 'rented';
    Color statusColor = isRented ? Colors.blue : Colors.green;
    String statusText = isRented ? l10n.rented : l10n.vacant;

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    property['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isRented) ...[
              _buildInfoRow(Icons.person, l10n.tenant, property['tenant']),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.calendar_today,
                l10n.rentDueDate,
                _formatDate(property['dueDate']),
                trailing: property['isPaid']
                    ? Text(l10n.paid, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                    : Text(l10n.unpaid, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _sendKey(property['name'], l10n),
                    icon: const Icon(Icons.vpn_key, size: 18),
                    label: Text(l10n.sendKey),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!property['isPaid'])
                    ElevatedButton.icon(
                      onPressed: () => _sendReminder(property['tenant'], l10n),
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: Text(l10n.remind),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ] else ...[
              Text(
                l10n.readyForRent,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _sendKey(String propertyName, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$propertyName: ${l10n.keySent}')),
    );
  }

  void _sendReminder(String tenantName, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$tenantName: ${l10n.reminderSent}')),
    );
  }

  void _showAddPropertyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(l10n.addProperty, style: const TextStyle(color: Colors.white)),
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
