import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';


class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _allKeys = [];
  bool _isLoading = false;
  bool _isLoadingKeys = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(AuthRepository());
    _loadUsers();
    _loadKeys();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getUserList(pageNo: 1, pageSize: 100);
      if (!mounted) return;
      setState(() {
        _users = List<Map<String, dynamic>>.from(response['list'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _loadKeys() async {
     if (_isLoadingKeys) return;
     setState(() => _isLoadingKeys = true);
     try {
       final locks = await _apiService.getKeyList();
       List<Map<String, dynamic>> keys = [];
       
       await Future.wait(locks.map((lock) async {
          try {
             final lockKeys = await _apiService.getLockEKeys(
               accessToken: _apiService.accessToken!, 
               lockId: lock['lockId'].toString(),
               pageNo: 1, 
               pageSize: 100
             );
             for (var k in lockKeys) {
               k['lockAlias'] = lock['lockAlias'] ?? lock['lockName'];
             }
             keys.addAll(lockKeys);
          } catch (e) {
             debugPrint('Error fetching keys for ${lock['lockId']}: $e');
          }
       }));
       
       if (!mounted) return;
       setState(() {
         _allKeys = keys;
         _isLoadingKeys = false;
       });
     } catch (e) {
       if (!mounted) return;
       setState(() => _isLoadingKeys = false);
       debugPrint('Key load error: $e');
     }
  }

  void _showAddUserDialog() {
    final l10n = AppLocalizations.of(context)!;
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.registerNewUser, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.userEmailOrPhone,
                labelStyle: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.password,
                labelStyle: const TextStyle(color: Colors.grey),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                try {
                  await _apiService.registerUser(
                    username: usernameController.text,
                    password: passwordController.text,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.saveSuccess), backgroundColor: AppColors.success),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.errorWithMsg(e.toString())), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: Text(l10n.save, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(l10n.deleteAccount, style: const TextStyle(color: Colors.white)),
        content: Text('${user['username']} - ${l10n.deleteAccountConfirmation}', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              try {
                await _apiService.deleteUser(username: user['username']);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.accountDeletedMessage), backgroundColor: AppColors.success),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.errorWithMsg(e.toString())), backgroundColor: AppColors.error),
                );
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFreeze(Map<String, dynamic> key, bool freeze, AppLocalizations l10n) async {
    try {
      await _apiService.getAccessToken();
      if (_apiService.accessToken == null) throw Exception('Token not found');

      if (freeze) {
        await _apiService.freezeEKey(accessToken: _apiService.accessToken!, keyId: key['keyId'].toString());
      } else {
        await _apiService.unfreezeEKey(accessToken: _apiService.accessToken!, keyId: key['keyId'].toString());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(freeze ? l10n.keyFrozen : l10n.keyUnfrozen),
        backgroundColor: freeze ? Colors.orange : Colors.green
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString())), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(l10n.userAccessManagement),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.appUsers),
              Tab(text: l10n.accessKeysFreeze),
            ],
            indicatorColor: AppColors.primary,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _showAddUserDialog,
              tooltip: l10n.registerNewUser,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadUsers();
                _loadKeys();
              },
              tooltip: l10n.refresh,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildUserListTab(l10n),
            _buildKeyFreezeTab(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListTab(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: l10n.searchUser,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _users.isEmpty
                  ? _buildEmptyState(l10n)
                  : _buildUserList(),
        ),
      ],
    );
  }

  Widget _buildKeyFreezeTab(AppLocalizations l10n) {
     if (_isLoadingKeys) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
     if (_allKeys.isEmpty) return Center(child: Text(l10n.noSharedKeys, style: const TextStyle(color: Colors.grey)));

     return RefreshIndicator(
       onRefresh: _loadKeys,
       child: ListView.builder(
         padding: const EdgeInsets.all(16),
         itemCount: _allKeys.length,
         itemBuilder: (context, index) {
           final key = _allKeys[index];
           final status = key['keyStatus'].toString();
           final bool frozen = status == '110402';
           
           return Card(
             color: const Color(0xFF1E1E1E),
             margin: const EdgeInsets.only(bottom: 8),
             child: ListTile(
               leading: Icon(
                 frozen ? Icons.lock : Icons.lock_open,
                 color: frozen ? Colors.orange : Colors.green,
               ),
               title: Text(key['keyName'] ?? key['username'] ?? l10n.key, style: const TextStyle(color: Colors.white)),
               subtitle: Text('${key['lockAlias']} - ${frozen ? l10n.frozen : l10n.active}', style: TextStyle(color: Colors.grey[400])),
               trailing: Switch(
                 value: frozen,
                                 activeTrackColor: Colors.orange,
                 onChanged: (val) => _toggleFreeze(key, val, l10n),
               ),
             ),
           );
         },
       ),
     );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          Text(l10n.noData, style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final filteredUsers = _users.where((user) {
      final searchTerm = _searchController.text.toLowerCase();
      final username = user['username'].toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return username.contains(searchTerm) || email.contains(searchTerm);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.2),
              child: Text(
                (user['username'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user['username'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Text(user['email'] ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _deleteUser(user),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      },
    );
  }
}