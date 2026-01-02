import 'package:flutter/material.dart';
import 'add_card_page.dart'; // To be created

class CardPage extends StatefulWidget {
  const CardPage({Key? key}) : super(key: key);

  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    setState(() => _isLoading = true);
    // TODO: Replace with real SDK call: TTLock.getAllValidCards(widget.lockData, ...)
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _cards.addAll([
        {'cardNumber': '10-23-45-67', 'type': 'Sürekli', 'validity': 'Süresiz'},
        {'cardNumber': '89-AB-CD-EF', 'type': 'Zamanlı', 'validity': '01.03.2026 - 01.04.2026'},
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
        title: Text('IC Kartlar'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? Center(child: Text('Hiç IC Kart bulunamadı.', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return ListTile(
                      leading: Icon(Icons.credit_card, color: Color(0xFF1E90FF)),
                      title: Text(card['cardNumber']!, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Text('${card['type']} | ${card['validity']}', style: TextStyle(color: Colors.grey[400])),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                          // TODO: Implement delete card functionality
                          print('Deleting ${card['cardNumber']}');
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCardPage()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF1E90FF),
      ),
    );
  }
}
