import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:intl/intl.dart';
import 'add_card_page.dart';

class CardPage extends StatefulWidget {
  final String lockId;
  const CardPage({super.key, required this.lockId});

  @override
  State<CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cards = [];

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final fetchedCards = await apiService.listIdentityCards(lockId: widget.lockId);
      setState(() {
        _cards = fetchedCards;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kartlar yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCard(int cardId, String cardNumber) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kartı Sil'),
          content: Text('"$cardNumber" numaralı kartı silmek istediğinize emin misiniz?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sil')),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.deleteIdentityCard(lockId: widget.lockId, cardId: cardId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kart "$cardNumber" başarıyla silindi.')));
        await _fetchCards();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kart silinemedi: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showEditCardDialog(Map<String, dynamic> card) async {
    final cardId = card['cardId'] as int;
    final TextEditingController nameController = TextEditingController(text: card['cardName'] ?? '');
    DateTime startDate = DateTime.fromMillisecondsSinceEpoch(card['startDate']);
    DateTime endDate = DateTime.fromMillisecondsSinceEpoch(card['endDate']);

    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Kartı Düzenle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Kart Adı')),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text('Başlangıç: ${DateFormat('dd/MM/yyyy').format(startDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (picked != null) setDialogState(() => startDate = picked);
                    },
                  ),
                  ListTile(
                    title: Text('Bitiş: ${DateFormat('dd/MM/yyyy').format(endDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (picked != null) setDialogState(() => endDate = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Kaydet')),
            ],
          );
        });
      },
    );

    if (save == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        bool needsRefresh = false;

        // Rename if name is different
        if (nameController.text != (card['cardName'] ?? '')) {
          await apiService.renameIdentityCard(lockId: widget.lockId, cardId: cardId, cardName: nameController.text);
          needsRefresh = true;
        }

        // Change period if dates are different
        if (startDate.millisecondsSinceEpoch != card['startDate'] || endDate.millisecondsSinceEpoch != card['endDate']) {
          await apiService.changeIdentityCardPeriod(lockId: widget.lockId, cardId: cardId, startDate: startDate.millisecondsSinceEpoch, endDate: endDate.millisecondsSinceEpoch);
          needsRefresh = true;
        }

        if (needsRefresh) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kart başarıyla güncellendi.')));
          await _fetchCards();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kart güncellenemedi: $e')));
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _clearAllCards() async {
     final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tüm Kartları Temizle'),
          content: const Text('Bu kilitteki tüm kartları sunucudan silmek istediğinizden emin misiniz?\n\nUyarı: Bu işlem geri alınamaz ve API dokümantasyonuna göre önce SDK üzerinden kilit hafızasının temizlenmesi gerekir.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Temizle')),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.clearIdentityCards(lockId: widget.lockId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm kartlar sunucudan başarıyla temizlendi.')));
        await _fetchCards();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kartlar temizlenemedi: $e')));
         setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(int timestamp) => DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('IC Kartlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _isLoading ? null : _clearAllCards,
            tooltip: 'Tüm Kartları Temizle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? const Center(child: Text('Hiç IC Kart bulunamadı.', style: TextStyle(color: Colors.white)))
              : RefreshIndicator(
                  onRefresh: _fetchCards,
                  child: ListView.builder(
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      final int cardId = card['cardId'] as int;
                      final String cardName = card['cardName'] ?? 'İsimsiz Kart';
                      final String cardNumber = card['cardNumber'] ?? 'N/A';
                      final String startDate = card['startDate'] != null ? _formatDate(card['startDate']) : 'N/A';
                      final String endDate = card['endDate'] != null ? _formatDate(card['endDate']) : 'N/A';

                      return Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: const Icon(Icons.credit_card, color: Color(0xFF1E90FF)),
                          title: Text(cardName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No: $cardNumber', style: TextStyle(color: Colors.grey[400])),
                              Text('Geçerlilik: $startDate - $endDate', style: TextStyle(color: Colors.grey[400])),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.amber),
                                onPressed: () => _showEditCardDialog(card),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteCard(cardId, cardNumber),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCardPage(lockId: widget.lockId)),
          );
          if (result == true) await _fetchCards();
        },
        backgroundColor: const Color(0xFF1E90FF),
        child: const Icon(Icons.add),
      ),
    );
  }
}
