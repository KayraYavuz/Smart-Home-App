import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_bloc.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_event.dart';
import 'package:yavuz_lock/blocs/fingerprint/fingerprint_state.dart';
import 'package:yavuz_lock/add_fingerprint_page.dart';
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
        title: Text(l10n.fingerprints),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.clearAllFingerprints),
                  content: Text(l10n.confirmClearAll),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<FingerprintBloc>()
                            .add(ClearAllFingerprints(widget.lockId));
                        Navigator.pop(dialogContext);
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
                          child: Text(l10n.rename),
                          onTap: () {
                            _showRenameDialog(
                                context,
                                widget.lockId,
                                fingerprint['fingerprintId'],
                                fingerprint['fingerprintName']);
                          },
                        ),
                        PopupMenuItem(
                          child: Text(l10n.changePeriod),
                          onTap: () {
                            _showChangePeriodDialog(context, widget.lockId,
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
            return Center(child: Text('${l10n.errorLabel}: ${state.error}'));
          }
          return Center(child: Text(l10n.fingerprints));
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
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.renameFingerprint),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: l10n.newName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<FingerprintBloc>().add(RenameFingerprint(
                    lockId: lockId,
                    fingerprintId: fingerprintId,
                    fingerprintName: nameController.text,
                  ));
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.rename),
          ),
        ],
      ),
    );
  }

  void _showChangePeriodDialog(
      BuildContext context, int lockId, int fingerprintId) {
    final l10n = AppLocalizations.of(context)!;
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changePeriod),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startDateController,
              decoration: InputDecoration(labelText: l10n.startDateMsLabel),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endDateController,
              decoration: InputDecoration(labelText: l10n.endDateMsLabel),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<FingerprintBloc>().add(ChangeFingerprintPeriod(
                    lockId: lockId,
                    fingerprintId: fingerprintId,
                    startDate: int.parse(startDateController.text),
                    endDate: int.parse(endDateController.text),
                  ));
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.change),
          ),
        ],
      ),
    );
  }
}
