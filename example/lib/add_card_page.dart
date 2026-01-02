import 'package:flutter/material.dart';

class AddCardPage extends StatefulWidget {
  // In a real app, you would pass lockData here
  // final String lockData;
  // const AddCardPage({Key? key, required this.lockData}) : super(key: key);
  const AddCardPage({Key? key}) : super(key: key);

  @override
  _AddCardPageState createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  bool _isScanning = false;
  String _statusText = 'Yeni bir IC kart eklemek için "Tara" butonuna basın.';

  Future<void> _startCardScan() async {
    setState(() {
      _isScanning = true;
      _statusText = 'Kilit aranıyor... Lütfen bekleyin.';
    });

    // TODO: Replace with real SDK call and progress callbacks
    // TTLock.addCard(..., (progress){ ... }, (cardNumber){ ... }, (error, message){ ... });

    // Simulate connecting to the lock
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _statusText = 'Kilit bulundu. Lütfen kartı kilidin okuyucusuna yaklaştırın.';
    });

    // Simulate waiting for the card
    await Future.delayed(const Duration(seconds: 5));

    // Simulate success
    setState(() {
      _isScanning = false;
      _statusText = 'Kart başarıyla eklendi!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Yeni kart başarıyla eklendi!')),
    );
    
    // Pop back to the card list page after a short delay
    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text('Yeni Kart Ekle'),
        backgroundColor: Colors.grey[900],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.contactless,
                color: Color(0xFF1E90FF),
                size: 120,
              ),
              SizedBox(height: 40),
              if (_isScanning)
                Center(child: CircularProgressIndicator()),
              SizedBox(height: 20),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 40),
              if (!_isScanning)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E90FF),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _startCardScan,
                  child: Text('Tara', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
