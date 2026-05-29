import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/add_fingerprint_page.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_bloc.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_event.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_state.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class FingerprintPage extends StatefulWidget {
  final int lockId;
  final String lockData;
  const FingerprintPage(
      {super.key, required this.lockId, required this.lockData});

  @override
  State<FingerprintPage> createState() => _FingerprintPageState();
}

class _FingerprintPageState extends State<FingerprintPage> {
  @override
  void initState() {
    super.initState();
    context.read<FingerprintBloc>().add(LoadFingerprints(widget.lockId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fingerprintsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.clearAllFingerprintsTitle),
                  content: Text(l10n.clearAllFingerprintsConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<FingerprintBloc>()
                            .add(ClearAllFingerprints(widget.lockId));
                        Navigator.pop(context);
                      },
                      child: Text(l10n.clear),
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
            context
                .read<FingerprintBloc>()
                .add(LoadFingerprints(widget.lockId));
          }
          if (state is FingerprintOperationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.operationFailedWithMsg(state.error)),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FingerprintLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FingerprintsLoaded) {
            final fingerprints = state.fingerprints;
            if (fingerprints.isEmpty) {
              return Center(child: Text(l10n.noFingerprintsFound));
            }
            return ListView.builder(
              itemCount: fingerprints.length,
              itemBuilder: (context, index) {
                final fp = fingerprints[index];
                return ListTile(
                  title: Text(fp['fingerprintName'] ?? l10n.noName),
                  subtitle: Text(fp['fingerprintNumber']?.toString() ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<FingerprintBloc>().add(DeleteFingerprint(
                          widget.lockId, fp['fingerprintId']));
                    },
                  ),
                  onLongPress: () {
                    showMenu(
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 400, 100, 100),
                      items: [
                        PopupMenuItem(
                          child: Text(l10n.rename),
                          onTap: () {
                            _showRenameDialog(context, widget.lockId,
                                fp['fingerprintId'], fp['fingerprintName']);
                          },
                        ),
                        PopupMenuItem(
                          child: Text(l10n.changePeriod),
                          onTap: () {
                            _showChangePeriodDialog(
                                context, widget.lockId, fp['fingerprintId']);
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
            return Center(child: Text(l10n.errorWithMsg(state.error)));
          }
          return const Center(child: CircularProgressIndicator());
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

  void _showRenameDialog(
      BuildContext context, int lockId, int fingerprintId, String currentName) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: currentName);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rename),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: l10n.nameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            child: Text(l10n.rename),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  void _showChangePeriodDialog(
      BuildContext context, int lockId, int fingerprintId) {
    final l10n = AppLocalizations.of(context)!;
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changePeriod),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startDateController,
              decoration: InputDecoration(labelText: l10n.startTime),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endDateController,
              decoration: InputDecoration(labelText: l10n.endTime),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final start = int.tryParse(startDateController.text);
              final end = int.tryParse(endDateController.text);
              if (start == null || end == null) return;
              context.read<FingerprintBloc>().add(ChangeFingerprintPeriod(
                    lockId: lockId,
                    fingerprintId: fingerprintId,
                    startDate: start,
                    endDate: end,
                  ));
              Navigator.pop(context);
            },
            child: Text(l10n.changePeriod),
          ),
        ],
      ),
    ).then((_) {
      startDateController.dispose();
      endDateController.dispose();
    });
  }
}
