import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme.dart';
import '../../../api_service.dart';
import '../../../repositories/auth_repository.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'send_ekey_page.dart';  // Will be created next
import '../ekey_detail_page.dart';

class EKeyListPage extends StatefulWidget {
  final Map<String, dynamic> lock;

  const EKeyListPage({super.key, required this.lock});

  @override
  State<EKeyListPage> createState() => _EKeyListPageState();
}

class _EKeyListPageState extends State<EKeyListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allKeys = [];
  List<Map<String, dynamic>> _filteredKeys = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _showOnlyAdmins = false; // New filter state

  @override
  void initState() {
    super.initState();
    _fetchKeys();
  }

  Future<void> _fetchKeys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final apiService = ApiService(context.read<AuthRepository>());

    try {
      await apiService.getAccessToken();
      final accessToken = apiService.accessToken;

      if (accessToken == null) throw Exception(l10n.noAccessPermission);

      final keys = await apiService.getLockEKeys(
        accessToken: accessToken,
        lockId: widget.lock['lockId'].toString(),
      );

      if (mounted) {
        setState(() {
          _allKeys = keys;
          _filteredKeys = keys;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterKeys(String query) {
    setState(() {
      _filteredKeys = _allKeys.where((key) {
        final name = (key['keyName'] ?? '').toLowerCase();
        final username = (key['username'] ?? '').toLowerCase();
        final matchesQuery = query.isEmpty || name.contains(query.toLowerCase()) || username.contains(query.toLowerCase());
        
        if (_showOnlyAdmins) {
          final keyRight = key['keyRight'];
          // keyRight 1 means Admin
          final isAdmin = keyRight == 1 || keyRight == '1';
          return matchesQuery && isAdmin;
        }
        
        return matchesQuery;
      }).toList();
    });
  }

  void _toggleAdminFilter() {
    setState(() {
      _showOnlyAdmins = !_showOnlyAdmins;
      _filterKeys(_searchController.text);
    });
  }

  void _resetKeys() {
    // Reset function - for now just re-fetch as per "Sıfırla" button intent often implies reset filters or reload
    // Based on user request "Sıfırla" button on top right usually resets data or filters. 
    // Assuming reload here or reset custom aliases if implemented. For now, reload.
    _searchController.clear();
    _fetchKeys();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.electronicKeysMenu.replaceAll('\n', ' '), style: const TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _resetKeys,
            child: Text(AppLocalizations.of(context)!.reset, style: const TextStyle(color: Colors.white)),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _filterKeys,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search,
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),


              // Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: AppLocalizations.of(context)!.all,
                      isSelected: !_showOnlyAdmins,
                      onTap: () {
                        if (_showOnlyAdmins) _toggleAdminFilter();
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildFilterChip(
                      label: AppLocalizations.of(context)!.admins, // Make sure to add this to localization if missing, or use 'Admins'
                      isSelected: _showOnlyAdmins,
                      onTap: () {
                        if (!_showOnlyAdmins) _toggleAdminFilter();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                        : _filteredKeys.isEmpty
                            ? Center(child: Text(AppLocalizations.of(context)!.noEKeysFound, style: const TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: _filteredKeys.length,
                                padding: const EdgeInsets.only(bottom: 150), // Increased padding for bottom button
                                itemBuilder: (context, index) {
                                  final key = _filteredKeys[index];
                                  return _buildKeyCard(key);
                                },
                              ),
              ),
            ],
          ),
          
          // Floating Bottom Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFF1E1E1E),
              padding: EdgeInsets.only(
                left: 16.0, 
                right: 16.0, 
                top: 16.0, 
                bottom: 80.0 + MediaQuery.of(context).padding.bottom
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SendEKeyPage(lock: widget.lock)),
                    ).then((_) => _fetchKeys()); // Refresh on return
                  },
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: Text(AppLocalizations.of(context)!.sendKey, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: AppColors.primary,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCard(Map<String, dynamic> keyItem) {
    /* 
       Keys map fields based on typical TTLock responses:
       keyName, username, startDate, endDate, keyStatus
    */
    final username = keyItem['username'] ?? ''; // Often email or phone
    final startDate = DateTime.fromMillisecondsSinceEpoch(keyItem['startDate'] ?? 0);
    final endDate = DateTime.fromMillisecondsSinceEpoch(keyItem['endDate'] ?? 0);
    final keyRight = keyItem['keyRight'];
    final isAdmin = keyRight == 1 || keyRight == '1';
    
    // Check if expired
    final isExpired = DateTime.now().isAfter(endDate);
    
    // Format dates: 2026.01.30 00:00
    final startStr = "${startDate.year}.${startDate.month.toString().padLeft(2,'0')}.${startDate.day.toString().padLeft(2,'0')} ${startDate.hour.toString().padLeft(2,'0')}:${startDate.minute.toString().padLeft(2,'0')}";
    final endStr = "${endDate.year}.${endDate.month.toString().padLeft(2,'0')}.${endDate.day.toString().padLeft(2,'0')} ${endDate.hour.toString().padLeft(2,'0')}:${endDate.minute.toString().padLeft(2,'0')}";

    return InkWell(
      onTap: () {
        // Navigate to details if needed, reusing existing EKeyDetailPage
        Navigator.push(
            context,
            MaterialPageRoute(
               builder: (context) => EKeyDetailPage(
                 eKey: keyItem, 
                 lockId: widget.lock['lockId'].toString(),
                 lockName: widget.lock['name'] ?? '',
                 isOwner: true // Assuming user viewing list is owner/admin
               )
            )
        ).then((_) => _fetchKeys());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF2C2C2C))),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF0A84FF), // Blue circle
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.keyFor(username), // Per design request mostly shows "Key for [receiver]"
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startStr - $endStr',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.roleAdmin, // 'Yönetici' or 'Admin'
                          style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Status / Arrow
            if (isExpired)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(AppLocalizations.of(context)!.expired, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                       Icon(Icons.watch_later_outlined, color: Colors.red, size: 16),
                    ]
                  )
                ],
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
