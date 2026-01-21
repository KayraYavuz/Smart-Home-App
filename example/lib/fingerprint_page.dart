import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_bloc.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_event.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_state.dart';
import 'package:yavuz_lock/add_fingerprint_page.dart';

class FingerprintPage extends StatefulWidget {
  final int lockId;
  final String lockData;
  const FingerprintPage(
      {super.key, required this.lockId, required this.lockData});

  @override
  _FingerprintPageState createState() => _FingerprintPageState();
}

class _FingerprintPageState extends State<FingerprintPage> {
  @override
  void initState() {
    super.initState();
    context.read<FingerprintBloc>().add(LoadFingerprints(widget.lockId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fingerprints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Fingerprints'),
                  content: const Text(
                      'Are you sure you want to clear all fingerprints?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<FingerprintBloc>()
                            .add(ClearAllFingerprints(widget.lockId));
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<FingerprintBloc, FingerprintState>(
        listener: (context, state) {
          if (state is FingerprintOperationSuccess) {
            context.read<FingerprintBloc>().add(LoadFingerprints(widget.lockId));
          }
        },
        builder: (context, state) {
          if (state is FingerprintLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FingerprintsLoaded) {
            final fingerprints = state.fingerprints;
            return ListView.builder(
              itemCount: fingerprints.length,
              itemBuilder: (context, index) {
                final fingerprint = fingerprints[index];
                return ListTile(
                  title: Text(fingerprint['fingerprintName'] ?? 'No Name'),
                  subtitle: Text(fingerprint['fingerprintNumber']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<FingerprintBloc>().add(DeleteFingerprint(
                          widget.lockId, fingerprint['fingerprintId']));
                    },
                  ),
                  onLongPress: () {
                    showMenu(
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 400, 100, 100),
                      items: [
                        PopupMenuItem(
                          child: const Text('Rename'),
                          onTap: () {
                            _showRenameDialog(
                                context,
                                widget.lockId,
                                fingerprint['fingerprintId'],
                                fingerprint['fingerprintName']);
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Change Period'),
                          onTap: () {
                            _showChangePeriodDialog(
                                context,
                                widget.lockId,
                                fingerprint['fingerprintId']);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          }
          if (state is FingerprintOperationFailure) {
            return Center(child: Text('Error: ${state.error}'));
          }
          return Center(
              child: Text('Fingerprint management for lock ${widget.lockId}'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFingerprintPage(
                  lockId: widget.lockId, lockData: widget.lockData),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, int lockId, int fingerprintId, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Fingerprint'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FingerprintBloc>().add(RenameFingerprint(
                    lockId: lockId,
                    fingerprintId: fingerprintId,
                    fingerprintName: nameController.text,
                  ));
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showChangePeriodDialog(BuildContext context, int lockId, int fingerprintId) {
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startDateController,
              decoration: const InputDecoration(labelText: 'Start Date (ms)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endDateController,
              decoration: const InputDecoration(labelText: 'End Date (ms)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FingerprintBloc>().add(ChangeFingerprintPeriod(
                    lockId: lockId,
                    fingerprintId: fingerprintId,
                    startDate: int.parse(startDateController.text),
                    endDate: int.parse(endDateController.text),
                  ));
              Navigator.pop(context);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
