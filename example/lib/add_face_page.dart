
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';

class AddFacePage extends StatefulWidget {
  final int lockId;
  const AddFacePage({super.key, required this.lockId});

  @override
  State<AddFacePage> createState() => _AddFacePageState();
}

class _AddFacePageState extends State<AddFacePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _imageFile;
  String? _featureData;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateTime.now().millisecondsSinceEpoch.toString();
    _endDateController.text =
        DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch.toString();
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      setState(() {
        _imageFile = selectedImage;
        _isProcessing = true;
      });
      try {
        final repository = context.read<TTLockRepository>();
        final result = await repository.getFeatureDataByPhoto(
            lockId: widget.lockId, imagePath: selectedImage.path);
        if (!mounted) return;
        setState(() {
          _featureData = result['featureData'];
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face feature data obtained successfully.')));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to get feature data: $e')));
      }
    }
  }

  Future<void> _addFace() async {
    if (_formKey.currentState!.validate() && _featureData != null) {
      setState(() {
        _isProcessing = true;
      });
      try {
        final repository = context.read<TTLockRepository>();
        await repository.addFace(
          lockId: widget.lockId,
          featureData: _featureData!,
          addType: 2, // 2 for remote adding via gateway
          name: _nameController.text,
          startDate: int.parse(_startDateController.text),
          endDate: int.parse(_endDateController.text),
        );
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Face added successfully.')));
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add face: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image and get feature data first.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Face'),
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
                  child: const Text('Pick Image'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Face Name'),
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
                ),
                TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(labelText: 'End Date (ms)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                if (_isProcessing) const CircularProgressIndicator(),
                if (_featureData != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 40),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _addFace,
                  child: const Text('Add Face'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
