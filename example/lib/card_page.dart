import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:intl/intl.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'add_card_page.dart';

class CardPage extends StatefulWidget {
  final String lockId;
  final String lockData;
  const CardPage({super.key, required this.lockId, required this.lockData});

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
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), 
              child: const Text('İptal')
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), 
              child: const Text('Sil', style: TextStyle(color: Colors.red))
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final apiService = Provider.of<ApiService>(context, listen: false);
      bool bluetoothSuccess = false;

      // 1. Try Bluetooth Deletion First
      try {
        // We attempt to delete via Bluetooth. 
        // If the lock is not connected or reachable, this might fail or timeout.
        // We can use a short timeout or just try.
        // Note: TTLock.deleteCard requires the card number.
        // We'll wrap this in a try-catch to not block the process if BT fails.
        final completer = Completer<void>();
        
        TTLock.deleteCard(cardNumber, widget.lockData, () {
          // Success
          completer.complete();
        }, (errorCode, errorMsg) {
          // Failure
          if (!completer.isCompleted) completer.completeError(Exception("$errorCode: $errorMsg"));
        });
        
        // Wait for result with a timeout (e.g., 5 seconds)
        // If it times out, we assume we are not near the lock and proceed to Gateway deletion.
        await completer.future.timeout(const Duration(seconds: 5));
        bluetoothSuccess = true;
        debugPrint("Card deleted via Bluetooth successfully.");
      } catch (e) {
        debugPrint("Bluetooth deletion failed or timed out: $e. Falling back to Gateway/Cloud deletion.");
        bluetoothSuccess = false;
      }

      // 2. Call API to update server state
      try {
        // If Bluetooth success -> deleteType: 1
        // If Bluetooth fail -> deleteType: 2 (Gateway/WiFi)
        await apiService.deleteIdentityCard(
          lockId: widget.lockId, 
          cardId: cardId,
          deleteType: bluetoothSuccess ? 1 : 2
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kart "$cardNumber" başarıyla silindi (${bluetoothSuccess ? "Bluetooth" : "Gateway"}).'))
        );
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

  Future<void> _recoverCards() async {
    final TextEditingController cardNumberController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 365));

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('Kartı Geri Al', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Daha önce silinen bir kartı geri almak için kilit ile Bluetooth bağlantısı gerekir.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cardNumberController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Kart Numarası',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A90FF))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Başlangıç: ${DateFormat('dd/MM/yyyy').format(startDate)}', style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.calendar_today, color: Colors.grey),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => startDate = picked);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Bitiş: ${DateFormat('dd/MM/yyyy').format(endDate)}', style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.calendar_today, color: Colors.grey),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => endDate = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Geri Al', style: TextStyle(color: Color(0xFF4A90FF))),
              ),
            ],
          );
        });
      },
    );

    if (confirm == true && cardNumberController.text.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = true);

      try {
        final completer = Completer<void>();

        TTLock.recoverCard(
          cardNumberController.text.trim(),
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
          widget.lockData,
          () {
            if (!completer.isCompleted) completer.complete();
          },
          (errorCode, errorMsg) {
            if (!completer.isCompleted) {
              completer.completeError(Exception('$errorCode: $errorMsg'));
            }
          },
        );

        await completer.future.timeout(const Duration(seconds: 15));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Kart başarıyla geri alındı.'), backgroundColor: Colors.green),
        );
        await _fetchCards();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kart geri alınamadı: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToRemoteAddCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCardPage(
          lockId: widget.lockId,
          lockData: widget.lockData,
        ),
      ),
    );
    if (result == true) await _fetchCards();
  }

  void _showAddCardOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Nasıl eklemek istersiniz?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.bluetooth, color: Colors.blueAccent),
                title: const Text('Kilit Üzerinden Ekle (Bluetooth)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _addCardViaBluetooth();
                },
              ),
              ListTile(
                leading: const Icon(Icons.nfc, color: Colors.white),
                title: const Text('Telefon Üzerinden Ekle (NFC)', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Gateway üzerinden kaydedilir', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToRemoteAddCard();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addCardViaBluetooth() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCardPage(
          lockId: widget.lockId,
          lockData: widget.lockData,
          isBluetooth: true,
        ),
      ),
    );
    if (result == true) await _fetchCards();
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey[850],
            onSelected: (value) {
              switch (value) {
                case 'recover':
                  _recoverCards();
                  break;
                case 'remote_add':
                  _navigateToRemoteAddCard();
                  break;
                case 'bluetooth_add':
                  _addCardViaBluetooth();
                  break;
                case 'clear_all':
                  _clearAllCards();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recover',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Geri Alma', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remote_add',
                child: Row(
                  children: [
                    Icon(Icons.nfc, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Uzaktan Kart Oluşturma', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'bluetooth_add',
                child: Row(
                  children: [
                    Icon(Icons.bluetooth, color: Colors.blueAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Kilit Üzerinden Kart Ekle', style: TextStyle(color: Colors.blueAccent)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Tüm Kartları Temizle', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
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
        onPressed: _showAddCardOptions,
        backgroundColor: const Color(0xFF1E90FF),
        child: const Icon(Icons.add),
      ),
    );
  }
}
