import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ttlock_flutter/ttlock.dart';

class LogsPage extends StatefulWidget {
  // In a real app, you would require lockData to be passed.
  // final String lockData;
  // const LogsPage({Key? key, required this.lockData}) : super(key: key);

  const LogsPage({Key? key}) : super(key: key);

  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // TODO: Replace this simulation with a real SDK call once lockData is available.
    // To make a real call, uncomment the following lines and pass real lockData.
    /*
    TTLock.getLockOperateRecord(
      TTOperateRecordType.total,
      widget.lockData,
      (records) {
        setState(() {
          _logs = jsonDecode(records);
          _isLoading = false;
        });
      },
      (error, errorMessage) {
        setState(() {
          _error = 'Failed to load logs: $errorMessage';
          _isLoading = false;
        });
      },
    );
    */

    // --- Simulation Logic ---
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      // Using the same dummy data for simulation
      _logs = [
        {'action': 'Kilidi Açma Başarılı', 'user': 'Ahmet Y.', 'date': '02.01.2026 18:30', 'icon': Icons.lock_open, 'color': Colors.green},
        {'action': 'Kilitleme Başarılı', 'user': 'Ahmet Y.', 'date': '02.01.2026 16:15', 'icon': Icons.lock, 'color': Colors.red},
        {'action': 'Kilidi Açma Başarılı', 'user': 'Misafir', 'date': '02.01.2026 14:05', 'icon': Icons.lock_open, 'color': Colors.green},
        {'action': 'Geçersiz Şifre Girişi', 'user': 'Bilinmiyor', 'date': '02.01.2026 11:20', 'icon': Icons.warning, 'color': Colors.orange},
        {'action': 'Kilitleme Başarılı', 'user': 'Ayşe K.', 'date': '01.01.2026 22:00', 'icon': Icons.lock, 'color': Colors.red},
        {'action': 'Kilidi Açma Başarılı', 'user': 'Ayşe K.', 'date': '01.01.2026 09:12', 'icon': Icons.lock_open, 'color': Colors.green},
      ];
      _isLoading = false;
    });
    // --- End of Simulation Logic ---
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));
    }
    if (_logs.isEmpty) {
      return Center(child: Text('Hiç kayıt bulunamadı.', style: TextStyle(color: Colors.white)));
    }

    return ListView.separated(
      itemCount: _logs.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey[800], height: 1),
      itemBuilder: (context, index) {
        final log = _logs[index];
        return ListTile(
          leading: Icon(log['icon'], color: log['color'] as Color?, size: 28),
          title: Text(
            log['action'],
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${log['user']} - ${log['date']}',
            style: TextStyle(color: Colors.grey[400]),
          ),
          trailing: Icon(Icons.more_vert, color: Colors.grey[600]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Kayıtlar'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }
}
