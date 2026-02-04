import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/ui/pages/group_detail_page.dart';

class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({super.key});

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  late ApiService _apiService;
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(context.read<AuthRepository>());
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await _apiService.getGroupList();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.groupListLoadError(e.toString()))),
      );
    }
  }

  Future<void> _addGroup() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.addNewGroup, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.groupName,
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final groupName = controller.text;
                Navigator.pop(context);
                try {
                  await _apiService.addGroup(name: groupName);
                  _fetchGroups();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.groupAddedSuccessfully)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.groupAddError(e.toString()))),
                    );
                  }
                }
              }
            },
            child: Text(l10n.add, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _editGroup(Map<String, dynamic> group) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: group['name']);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.editGroup, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: l10n.newGroupName,
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newName = controller.text;
                Navigator.pop(context);
                try {
                  await _apiService.updateGroup(
                    groupId: group['groupId'].toString(),
                    newName: newName,
                  );
                  _fetchGroups();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.groupUpdated)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.updateErrorWithMsg(e.toString()))),
                    );
                  }
                }
              }
            },
            child: Text(l10n.save, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(Map<String, dynamic> group) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.deleteGroup, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.deleteGroupConfirmation(group['name'] ?? ''),
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteGroup(groupId: group['groupId'].toString());
        _fetchGroups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.groupDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteErrorWithMsg(e.toString()))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.groupManagement),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _groups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noGroupsCreatedYet,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addGroup,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.createGroup),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupDetailPage(
                              group: group,
                              onGroupUpdated: _fetchGroups,
                            ),
                          ),
                        ).then((_) => _fetchGroups());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 Container(
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(
                                     color: AppColors.primary.withValues(alpha: 0.1),
                                     shape: BoxShape.circle,
                                   ),
                                   child: const Icon(Icons.folder, color: AppColors.primary, size: 28),
                                 ),
                                 const SizedBox(width: 16),
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         group['name'] ?? l10n.unnamedGroup,
                                         style: const TextStyle(
                                           color: Colors.white, 
                                           fontWeight: FontWeight.bold,
                                           fontSize: 18,
                                         ),
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                       const SizedBox(height: 4),
                                       Text(
                                         'Grup ID: ${group['groupId']}',
                                         style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                       ),
                                     ],
                                   ),
                                 ),
                                 const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                               ],
                             ),
                             const SizedBox(height: 16),
                             const Divider(color: Colors.white10),
                             const SizedBox(height: 8),
                             Row(
                                   mainAxisAlignment: MainAxisAlignment.end,
                                   children: [
                                     TextButton.icon(
                                       onPressed: () => _editGroup(group),
                                       icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                       label: Text(l10n.rename, style: const TextStyle(color: Colors.blue)),
                                     ),
                                     const SizedBox(width: 8),
                                     TextButton.icon(
                                       onPressed: () => _deleteGroup(group),
                                       icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                       label: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
                                     ),
                                   ],
                                 )
                           ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _groups.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addGroup,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

}
