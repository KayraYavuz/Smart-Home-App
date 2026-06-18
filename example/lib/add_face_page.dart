import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class AddFacePage extends StatefulWidget {
  final int lockId;
  const AddFacePage({super.key, required this.lockId});

  @override
  State<AddFacePage> createState() => _AddFacePageState();
}

class _AddFacePageState extends State<AddFacePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _imageFile;
  String? _featureData;
  bool _isProcessing = false;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      if (!mounted) return;
      setState(() {
        _imageFile = selectedImage;
        _isProcessing = true;
      });
      try {
        if (!mounted) return;
        final repository = context.read<TTLockRepository>();
        final result = await repository.getFeatureDataByPhoto(
            lockId: widget.lockId, imagePath: selectedImage.path);
        if (!mounted) return;
        setState(() {
          _featureData = result['featureData'];
          _isProcessing = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.faceFeatureObtained)));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
      }
    }
  }

  Future<void> _addFace() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate() && _featureData != null) {
      if (!mounted) return;
      setState(() {
        _isProcessing = true;
      });
      try {
        if (!mounted) return;
        final repository = context.read<TTLockRepository>();
        await repository.addFace(
          lockId: widget.lockId,
          featureData: _featureData!,
          addType: 2, // 2 for remote adding via gateway
          name: _nameController.text,
          startDate: _startDate.millisecondsSinceEpoch,
          endDate: _endDate.millisecondsSinceEpoch,
        );
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.faceAddedSuccess)));
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.selectImageFirst)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addFace),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_imageFile != null)
                  Image.file(File(_imageFile!.path), height: 150, width: 150),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text(l10n.pickImage),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.faceName),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterName;
                    }
                    return null;
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(l10n.startDate),
                  subtitle: Text(_formatDate(_startDate)),
                  onTap: () => _pickDate(isStart: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(l10n.endDate),
                  subtitle: Text(_formatDate(_endDate)),
                  onTap: () => _pickDate(isStart: false),
                ),
                const SizedBox(height: 20),
                if (_isProcessing) const CircularProgressIndicator(),
                if (_featureData != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child:
                        Icon(Icons.check_circle, color: Colors.green, size: 40),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _addFace,
                  child: Text(l10n.addFace),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
