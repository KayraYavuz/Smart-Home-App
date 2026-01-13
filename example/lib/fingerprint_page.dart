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
      {Key? key, required this.lockId, required this.lockData})
      : super(key: key);

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
        title: Text('Fingerprints'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Clear All Fingerprints'),
                  content: Text(
                      'Are you sure you want to clear all fingerprints?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<FingerprintBloc>()
                            .add(ClearAllFingerprints(widget.lockId));
                        Navigator.pop(context);
                      },
                      child: Text('Clear'),
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
            return Center(child: CircularProgressIndicator());
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
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      context.read<FingerprintBloc>().add(DeleteFingerprint(
                          widget.lockId, fingerprint['fingerprintId']));
                    },
                  ),
                  onLongPress: () {
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(100, 400, 100, 100),
                      items: [
                        PopupMenuItem(
                          child: Text('Rename'),
                          onTap: () {
                            _showRenameDialog(
                                context,
                                widget.lockId,
                                fingerprint['fingerprintId'],
                                fingerprint['fingerprintName']);
                          },
                        ),
                        PopupMenuItem(
                          child: Text('Change Period'),
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
        child: Icon(Icons.add),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, int lockId, int fingerprintId, String currentName) {
    final _nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Fingerprint'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FingerprintBloc>().add(RenameFingerprint(
                    lockId: lockId,
                    fingerprintId: fingerprintId,
                    fingerprintName: _nameController.text,
                  ));
              Navigator.pop(context);
            },
            child: Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showChangePeriodDialog(BuildContext context, int lockId, int fingerprintId) {
    final _startDateController = TextEditingController();
    final _endDateController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _startDateController,
              decoration: InputDecoration(labelText: 'Start Date (ms)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _endDateController,
              decoration: InputDecoration(labelText: 'End Date (ms)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FingerprintBloc>().add(ChangeFingerprintPeriod(
                    lockId: lockId,
                    fingerprintId: fingerprintId,
                    startDate: int.parse(_startDateController.text),
                    endDate: int.parse(_endDateController.text),
                  ));
              Navigator.pop(context);
            },
            child: Text('Change'),
          ),
        ],
      ),
    );
  }
}
