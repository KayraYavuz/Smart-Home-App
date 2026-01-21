import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/add_face_page.dart';
import 'package:yavuz_lock/blocs/face/face_bloc.dart';

class FacePage extends StatefulWidget {
  final int lockId;
  const FacePage({super.key, required this.lockId});

  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  @override
  void initState() {
    super.initState();
    context.read<FaceBloc>().add(LoadFaces(widget.lockId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Faces'),
                  content: const Text('Are you sure you want to clear all faces?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<FaceBloc>().add(ClearAllFaces(widget.lockId));
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
              return const Center(child: Text('No faces found.'));
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
                      context.read<FaceBloc>().add(DeleteFace(widget.lockId, face['faceId']));
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
                                face['faceId'],
                                face['name']);
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Change Period'),
                          onTap: () {
                            _showChangePeriodDialog(
                                context,
                                widget.lockId,
                                face['faceId']);
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
            return Center(child: Text('Error: ${state.error}'));
          }
          return Center(child: Text('Face management for lock ${widget.lockId}'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFacePage(lockId: widget.lockId),
            ),
          );
          if (result == true) {
            context.read<FaceBloc>().add(LoadFaces(widget.lockId));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, int lockId, int faceId, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Face'),
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
              context.read<FaceBloc>().add(RenameFace(
                    lockId: lockId,
                    faceId: faceId,
                    name: nameController.text,
                  ));
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showChangePeriodDialog(BuildContext context, int lockId, int faceId) {
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
              context.read<FaceBloc>().add(ChangeFacePeriod(
                    lockId: lockId,
                    faceId: faceId,
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
