import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class CreatePasscodePage extends StatefulWidget {
  // In a real app, you would pass lockData here
  // final String lockData;
  // const CreatePasscodePage({Key? key, required this.lockData}) : super(key: key);

  const CreatePasscodePage({Key? key}) : super(key: key);

  @override
  _CreatePasscodePageState createState() => _CreatePasscodePageState();
}

class _CreatePasscodePageState extends State<CreatePasscodePage> {
  final _formKey = GlobalKey<FormState>();
  String _passcode = '';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 30));

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _createPasscode() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Implement actual passcode creation with SDK:
      // TTLock.createCustomPasscode(_passcode, _startDate.millisecondsSinceEpoch, _endDate.millisecondsSinceEpoch, widget.lockData, ...);
      print('Creating passcode: $_passcode from $_startDate to $_endDate');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Text('Yeni Şifre Oluştur'),
        backgroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: _buildInputDecoration('Şifre (4-9 haneli)'),
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white, fontSize: 18),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir şifre girin';
                  }
                  if (value.length < 4 || value.length > 9) {
                    return 'Şifre 4 ile 9 haneli olmalıdır';
                  }
                  return null;
                },
                onSaved: (value) => _passcode = value!,
              ),
              SizedBox(height: 30),
              Text('Geçerlilik Başlangıcı', style: TextStyle(color: Colors.grey[400])),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                onPressed: () => _selectDate(context, true),
                child: Text(DateFormat('dd.MM.yyyy').format(_startDate), style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 30),
              Text('Geçerlilik Bitişi', style: TextStyle(color: Colors.grey[400])),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                onPressed: () => _selectDate(context, false),
                child: Text(DateFormat('dd.MM.yyyy').format(_endDate), style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E90FF),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _createPasscode,
                child: Text('Oluştur', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
