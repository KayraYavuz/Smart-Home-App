import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';

class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({Key? key}) : super(key: key);

  @override
  _GroupManagementPageState createState() => _GroupManagementPageState();
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
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grup listesi yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _addGroup() async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Yeni Grup Ekle', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Grup Adı',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await _apiService.addGroup(name: controller.text);
                  _fetchGroups();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Grup başarıyla eklendi')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Grup eklenemedi: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Ekle', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _editGroup(Map<String, dynamic> group) async {
    final TextEditingController controller = TextEditingController(text: group['name'] ?? '');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Grubu Düzenle', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Yeni Grup Adı',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await _apiService.updateGroup(
                    groupId: group['groupId'].toString(),
                    newName: controller.text,
                  );
                  _fetchGroups();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Grup güncellendi')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Güncelleme hatası: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Kaydet', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup(Map<String, dynamic> group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Grubu Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          '${group['name']} grubunu silmek istediğinizden emin misiniz?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
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
            const SnackBar(content: Text('Grup silindi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silme hatası: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Grup Yönetimi'),
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
                      const Text(
                        'Henüz grup oluşturulmamış',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addGroup,
                        icon: const Icon(Icons.add),
                        label: const Text('Grup Oluştur'),
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
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.folder, color: AppColors.primary),
                        ),
                        title: Text(
                          group['name'] ?? 'İsimsiz Grup',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'ID: ${group['groupId']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editGroup(group),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteGroup(group),
                            ),
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
