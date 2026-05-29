import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/add_face_page.dart';
import 'package:yavuz_lock/blocs/face/face_bloc.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class FacePage extends StatefulWidget {
  final int lockId;
  const FacePage({super.key, required this.lockId});

  @override
  State<FacePage> createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  @override
  void initState() {
    super.initState();
    context.read<FaceBloc>().add(LoadFaces(widget.lockId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.facesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.clearAllFacesTitle),
                  content: Text(l10n.clearAllFacesConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<FaceBloc>()
                            .add(ClearAllFaces(widget.lockId));
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
      body: BlocConsumer<FaceBloc, FaceState>(
        listener: (context, state) {
          if (state is FaceOperationSuccess) {
            context.read<FaceBloc>().add(LoadFaces(widget.lockId));
          }
          if (state is FaceOperationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.operationFailedWithMsg(state.error)),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FaceLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FacesLoaded) {
            final faces = state.faces;
            if (faces.isEmpty) {
              return Center(child: Text(l10n.noFacesFound));
            }
            return ListView.builder(
              itemCount: faces.length,
              itemBuilder: (context, index) {
                final face = faces[index];
                return ListTile(
                  title: Text(face['name'] ?? l10n.noName),
                  subtitle: Text('ID: ${face['faceId']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context
                          .read<FaceBloc>()
                          .add(DeleteFace(widget.lockId, face['faceId']));
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
                            if (!mounted) return;
                            _showRenameDialog(context, widget.lockId,
                                face['faceId'], face['name']);
                          },
                        ),
                        PopupMenuItem(
                          child: Text(l10n.changePeriod),
                          onTap: () {
                            if (!mounted) return;
                            _showChangePeriodDialog(
                                context, widget.lockId, face['faceId']);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          }
          if (state is FaceOperationFailure) {
            return Center(child: Text(l10n.errorWithMsg(state.error)));
          }
          return Center(child: const CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFacePage(lockId: widget.lockId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, int lockId, int faceId, String currentName) {
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
              context.read<FaceBloc>().add(RenameFace(
                    lockId: lockId,
                    faceId: faceId,
                    name: nameController.text,
                  ));
              Navigator.pop(context);
            },
            child: Text(l10n.rename),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  void _showChangePeriodDialog(BuildContext context, int lockId, int faceId) {
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
              context.read<FaceBloc>().add(ChangeFacePeriod(
                    lockId: lockId,
                    faceId: faceId,
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
