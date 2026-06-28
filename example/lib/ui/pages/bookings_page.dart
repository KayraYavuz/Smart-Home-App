import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/services/email_service.dart';
import 'package:yavuz_lock/ui/theme.dart';

String _t(BuildContext context, {required String tr, required String en}) {
  return Localizations.localeOf(context).languageCode == 'tr' ? tr : en;
}

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  bool? _isPremium;
  final _db = FirebaseFirestore.instance;
  String? _uid;
  List<Map<String, dynamic>> _units = [];
  Map<String, List<Map<String, dynamic>>> _activeBookings = {};
  bool _isLoading = false;
  ApiService? _apiRef;

  // Provider'dan bir kez yakalanan ApiService — async işlemlerden sonra
  // context.read çağırmayı (dispose sonrası hata riskini) önler.
  ApiService get _api => _apiRef ??= context.read<ApiService>();

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiRef ??= context.read<ApiService>();
  }

  Future<void> _checkPremium() async {
    final prefs = await SharedPreferences.getInstance();
    var email = prefs.getString('saved_email') ?? '';
    // SharedPreferences reinstall'da silinir; Keychain'den geri yükle
    if (email.isEmpty) {
      email = await AuthRepository().getEmail() ?? '';
      if (email.isNotEmpty) await prefs.setString('saved_email', email);
    }
    if (email.isEmpty) {
      if (mounted) setState(() => _isPremium = false);
      return;
    }
    _uid = email.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    try {
      final doc = await _db.collection('users').doc(_uid).get()
          .timeout(const Duration(seconds: 10));
      final premium = doc.data()?['isPremium'] == true;
      if (mounted) setState(() => _isPremium = premium);
      if (premium) {
        _loadUnits();
        _loadActiveBookings();
      }
    } catch (e) {
      debugPrint('⚠️ Firestore premium check failed: $e');
      if (mounted) setState(() => _isPremium = false);
    }
  }

  void _loadUnits() {
    _db
        .collection('users')
        .doc(_uid)
        .collection('units')
        .orderBy('createdAt')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _units = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      });
      _loadActiveBookings();
    });
  }

  Future<void> _loadActiveBookings() async {
    if (_uid == null) return;
    final now = DateTime.now();
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('bookings')
        .where('status', isEqualTo: 'active')
        .get();

    final Map<String, List<Map<String, dynamic>>> map = {};
    final List<DocumentReference> expired = [];
    for (final doc in snap.docs) {
      final data = {'id': doc.id, ...doc.data()};
      final endTime = (data['endTime'] as Timestamp?)?.toDate();
      if (endTime != null && endTime.isAfter(now)) {
        final unitId = data['unitId'] as String?;
        if (unitId != null) {
          map[unitId] = [...(map[unitId] ?? []), data];
        }
      } else if (endTime != null) {
        // Süresi dolmuş — şifre/eKey kilit tarafından zaten reddedilir,
        // sadece kaydı temizle (active listesini şişirmesin).
        expired.add(doc.reference);
      }
    }
    // Süresi dolanları toplu olarak 'completed' yap
    if (expired.isNotEmpty) {
      final batch = _db.batch();
      for (final ref in expired) {
        batch.update(ref, {'status': 'completed'});
      }
      batch.commit().catchError((e) => debugPrint('⚠️ Süresi dolan rezervasyon temizlenemedi: $e'));
    }
    if (!mounted) return;
    setState(() => _activeBookings = map);
  }

  String _getUnitStatus(String unitId) =>
      (_activeBookings[unitId]?.isNotEmpty == true) ? 'occupied' : 'vacant';

  Map<String, dynamic>? _getActiveBooking(String unitId) =>
      _activeBookings[unitId]?.firstOrNull;

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _addUnit() async {
    final nameCtrl = TextEditingController();
    String selectedType = 'court';

    final types = [
      {'value': 'court', 'icon': Icons.sports_tennis, 'tr': 'Kort', 'en': 'Court'},
      {'value': 'room', 'icon': Icons.hotel, 'tr': 'Oda', 'en': 'Room'},
      {'value': 'apartment', 'icon': Icons.apartment, 'tr': 'Daire', 'en': 'Apartment'},
      {'value': 'other', 'icon': Icons.category, 'tr': 'Diğer', 'en': 'Other'},
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(_t(ctx, tr: 'Birim Ekle', en: 'Add Unit'),
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _t(ctx, tr: 'Birim Adı (örn: Kort-1, 101)', en: 'Unit Name (e.g. Court-1, 101)'),
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_t(ctx, tr: 'Tür:', en: 'Type:'),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: types.map((t) {
                    final selected = selectedType == t['value'];
                    final label = Localizations.localeOf(ctx).languageCode == 'tr'
                        ? t['tr'] as String
                        : t['en'] as String;
                    return GestureDetector(
                      onTap: () => setSt(() => selectedType = t['value'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t['icon'] as IconData,
                                size: 16,
                                color: selected ? Colors.black : Colors.grey),
                            const SizedBox(width: 6),
                            Text(label,
                                style: TextStyle(
                                    color: selected ? Colors.black : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t(ctx, tr: 'İptal', en: 'Cancel'),
                    style: const TextStyle(color: Colors.grey))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_t(ctx, tr: 'Ekle', en: 'Add'),
                    style: const TextStyle(color: AppColors.primary))),
          ],
        ),
      ),
    );

    if (confirmed != true || nameCtrl.text.trim().isEmpty) return;
    await _db.collection('users').doc(_uid).collection('units').add({
      'name': nameCtrl.text.trim(),
      'type': selectedType,
      'lockId': null,
      'lockName': null,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> _deleteUnit(Map<String, dynamic> unit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(_t(ctx, tr: 'Birimi Sil', en: 'Delete Unit'),
            style: const TextStyle(color: Colors.white)),
        content: Text(
            _t(ctx,
                tr: '"${unit['name']}" silinsin mi? Tüm rezervasyonlar da silinir.',
                en: 'Delete "${unit['name']}"? All bookings will also be deleted.'),
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t(ctx, tr: 'İptal', en: 'Cancel'),
                  style: const TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t(ctx, tr: 'Sil', en: 'Delete'),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    final bookingsSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection('bookings')
        .where('unitId', isEqualTo: unit['id'])
        .get();

    final batch = _db.batch();
    for (final doc in bookingsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('users').doc(_uid).collection('units').doc(unit['id']));
    await batch.commit();
  }

  Future<void> _assignLock(Map<String, dynamic> unit) async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> locks = [];
    try {
      locks = await _api.getKeyList();
    } catch (e) {
      _snack(_t(context, tr: 'Kilitler yüklenemedi: $e', en: 'Failed to load locks: $e'), error: true);
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (locks.isEmpty) {
      _snack(_t(context, tr: 'Hiç kilit bulunamadı', en: 'No locks found'), error: true);
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(_t(ctx, tr: 'Kilit Seç', en: 'Select Lock'),
            style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: locks.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.lock, color: AppColors.primary),
              title: Text(locks[i]['lockAlias'] ?? 'Lock ${locks[i]['lockId']}',
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text('ID: ${locks[i]['lockId']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, locks[i]),
            ),
          ),
        ),
      ),
    );

    if (selected == null) return;
    await _db.collection('users').doc(_uid).collection('units').doc(unit['id']).update({
      'lockId': selected['lockId'].toString(),
      'lockName': selected['lockAlias'] ?? 'Lock ${selected['lockId']}',
    });
    _snack(_t(context,
        tr: 'Kilit atandı: ${selected['lockAlias']}',
        en: 'Lock assigned: ${selected['lockAlias']}'));
  }

  Future<void> _handleUnitTap(Map<String, dynamic> unit) async {
    if (unit['lockId'] == null) {
      await _assignLock(unit);
      return;
    }
    final status = _getUnitStatus(unit['id'] as String);
    if (status == 'occupied') {
      await _showActiveBooking(unit);
    } else {
      await _showNewBooking(unit);
    }
  }

  Future<void> _showNewBooking(Map<String, dynamic> unit) async {
    final types = [
      {'value': 'hourly', 'icon': Icons.access_time, 'tr': 'Saatlik', 'en': 'Hourly'},
      {'value': 'daily', 'icon': Icons.today, 'tr': 'Günlük', 'en': 'Daily'},
      {'value': 'monthly', 'icon': Icons.calendar_month, 'tr': 'Aylık', 'en': 'Monthly'},
      {'value': 'yearly', 'icon': Icons.event_repeat, 'tr': 'Yıllık', 'en': 'Yearly'},
      {'value': 'cyclic', 'icon': Icons.repeat, 'tr': 'Haftalık Program', 'en': 'Weekly Schedule'},
    ];

    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(_t(ctx, tr: 'Rezervasyon Türü', en: 'Booking Type'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...types.map((t) {
              final label = Localizations.localeOf(ctx).languageCode == 'tr'
                  ? t['tr'] as String
                  : t['en'] as String;
              return ListTile(
                leading: Icon(t['icon'] as IconData, color: AppColors.primary),
                title: Text(label, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, t['value'] as String),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (type != null) await _createBooking(unit, type);
  }

  Future<DateTime?> _pickDateTime(BuildContext ctx, DateTime initial, DateTime first) async {
    final date = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: first,
        lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _fmtDt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// Seçilen günleri (0=Pzt..6=Paz) TTLock algoritmik cyclic şifre tipine çevirir.
  /// Preset tipler sınırlı: günlük / hafta içi / hafta sonu / tek gün.
  /// Arbitrer kombinasyon (ör. Pzt+Çar+Cum) preset'e tam oturmaz → dailyCyclic'e düşer.
  PasscodeType _cyclicPasscodeType(Set<int> days) {
    final s = days.toList()..sort();
    if (s.length == 7) return PasscodeType.dailyCyclic;
    if (s.length == 5 && s.every((d) => d <= 4)) return PasscodeType.workdayCyclic;
    if (s.length == 2 && s.contains(5) && s.contains(6)) return PasscodeType.weekendCyclic;
    if (s.length == 1) {
      const single = [
        PasscodeType.mondayCyclic, PasscodeType.tuesdayCyclic,
        PasscodeType.wednesdayCyclic, PasscodeType.thursdayCyclic,
        PasscodeType.fridayCyclic, PasscodeType.saturdayCyclic,
        PasscodeType.sundayCyclic,
      ];
      return single[s.first];
    }
    return PasscodeType.dailyCyclic; // arbitrer set için en yakın fallback
  }

  /// Gün seti preset bir cyclic tipe tam oturuyor mu? (PIN periyodik uyarısı için)
  bool _cyclicMapsExactly(Set<int> days) {
    final s = days.toList()..sort();
    if (s.length == 7) return true;
    if (s.length == 5 && s.every((d) => d <= 4)) return true;
    if (s.length == 2 && s.contains(5) && s.contains(6)) return true;
    if (s.length == 1) return true;
    return false;
  }

  List<Map<String, dynamic>> _buildCyclicConfig(Set<int> days, TimeOfDay start, TimeOfDay end) {
    return days.map((d) {
      final apiDay = d == 6 ? 7 : d + 1;
      return {
        'weekDay': apiDay,
        'startTime': start.hour * 60 + start.minute,
        'endTime': end.hour * 60 + end.minute,
      };
    }).toList();
  }

  String _cyclicLabel(BuildContext ctx, Set<int> days, TimeOfDay start, TimeOfDay end) {
    final names = [
      _t(ctx, tr: 'Pzt', en: 'Mon'), _t(ctx, tr: 'Sal', en: 'Tue'),
      _t(ctx, tr: 'Çar', en: 'Wed'), _t(ctx, tr: 'Per', en: 'Thu'),
      _t(ctx, tr: 'Cum', en: 'Fri'), _t(ctx, tr: 'Cmt', en: 'Sat'),
      _t(ctx, tr: 'Paz', en: 'Sun'),
    ];
    final ds = (days.toList()..sort()).map((d) => names[d]).join(', ');
    final s = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final e = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$ds $s–$e';
  }

  Future<void> _createBooking(Map<String, dynamic> unit, String bookingType) async {
    final guestNameCtrl = TextEditingController();
    final guestContactCtrl = TextEditingController();
    final guestEmailCtrl = TextEditingController(); // PIN şifresini göndermek için

    final now = DateTime.now();
    DateTime startTime = now;
    DateTime endTime = switch (bookingType) {
      'hourly' => now.add(const Duration(hours: 1)),
      'daily' => now.add(const Duration(days: 1)),
      'monthly' => now.add(const Duration(days: 30)),
      _ => now.add(const Duration(days: 365)),
    };

    String accessType = (bookingType == 'hourly' || bookingType == 'daily') ? 'pin' : 'ekey';
    Set<int> cyclicDays = {0, 1, 2, 3, 4};
    TimeOfDay cyclicStart = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay cyclicEnd = const TimeOfDay(hour: 22, minute: 0);

    final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final dayLabelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
              _t(ctx, tr: 'Rezervasyon — ${unit['name']}', en: 'Booking — ${unit['name']}'),
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: guestNameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _t(ctx, tr: 'İsim', en: 'Name'),
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: guestContactCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: accessType == 'ekey'
                        ? _t(ctx, tr: 'Alıcı E-posta *', en: 'Recipient Email *')
                        : _t(ctx, tr: 'Telefon', en: 'Phone'),
                    labelStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                // PIN için: şifreyi e-postayla göndermek üzere ayrı, net alan
                if (accessType == 'pin') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: guestEmailCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: _t(ctx,
                          tr: 'E-posta (şifre buraya gönderilir)',
                          en: 'Email (PIN sent here)'),
                      labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey, size: 20),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (bookingType != 'cyclic') ...[
                  Text(_t(ctx, tr: 'Başlangıç:', en: 'Start:'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  TextButton(
                    onPressed: () async {
                      final dt = await _pickDateTime(ctx, startTime, DateTime.now());
                      if (dt != null) setSt(() => startTime = dt);
                    },
                    child: Text(_fmtDt(startTime),
                        style: const TextStyle(color: AppColors.primary)),
                  ),
                  Text(_t(ctx, tr: 'Bitiş:', en: 'End:'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  TextButton(
                    onPressed: () async {
                      final dt = await _pickDateTime(ctx, endTime,
                          startTime.add(const Duration(minutes: 30)));
                      if (dt != null) setSt(() => endTime = dt);
                    },
                    child: Text(_fmtDt(endTime),
                        style: const TextStyle(color: AppColors.primary)),
                  ),
                ],
                if (bookingType == 'cyclic') ...[
                  Text(_t(ctx, tr: 'Geçerlilik Başlangıcı:', en: 'Valid From:'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  TextButton(
                    onPressed: () async {
                      final dt = await _pickDateTime(ctx, startTime, DateTime.now());
                      if (dt != null) setSt(() => startTime = dt);
                    },
                    child: Text(_fmtDt(startTime),
                        style: const TextStyle(color: AppColors.primary)),
                  ),
                  Text(_t(ctx, tr: 'Geçerlilik Bitişi:', en: 'Valid Until:'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  TextButton(
                    onPressed: () async {
                      final dt = await _pickDateTime(ctx, endTime,
                          startTime.add(const Duration(days: 1)));
                      if (dt != null) setSt(() => endTime = dt);
                    },
                    child: Text(_fmtDt(endTime),
                        style: const TextStyle(color: AppColors.primary)),
                  ),
                  const SizedBox(height: 8),
                  Text(_t(ctx, tr: 'Günler:', en: 'Days:'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      final label = Localizations.localeOf(ctx).languageCode == 'tr'
                          ? dayLabels[i]
                          : dayLabelsEn[i];
                      final sel = cyclicDays.contains(i);
                      return GestureDetector(
                        onTap: () => setSt(() {
                          if (sel) cyclicDays.remove(i); else cyclicDays.add(i);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(label,
                              style: TextStyle(
                                  color: sel ? Colors.black : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(_t(ctx, tr: 'Saatler:', en: 'Hours:'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: cyclicStart);
                          if (t != null) setSt(() => cyclicStart = t);
                        },
                        child: Text(
                            '${cyclicStart.hour.toString().padLeft(2, '0')}:${cyclicStart.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.primary, fontSize: 16)),
                      ),
                      const Text('–', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: cyclicEnd);
                          if (t != null) setSt(() => cyclicEnd = t);
                        },
                        child: Text(
                            '${cyclicEnd.hour.toString().padLeft(2, '0')}:${cyclicEnd.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.primary, fontSize: 16)),
                      ),
                    ],
                  ),
                ],
                const Divider(color: Colors.grey),
                Text(_t(ctx, tr: 'Erişim Yöntemi:', en: 'Access Method:'),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Row(
                  children: [
                    Radio<String>(
                      value: 'pin',
                      groupValue: accessType,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setSt(() => accessType = v!),
                    ),
                    Text(_t(ctx, tr: 'Şifre (PIN)', en: 'PIN Code'),
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'ekey',
                      groupValue: accessType,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setSt(() => accessType = v!),
                    ),
                    Text(_t(ctx, tr: 'Dijital Anahtar', en: 'eKey'),
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t(ctx, tr: 'İptal', en: 'Cancel'),
                    style: const TextStyle(color: Colors.grey))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(_t(ctx, tr: 'Rezervasyon Yap', en: 'Book'),
                    style: const TextStyle(color: AppColors.primary))),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    // Conflict detection
    final conflictSnap = await _db
        .collection('users')
        .doc(_uid)
        .collection('bookings')
        .where('unitId', isEqualTo: unit['id'])
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in conflictSnap.docs) {
      final data = doc.data();
      if (bookingType != 'cyclic') {
        final bStart = (data['startTime'] as Timestamp?)?.toDate();
        final bEnd = (data['endTime'] as Timestamp?)?.toDate();
        if (bStart != null && bEnd != null) {
          if (startTime.isBefore(bEnd) && endTime.isAfter(bStart)) {
            _snack(_t(context,
                tr: 'Bu zaman diliminde başka bir rezervasyon var',
                en: 'Another booking exists for this time slot'),
                error: true);
            return;
          }
        }
      }
    }

    setState(() => _isLoading = true);
    try {
      final lockId = unit['lockId'].toString();
      String? pinCode;
      int? keyboardPwdId;
      String? keyId;
      String? cyclicLabelStr;
      List<Map<String, dynamic>>? cyclicConfigData;

      if (bookingType == 'cyclic' && cyclicDays.isNotEmpty) {
        cyclicConfigData = _buildCyclicConfig(cyclicDays, cyclicStart, cyclicEnd);
        cyclicLabelStr = _cyclicLabel(context, cyclicDays, cyclicStart, cyclicEnd);
      }

      String? token;
      if (accessType == 'pin') {
        // Algoritmik şifre — gateway GEREKTİRMEZ. Kilit, kendi saati + gizli
        // anahtarıyla şifreyi offline doğrular. Şifreyi TTLock üretir.
        PasscodeType pType = PasscodeType.timed;
        int pStart = startTime.millisecondsSinceEpoch;
        int pEnd = endTime.millisecondsSinceEpoch;

        if (bookingType == 'cyclic' && cyclicDays.isNotEmpty) {
          // Periyodik PIN: gün setini preset cyclic tipe çevir.
          // Geçerlilik tarih aralığı + günlük saat penceresini birleştir.
          pType = _cyclicPasscodeType(cyclicDays);
          pStart = DateTime(startTime.year, startTime.month, startTime.day,
              cyclicStart.hour, cyclicStart.minute).millisecondsSinceEpoch;
          pEnd = DateTime(endTime.year, endTime.month, endTime.day,
              cyclicEnd.hour, cyclicEnd.minute).millisecondsSinceEpoch;
          if (!_cyclicMapsExactly(cyclicDays)) {
            _snack(_t(context,
                tr: 'PIN periyodik sadece günlük/hafta içi/hafta sonu/tek gün destekler — "her gün" olarak ayarlandı',
                en: 'Periodic PIN supports only daily/workdays/weekend/single day — set to "daily"'),
                error: true);
          }
        }

        final result = await _api.getRandomPasscode(
          lockId: lockId,
          passcodeType: pType,
          startDate: pStart,
          endDate: pEnd,
          passcodeName: '${guestNameCtrl.text.trim().isEmpty ? _t(context, tr: 'Misafir', en: 'Guest') : guestNameCtrl.text.trim()} - ${unit['name']}',
        );
        pinCode = result['keyboardPwd']?.toString();
        final pwdId = result['keyboardPwdId'] ?? result['keyboard_pwd_id'];
        keyboardPwdId = pwdId is int ? pwdId : (pwdId != null ? int.tryParse(pwdId.toString()) : null);
        if (pinCode == null) throw Exception('Şifre üretilemedi');
      } else {
        await _api.getAccessToken();
        token = _api.accessToken;
        if (token == null) throw Exception('No access token');
        final email = guestContactCtrl.text.trim();
        if (email.isEmpty || !email.contains('@')) {
          throw Exception(_t(context, tr: 'Geçerli bir e-posta gerekli', en: 'Valid email required'));
        }
        // Paylaşılan yardımcı: fihbg_ (Yavuz Lock) + ham email (TTLock-native) +
        // sanitized formatlarını öncelik sırasıyla üretir. ÖNCE hepsini
        // createUser:2 (oluşturma yok) ile dene → kayıtlı hesabı bul. Hiçbiri
        // yoksa ilk format (fihbg_) ile oluştur.
        final usernamesToTry = buildReceiverUsernames(email);
        final keyName =
            '${guestNameCtrl.text.trim().isEmpty ? _t(context, tr: 'Misafir', en: 'Guest') : guestNameCtrl.text.trim()} - ${unit['name']}';

        Future<Map<String, dynamic>?> trySend(String u, int cu) async {
          try {
            final r = await _api.sendEKey(
              accessToken: token!,
              lockId: lockId,
              receiverUsername: u,
              keyName: keyName,
              startDate: startTime,
              endDate: endTime,
              createUser: cu,
              remoteEnable: 1, // link ile uzaktan açma için
              cyclicConfig: cyclicConfigData,
            );
            debugPrint('✅ eKey gönderildi: "$u" (createUser:$cu)');
            return r;
          } catch (e) {
            debugPrint('⚠️ eKey "$u" (createUser:$cu) başarısız: $e');
            return null;
          }
        }

        Map<String, dynamic>? result;
        // Faz 1: var olan kayıtlı hesabı bul (createUser:2, oluşturma yok)
        for (final u in usernamesToTry) {
          result = await trySend(u, 2);
          if (result != null) break;
        }
        // Faz 2: hiç kayıtlı değilse ilk format (fihbg_) ile oluştur
        if (result == null && usernamesToTry.isNotEmpty) {
          result = await trySend(usernamesToTry.first, 1);
        }

        if (result == null) {
          throw Exception(_t(context, tr: 'eKey gönderilemedi', en: 'Failed to send eKey'));
        }
        keyId = result['keyId']?.toString() ?? result['key_id']?.toString();
      }

      await _db.collection('users').doc(_uid).collection('bookings').add({
        'unitId': unit['id'],
        'unitName': unit['name'],
        'guestName': guestNameCtrl.text.trim().isEmpty
            ? _t(context, tr: 'Misafir', en: 'Guest')
            : guestNameCtrl.text.trim(),
        'guestContact': guestContactCtrl.text.trim(),
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'bookingType': bookingType,
        'accessType': accessType,
        'pinCode': pinCode,
        'keyboardPwdId': keyboardPwdId,
        'keyId': keyId,
        'cyclicLabel': cyclicLabelStr,
        'cyclicConfig': cyclicConfigData,
        'status': 'active',
        'createdAt': Timestamp.now(),
      });

      await _loadActiveBookings();

      // eKey için web unlock linki al (uygulama gerektirmez)
      String? unlockLink;
      if (accessType == 'ekey' && keyId != null) {
        // Link ilk denemede genelde boş döner; 3 kez dene
        for (int i = 0; i < 3; i++) {
          try {
            if (i > 0) await Future.delayed(const Duration(milliseconds: 1500));
            final linkResult = await _api.getUnlockLink(
              accessToken: token ?? _api.accessToken ?? '',
              keyId: keyId,
            );
            final link = linkResult['link']?.toString();
            if (link != null && link.isNotEmpty) {
              unlockLink = link;
              break;
            }
          } catch (e) {
            debugPrint('⚠️ Unlock link denemesi ${i + 1} başarısız: $e');
          }
        }
      }

      // Misafire bildirim emaili gönder (sonucu yakala)
      // PIN → ayrı e-posta alanı (yoksa contact alanına bak); eKey → alıcı e-posta
      bool emailSent = false;
      final contactEmail = accessType == 'pin'
          ? (guestEmailCtrl.text.contains('@')
              ? guestEmailCtrl.text.trim()
              : guestContactCtrl.text.trim())
          : guestContactCtrl.text.trim();
      if (contactEmail.contains('@')) {
        try {
          emailSent = await EmailService().sendBookingConfirmation(
            recipientEmail: contactEmail,
            guestName: guestNameCtrl.text.trim().isEmpty
                ? _t(context, tr: 'Misafir', en: 'Guest')
                : guestNameCtrl.text.trim(),
            unitName: unit['name'] as String,
            startFormatted: _fmtDt(startTime),
            endFormatted: _fmtDt(endTime),
            pinCode: accessType == 'pin' ? pinCode : null,
            unlockLink: unlockLink,
          );
        } catch (e) {
          debugPrint('⚠️ Booking emaili gönderilemedi: $e');
        }
        if (!emailSent) {
          _snack(_t(context,
              tr: 'Uyarı: Misafire e-posta gönderilemedi',
              en: 'Warning: Could not email the guest'),
              error: true);
        }
      }

      if (!mounted) return;

      if (accessType == 'pin' && pinCode != null) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(_t(ctx, tr: 'Rezervasyon Oluşturuldu', en: 'Booking Created'),
                style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_t(ctx, tr: 'Kapı Şifresi:', en: 'Door PIN:'),
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                SelectableText(pinCode ?? '',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 10)),
                const SizedBox(height: 8),
                Text(
                    cyclicLabelStr ?? '${_fmtDt(startTime)} → ${_fmtDt(endTime)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_t(ctx, tr: 'Tamam', en: 'OK'),
                      style: const TextStyle(color: AppColors.primary))),
            ],
          ),
        );
      } else {
        final link = unlockLink;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(_t(ctx, tr: 'Dijital Anahtar Gönderildi', en: 'Digital Key Sent'),
                style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (link != null) ...[
                  Text(_t(ctx,
                      tr: 'Web kilit açma bağlantısı misafirin e-postasına gönderildi. Uygulama yüklemesine gerek yok — belirlenen süre içinde bu bağlantıdan kilidi açabilir.',
                      en: 'A web unlock link has been sent to the guest\'s email. No app needed — they can unlock within the set period.'),
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  Text(_t(ctx, tr: 'Bağlantı:', en: 'Link:'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  SelectableText(link,
                      style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      _snack(_t(context, tr: 'Bağlantı kopyalandı', en: 'Link copied'));
                    },
                    icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                    label: Text(_t(ctx, tr: 'Kopyala', en: 'Copy'),
                        style: const TextStyle(color: AppColors.primary)),
                  ),
                ] else ...[
                  Text(_t(ctx,
                      tr: 'Web bağlantısı oluşturulamadı (kilit sahibi değilsiniz veya ağ geçidi yok). Misafir uygulamayla erişebilir:',
                      en: 'Web link could not be created (not lock admin or no gateway). Guest can access via the app:'),
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 12),
                  _stepRow('1', _t(ctx, tr: 'Yavuz Lock uygulamasını indirsin', en: 'Download the Yavuz Lock app')),
                  const SizedBox(height: 6),
                  _stepRow('2', _t(ctx, tr: 'Gönderdiğin e-posta adresiyle kayıt olsun', en: 'Register with the email you entered')),
                  const SizedBox(height: 6),
                  _stepRow('3', _t(ctx, tr: 'Anahtarları bölümünden erişsin', en: 'Access via the Keys section')),
                ],
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_t(ctx, tr: 'Tamam', en: 'OK'),
                      style: const TextStyle(color: AppColors.primary))),
            ],
          ),
        );
      }
    } catch (e) {
      _snack(_t(context, tr: 'Hata: $e', en: 'Error: $e'), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showActiveBooking(Map<String, dynamic> unit) async {
    final unitId = unit['id'] as String;
    final bookings = _activeBookings[unitId] ?? [];
    if (bookings.isEmpty) {
      await _showNewBooking(unit);
      return;
    }
    // Başlangıç tarihine göre sırala
    bookings.sort((a, b) {
      final aT = (a['startTime'] as Timestamp?)?.toDate() ?? DateTime(2100);
      final bT = (b['startTime'] as Timestamp?)?.toDate() ?? DateTime(2100);
      return aT.compareTo(bT);
    });

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${unit['name']} — ${bookings.length} ${_t(ctx, tr: 'rezervasyon', en: 'bookings')}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showNewBooking(unit);
                      },
                      icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
                      label: Text(_t(ctx, tr: 'Yeni', en: 'New'),
                          style: const TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _bookingCard(ctx, unit, bookings[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookingCard(BuildContext ctx, Map<String, dynamic> unit, Map<String, dynamic> booking) {
    final startTime = (booking['startTime'] as Timestamp?)?.toDate();
    final endTime = (booking['endTime'] as Timestamp?)?.toDate();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(Icons.person, booking['guestName'] ?? ''),
          if ((booking['guestContact'] as String?)?.isNotEmpty == true)
            _detailRow(Icons.contact_mail, booking['guestContact']),
          if (booking['cyclicLabel'] != null)
            _detailRow(Icons.repeat, booking['cyclicLabel'])
          else ...[
            if (startTime != null) _detailRow(Icons.login, _fmtDt(startTime)),
            if (endTime != null) _detailRow(Icons.logout, _fmtDt(endTime)),
          ],
          if (booking['accessType'] == 'pin' && booking['pinCode'] != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(_t(ctx, tr: 'Kapı Şifresi', en: 'Door PIN'),
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  SelectableText(booking['pinCode'],
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4)),
                ],
              ),
            ),
          ],
          if (booking['accessType'] == 'ekey')
            _detailRow(Icons.smartphone, _t(ctx, tr: 'Dijital Anahtar', en: 'Digital Key')),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _checkout(unit, booking);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              label: Text(_t(ctx, tr: 'Kaldır', en: 'Remove'),
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(String num, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Text(num, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      );

  Widget _detailRow(IconData icon, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(value, style: const TextStyle(color: Colors.white70))),
          ],
        ),
      );

  Future<void> _checkout(Map<String, dynamic> unit, Map<String, dynamic> booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(_t(ctx, tr: 'Çıkış Onayı', en: 'Confirm Checkout'),
            style: const TextStyle(color: Colors.white)),
        content: Text(
            _t(ctx,
                tr: 'Rezervasyon iptal edilsin mi? Erişim kaldırılacak.',
                en: 'Cancel this booking? Access will be removed.'),
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t(ctx, tr: 'İptal', en: 'Cancel'),
                  style: const TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t(ctx, tr: 'Evet', en: 'Yes'),
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _removeAccess(unit, booking);
      await _loadActiveBookings();
      _snack(_t(context, tr: 'Çıkış yapıldı', en: 'Checked out'));
    } catch (e) {
      _snack(_t(context, tr: 'Hata: $e', en: 'Error: $e'), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Bir rezervasyonun kilit erişimini (PIN/eKey) kaldırır ve 'completed' yapar.
  /// Onay göstermez — checkout ve otomatik değiştirme bunu kullanır.
  Future<void> _removeAccess(Map<String, dynamic> unit, Map<String, dynamic> booking) async {
    final lockId = unit['lockId'].toString();
    try {
      if (booking['accessType'] == 'pin' && booking['keyboardPwdId'] != null) {
        final pwdId = booking['keyboardPwdId'];
        await _api.deletePasscode(
          lockId: lockId,
          keyboardPwdId: pwdId is int ? pwdId : int.parse(pwdId.toString()),
        );
      } else if (booking['accessType'] == 'ekey' && booking['keyId'] != null) {
        await _api.getAccessToken();
        final token = _api.accessToken;
        if (token != null) {
          await _api.deleteEKey(
            accessToken: token,
            keyId: booking['keyId'].toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ Eski erişim kaldırılamadı (devam ediliyor): $e');
    }
    await _db
        .collection('users')
        .doc(_uid)
        .collection('bookings')
        .doc(booking['id'])
        .update({'status': 'completed'});
  }

  IconData _typeIcon(String type) => switch (type) {
        'court' => Icons.sports_tennis,
        'room' => Icons.hotel,
        'apartment' => Icons.apartment,
        _ => Icons.category,
      };

  String _typeLabel(BuildContext ctx, String type) => switch (type) {
        'court' => _t(ctx, tr: 'Kort', en: 'Court'),
        'room' => _t(ctx, tr: 'Oda', en: 'Room'),
        'apartment' => _t(ctx, tr: 'Daire', en: 'Apartment'),
        _ => _t(ctx, tr: 'Diğer', en: 'Other'),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Bookings',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: switch (_isPremium) {
        null => const Center(child: CircularProgressIndicator()),
        false => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.book_online, size: 56, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _t(context, tr: 'Yavuz Lock Bookings', en: 'Yavuz Lock Bookings'),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t(context,
                        tr: 'Otel, apart ve tenis kortu sahiplerine özel yönetim paneli.',
                        en: 'Management panel for hotel, apartment and court owners.'),
                    style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _ContactForm(),
                ],
              ),
            ),
          ),
        true => Stack(
            children: [
              _units.isEmpty
                  ? Center(
                      child: Text(
                        _t(context,
                            tr: 'Henüz birim yok. + ile ekleyin.',
                            en: 'No units yet. Add one with +.'),
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: _units.length,
                      itemBuilder: (context, index) {
                        final unit = _units[index];
                        final unitId = unit['id'] as String;
                        final status = _getUnitStatus(unitId);
                        final isOccupied = status == 'occupied';
                        final statusColor = isOccupied ? Colors.redAccent : Colors.green;
                        final activeBooking = _getActiveBooking(unitId);

                        return GestureDetector(
                          onTap: () => _handleUnitTap(unit),
                          child: Card(
                            color: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: statusColor.withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(unit['name'] ?? '',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      GestureDetector(
                                        onTap: () => _deleteUnit(unit),
                                        child: const Icon(Icons.delete_outline,
                                            color: Colors.grey, size: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(_typeIcon(unit['type'] ?? 'other'),
                                          size: 11, color: Colors.grey),
                                      const SizedBox(width: 3),
                                      Text(_typeLabel(context, unit['type'] ?? 'other'),
                                          style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.lock_outline,
                                          size: 11,
                                          color: unit['lockName'] != null
                                              ? Colors.grey
                                              : Colors.orange),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          unit['lockName'] ??
                                              _t(context,
                                                  tr: 'Kilit atanmadı', en: 'No lock'),
                                          style: TextStyle(
                                              color: unit['lockName'] != null
                                                  ? Colors.grey
                                                  : Colors.orange,
                                              fontSize: 10),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isOccupied && activeBooking != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline,
                                            size: 11, color: Colors.white70),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(activeBooking['guestName'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white70, fontSize: 10),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        if ((_activeBookings[unitId]?.length ?? 0) > 1)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '+${_activeBookings[unitId]!.length - 1}',
                                              style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (activeBooking['endTime'] != null) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.schedule,
                                              size: 11, color: Colors.grey),
                                          const SizedBox(width: 3),
                                          Text(
                                            _fmtDt((activeBooking['endTime'] as Timestamp)
                                                .toDate()),
                                            style: const TextStyle(
                                                color: Colors.grey, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isOccupied
                                              ? _t(context, tr: 'Dolu', en: 'Occupied')
                                              : _t(context, tr: 'Boş', en: 'Vacant'),
                                          style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        unit['lockId'] == null
                                            ? _t(context,
                                                tr: 'Kilit Ata', en: 'Assign Lock')
                                            : isOccupied
                                                ? _t(context, tr: 'Detay', en: 'Details')
                                                : _t(context,
                                                    tr: 'Rezervasyon', en: 'Book'),
                                        style: const TextStyle(
                                            color: AppColors.primary, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              if (_isLoading)
                const ColoredBox(
                  color: Colors.black54,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
      },
      floatingActionButton: _isPremium == true
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: _addUnit,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
}

class _ContactForm extends StatefulWidget {
  const _ContactForm();
  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    var email = prefs.getString('saved_email') ?? '';
    if (email.isEmpty) email = await AuthRepository().getEmail() ?? '';
    if (email.isEmpty) email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (mounted) setState(() => _emailCtrl.text = email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  String _t(BuildContext context, {required String tr, required String en}) {
    return Localizations.localeOf(context).languageCode == 'tr' ? tr : en;
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t(context, tr: 'Ad ve telefon zorunludur', en: 'Name and phone are required')),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _sending = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final name = _nameCtrl.text.trim();
    final business = _businessCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final message = _msgCtrl.text.trim().isEmpty
        ? _t(context, tr: 'Bookings erişimi talep ediyorum.', en: 'I am requesting Bookings access.')
        : _msgCtrl.text.trim();

    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('contactRequests').doc(uid).set({
          'name': name,
          'business': business,
          'email': email,
          'phone': phone,
          'message': message,
          'createdAt': Timestamp.now(),
          'status': 'pending',
        });
      } catch (e) {
        debugPrint('⚠️ Firestore contact save failed: $e');
      }
    }

    final ok = await EmailService().sendContactForm(
      name: name,
      business: business,
      email: email,
      phone: phone,
      message: message,
    );
    if (!mounted) return;
    setState(() { _sending = false; _sent = ok || uid != null; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? _t(context, tr: 'Talebiniz iletildi, en kısa sürede dönüş yapılacak.', en: 'Your request has been sent. We will get back to you shortly.')
          : _t(context, tr: 'Gönderilemedi, lütfen tekrar deneyin.', en: 'Failed to send, please try again.')),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Column(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 56),
          const SizedBox(height: 16),
          Text(
            _t(context, tr: 'Talebiniz alındı!', en: 'Request received!'),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _t(context, tr: 'En kısa sürede sizinle iletişime geçeceğiz.', en: 'We will contact you as soon as possible.'),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(context, tr: 'Erişim Talebi', en: 'Access Request'),
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _field(_nameCtrl, _t(context, tr: 'Ad Soyad *', en: 'Full Name *'), Icons.person_outline),
        const SizedBox(height: 10),
        _field(_businessCtrl, _t(context, tr: 'İşletme Adı', en: 'Business Name'), Icons.business_outlined),
        const SizedBox(height: 10),
        _field(_emailCtrl, _t(context, tr: 'E-posta', en: 'Email'), Icons.email_outlined, type: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _field(_phoneCtrl, _t(context, tr: 'Telefon *', en: 'Phone *'), Icons.phone_outlined, type: TextInputType.phone),
        const SizedBox(height: 10),
        _field(_msgCtrl, _t(context, tr: 'Mesaj (opsiyonel)', en: 'Message (optional)'), Icons.message_outlined, maxLines: 3),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _sending ? null : _submit,
            child: _sending
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text(_t(context, tr: 'Talep Gönder', en: 'Send Request'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
