import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:intl/intl.dart';

class QueryLockPage extends StatefulWidget {
  const QueryLockPage({super.key});

  @override
  State<QueryLockPage> createState() => _QueryLockPageState();
}

class _QueryLockPageState extends State<QueryLockPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _locks = [];
  Map<String, dynamic>? _selectedLock;
  Map<String, dynamic>? _queryResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLocks();
  }

  Future<void> _fetchLocks() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService(context.read<AuthRepository>());
      final locks = await apiService.getKeyList();
      if (mounted) {
        setState(() {
          _locks = locks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _queryLockDetails() async {
    if (_selectedLock == null) return;

    setState(() {
      _isLoading = true;
      _queryResult = null;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService(context.read<AuthRepository>());
      final lockId = _selectedLock!['lockId'].toString();
      
      // Fetch lock time as a representation of querying lock details
      // In a real scenario, we might want to fetch more details if available
      // For now, we use queryLockTime and merge with existing info
      final lockTime = await apiService.queryLockTime(lockId: lockId);
      final battery = await apiService.queryLockBattery(lockId: lockId);
      
      if (mounted) {
        setState(() {
          _queryResult = {
            'lockTime': DateTime.fromMillisecondsSinceEpoch(lockTime),
            'battery': battery,
            'name': _selectedLock!['name'],
            'mac': _selectedLock!['lockMac'],
            'lockId': lockId,
            'lockData': _selectedLock!['lockData'],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Sorgulama hatası: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          l10n.queryLock,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading && _locks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLockSelector(l10n),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _selectedLock == null || _isLoading ? null : _queryLockDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            l10n.queryLock,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_queryResult != null) _buildResultCard(l10n),
                ],
              ),
            ),
    );
  }

  Widget _buildLockSelector(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLock?['lockId']?.toString(),
          hint: Text(
            l10n.selectLock,
            style: TextStyle(color: Colors.grey[400]),
          ),
          dropdownColor: const Color(0xFF1E1E1E),
          style: const TextStyle(color: Colors.white),
          isExpanded: true,
          items: _locks.map((lock) {
            return DropdownMenuItem<String>(
              value: lock['lockId']?.toString(),
              child: Text(
                lock['name'] ?? 'Bilinmeyen Kilit',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLock = _locks.firstWhere((lock) => lock['lockId'].toString() == value);
              _queryResult = null; // Reset previous result
            });
          },
        ),
      ),
    );
  }

  Widget _buildResultCard(AppLocalizations l10n) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _queryResult!['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.grey, height: 24),
            _buildResultRow(Icons.fingerprint, l10n.lockId, _queryResult!['lockId']),
            _buildResultRow(Icons.bluetooth, l10n.macAddress, _queryResult!['mac']),
            _buildResultRow(
              Icons.access_time,
              l10n.lockTime,
              DateFormat('dd/MM/yyyy HH:mm').format(_queryResult!['lockTime']),
            ),
            _buildResultRow(
              Icons.battery_std,
              l10n.batteryLevel,
              '${_queryResult!['battery']}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
