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
        title: Text(l10n.faces),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(l10n.clearAllFaces),
                  content: Text(l10n.confirmClearAll),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<FaceBloc>()
                            .add(ClearAllFaces(widget.lockId));
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
      body: BlocConsumer<FaceBloc, FaceState>(
        listener: (context, state) {
          if (state is FaceOperationSuccess) {
            context.read<FaceBloc>().add(LoadFaces(widget.lockId));
          }
          if (state is FaceOperationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Operation failed: ${state.error}'),
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
                  title: Text(face['name'] ?? 'No Name'),
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
            return Center(child: Text('${l10n.errorLabel}: ${state.error}'));
          }
          return Center(child: Text(l10n.faces));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bloc = context.read<FaceBloc>();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFacePage(lockId: widget.lockId),
            ),
          );
          if (result == true) {
            bloc.add(LoadFaces(widget.lockId));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, int lockId, int faceId, String currentName) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.renameFace),
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
              context.read<FaceBloc>().add(RenameFace(
                    lockId: lockId,
                    faceId: faceId,
                    name: nameController.text,
                  ));
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.rename),
          ),
        ],
      ),
    );
  }

  void _showChangePeriodDialog(BuildContext context, int lockId, int faceId) {
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
              context.read<FaceBloc>().add(ChangeFacePeriod(
                    lockId: lockId,
                    faceId: faceId,
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
