import 'package:flutter/material.dart';
import 'create_passcode_page.dart'; // To be created

class PasscodePage extends StatefulWidget {
  // In a real app, you would pass lockData here
  // final String lockData;
  // const PasscodePage({Key? key, required this.lockData}) : super(key: key);

  const PasscodePage({Key? key}) : super(key: key);

  @override
  _PasscodePageState createState() => _PasscodePageState();
}

class _PasscodePageState extends State<PasscodePage> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _passcodes = [];

  @override
  void initState() {
    super.initState();
    _fetchPasscodes();
  }

  Future<void> _fetchPasscodes() async {
    setState(() => _isLoading = true);

    // TODO: Replace with real SDK call: TTLock.getAllValidPasscode(widget.lockData, ...)
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _passcodes.addAll([
        {'passcode': '198745', 'type': 'Sürekli', 'validity': '01.01.2025 - 01.01.2027'},
        {'passcode': '556677', 'type': 'Zamanlı', 'validity': 'Her Salı, 09:00 - 17:00'},
        {'passcode': '123123', 'type': 'Tek Seferlik', 'validity': 'Kullanılmadı'},
        {'passcode': '987654', 'type': 'Sürekli', 'validity': 'Süresiz'},
      ]);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Şifreler'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _passcodes.isEmpty
              ? Center(child: Text('Hiç şifre bulunamadı.', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: _passcodes.length,
                  itemBuilder: (context, index) {
                    final passcode = _passcodes[index];
                    return ListTile(
                      leading: Icon(Icons.password, color: Color(0xFF1E90FF)),
                      title: Text(passcode['passcode']!, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Text('${passcode['type']} | ${passcode['validity']}', style: TextStyle(color: Colors.grey[400])),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                          // TODO: Implement delete passcode functionality
                          print('Deleting ${passcode['passcode']}');
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePasscodePage()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF1E90FF),
      ),
    );
  }
}
