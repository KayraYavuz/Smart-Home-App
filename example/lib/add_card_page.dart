import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:intl/intl.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class AddCardPage extends StatefulWidget {
  final String lockId;
  final String lockData;
  const AddCardPage({super.key, required this.lockId, required this.lockData});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

enum ValidityType { permanent, timed, recurring }

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNameController = TextEditingController();
  
  ValidityType _validityType = ValidityType.permanent;
  
  // Timed/Permanent Dates
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  // Recurring Config
  List<int> _selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri default
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  // 0: Bluetooth (Scan), 1: Gateway (Manual)
  int _addMode = 0; 
  final TextEditingController _manualCardNumberController = TextEditingController();

  @override
  void dispose() {
    _cardNameController.dispose();
    _manualCardNumberController.dispose();
    super.dispose();
  }

  // ... (dates selection methods remain same) ...

  Future<void> _scanAndAddCard() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _statusMessage = _addMode == 0 ? l10n.connectAndScan : "Adding via Gateway...";
    });

    try {
      int startDateMs;
      int endDateMs;
      
      // Calculate start/end dates based on validity type
      if (_validityType == ValidityType.permanent) {
        startDateMs = DateTime.now().millisecondsSinceEpoch;
        endDateMs = DateTime.now().add(const Duration(days: 365 * 99)).millisecondsSinceEpoch;
      } else if (_validityType == ValidityType.timed) {
        startDateMs = _startDate.millisecondsSinceEpoch;
        endDateMs = _endDate.millisecondsSinceEpoch;
      } else {
        // Recurring
        startDateMs = DateTime.now().millisecondsSinceEpoch;
        endDateMs = DateTime.now().add(const Duration(days: 365 * 10)).millisecondsSinceEpoch;
        
        if (_selectedDays.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one day')));
           setState(() => _isLoading = false);
           return;
        }
      }

      String cardNumber = "";

      if (_addMode == 0) {
        // Bluetooth Mode: Scan using SDK
        final completer = Completer<String>();
        
        // Pass null for cyclicConfig to SDK as structure is uncertain/complex
        TTLock.addCard(null, startDateMs, endDateMs, widget.lockData, () {
           setState(() {
             _statusMessage = "Device connecting...";
           });
        }, (scannedNumber) {
           completer.complete(scannedNumber);
        }, (errorCode, errorMsg) {
           if (!completer.isCompleted) completer.completeError(Exception("$errorCode: $errorMsg"));
        });
        
        cardNumber = await completer.future;
        setState(() {
          _statusMessage = "Card scanned. Saving to server...";
        });
      } else {
        // Gateway Mode: Use manually entered card number
         cardNumber = _manualCardNumberController.text.trim();
         if (cardNumber.isEmpty) {
           throw Exception("Card number is required for Gateway mode");
         }
      }
      
      // Add to Server
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      List<Map<String, dynamic>>? cyclicData;
      if (_validityType == ValidityType.recurring) {
         cyclicData = _selectedDays.map((day) => {
           "weekDay": day,
           "startTime": _startTime.hour * 60 + _startTime.minute,
           "endTime": _endTime.hour * 60 + _endTime.minute
         }).toList();
      }

      await apiService.addIdentityCard(
        lockId: widget.lockId,
        cardNumber: cardNumber,
        startDate: startDateMs,
        endDate: endDateMs,
        cardName: _cardNameController.text.isEmpty ? 'Card $cardNumber' : _cardNameController.text,
        addType: _addMode == 0 ? 1 : 2, // 1: Bluetooth, 2: Gateway
        cyclicConfig: cyclicData, 
        cardType: _validityType == ValidityType.recurring ? 4 : 1
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card added successfully!')),
      );
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(l10n.addDevice), 
        backgroundColor: Colors.grey[900],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_statusMessage ?? l10n.processing, style: const TextStyle(color: Colors.white)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Selection
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('Bluetooth', style: TextStyle(color: Colors.white)),
                            value: 0,
                            groupValue: _addMode,
                            onChanged: (val) => setState(() => _addMode = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text('Gateway/WLAN', style: TextStyle(color: Colors.white)),
                            value: 1,
                            groupValue: _addMode,
                            onChanged: (val) => setState(() => _addMode = val!),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),

                    // Card Name
                    TextFormField(
                      controller: _cardNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: l10n.nameLabel,
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF1E90FF)), borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Manual Card Number (Only for Gateway Mode)
                    if (_addMode == 1) ...[
                      TextFormField(
                        controller: _manualCardNumberController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Card Number',
                          helperText: 'Enter the card number printed on the card',
                          helperStyle: const TextStyle(color: Colors.grey),
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF1E90FF)), borderRadius: BorderRadius.circular(8)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                           if (_addMode == 1 && (value == null || value.isEmpty)) {
                             return 'Card number is required';
                           }
                           return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ... (Validity Type and rest of UI remains same) ...
                    
                    // Validity Type
                    DropdownButtonFormField<ValidityType>(
                      value: _validityType,
                      dropdownColor: Colors.grey[850],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: l10n.validityType, // need to check if exists, otherwise "Validity Type"
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [
                        DropdownMenuItem(value: ValidityType.permanent, child: Text(l10n.tabPermanent ?? 'Permanent')),
                        DropdownMenuItem(value: ValidityType.timed, child: Text(l10n.tabTimed ?? 'Timed')),
                        DropdownMenuItem(value: ValidityType.recurring, child: Text(l10n.tabRecurring ?? 'Recurring')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _validityType = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Specific Config UI
                    if (_validityType == ValidityType.timed) ...[
                      _buildDateTile(l10n.startDate, _startDate, true),
                      _buildDateTile(l10n.endDate, _endDate, false),
                    ],
                    
                    if (_validityType == ValidityType.recurring) ...[
                      _buildRecurringUI(l10n),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E90FF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _scanAndAddCard,
                        icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
                        label: Text(
                          l10n.scanCard ?? 'Scan Card',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(child: Text(l10n.connectAndScan ?? 'Connect to lock and scan card', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, bool isStart) {
    return ListTile(
      title: Text('$label: ${DateFormat('dd/MM/yyyy').format(date)}', style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.calendar_today, color: Color(0xFF1E90FF)),
      onTap: () => _selectDate(context, isStart),
    );
  }

  Widget _buildRecurringUI(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.selectDays ?? 'Select Days', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          children: [
            _buildDayChip(1, l10n.monday ?? 'Mon'),
            _buildDayChip(2, l10n.tuesday ?? 'Tue'),
            _buildDayChip(3, l10n.wednesday ?? 'Wed'),
            _buildDayChip(4, l10n.thursday ?? 'Thu'),
            _buildDayChip(5, l10n.friday ?? 'Fri'),
            _buildDayChip(6, l10n.saturday ?? 'Sat'),
            _buildDayChip(7, l10n.sunday ?? 'Sun'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text(l10n.startTime ?? 'Start', style: const TextStyle(color: Colors.white)),
                subtitle: Text(_startTime.format(context), style: const TextStyle(color: Colors.white70)),
                onTap: () => _selectTime(context, true),
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text(l10n.endTime ?? 'End', style: const TextStyle(color: Colors.white)),
                subtitle: Text(_endTime.format(context), style: const TextStyle(color: Colors.white70)),
                onTap: () => _selectTime(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayChip(int day, String label) {
    final isSelected = _selectedDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedDays.add(day);
          } else {
            _selectedDays.remove(day);
          }
        });
      },
      checkmarkColor: Colors.white,
      selectedColor: const Color(0xFF1E90FF),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      backgroundColor: Colors.grey[300],
    );
  }
}
