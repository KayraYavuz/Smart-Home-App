import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:intl/intl.dart';


class AddCardPage extends StatefulWidget {
  final String lockId;
  const AddCardPage({Key? key, required this.lockId}) : super(key: key);

  @override
  _AddCardPageState createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365)); // Default to 1 year from now
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // 5 years ago
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)), // 10 years from now
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 1)); // Ensure end date is after start date
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 1)); // Ensure start date is before end date
          }
        }
      });
    }
  }

  Future<void> _addCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);

    try {
      await apiService.addIdentityCard(
        lockId: widget.lockId,
        cardNumber: _cardNumberController.text,
        cardName: _cardNameController.text,
        startDate: _startDate.millisecondsSinceEpoch,
        endDate: _endDate.millisecondsSinceEpoch,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kart başarıyla eklendi!')),
      );
      Navigator.pop(context, true); // Pop with a result to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kart eklenemedi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Yeni Kart Ekle'),
        backgroundColor: Colors.grey[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _cardNumberController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Kart Numarası',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: const TextStyle(color: Colors.white38),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF1E90FF)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen kart numarasını girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cardNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Kart Adı (Opsiyonel)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintStyle: const TextStyle(color: Colors.white38),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF1E90FF)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        'Başlangıç Tarihi: ${DateFormat('dd/MM/yyyy').format(_startDate)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Color(0xFF1E90FF)),
                      onTap: () => _selectDate(context, true),
                    ),
                    ListTile(
                      title: Text(
                        'Bitiş Tarihi: ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Color(0xFF1E90FF)),
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E90FF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _addCard,
                      child: Text(
                        _isLoading ? 'Ekleniyor...' : 'Kart Ekle',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
