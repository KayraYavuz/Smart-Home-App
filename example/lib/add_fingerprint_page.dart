import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_bloc.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_event.dart';

class AddFingerprintPage extends StatefulWidget {
  final int lockId;
  final String lockData;
  const AddFingerprintPage({super.key, required this.lockId, required this.lockData});

  @override
  State<AddFingerprintPage> createState() => _AddFingerprintPageState();
}

class _AddFingerprintPageState extends State<AddFingerprintPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String? _fingerprintNumber;

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateTime.now().millisecondsSinceEpoch.toString();
    _endDateController.text = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fingerprint'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Fingerprint Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _startDateController,
                decoration: const InputDecoration(labelText: 'Start Date (ms)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a start date';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(labelText: 'End Date (ms)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an end date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  TTLock.addFingerprint(null, int.parse(_startDateController.text), int.parse(_endDateController.text), widget.lockData,
                      (currentCount, totalCount) {
                    // _showLoading("currentCount:$currentCount  totalCount:$totalCount");
                  }, (fingerprintNumber) {
                    setState(() {
                      _fingerprintNumber = fingerprintNumber;
                    });
                  }, (errorCode, errorMsg) {
                    // _showErrorAndDismiss(errorCode, errorMsg);
                  });
                },
                child: const Text('Get Fingerprint Number'),
              ),
              const SizedBox(height: 20),
              if (_fingerprintNumber != null) Text('Fingerprint Number: $_fingerprintNumber'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _fingerprintNumber != null) {
                    context.read<FingerprintBloc>().add(
                          AddFingerprint(
                            lockId: widget.lockId,
                            fingerprintNumber: _fingerprintNumber!,
                            fingerprintName: _nameController.text,
                            startDate: int.parse(_startDateController.text),
                            endDate: int.parse(_endDateController.text),
                          ),
                        );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Fingerprint'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
