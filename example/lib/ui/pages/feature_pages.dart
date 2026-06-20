import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:ttlock_flutter/ttremotekey.dart';
import 'package:ttlock_flutter/ttdoorSensor.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import '../../api_service.dart';
import '../../repositories/auth_repository.dart';

// --- Base Page Structure ---
class FeatureBasePage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const FeatureBasePage(
      {super.key, required this.title, required this.body, this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: actions,
      ),
      body: body,
    );
  }
}

// --- Remote List Page ---
class RemoteListPage extends StatefulWidget {
  final int lockId;
  final String lockData;
  const RemoteListPage({super.key, required this.lockId, required this.lockData});

  @override
  State<RemoteListPage> createState() => _RemoteListPageState();
}

class _RemoteListPageState extends State<RemoteListPage> {
  List<dynamic> _remotes = [];
  bool _isLoading = true;

  ApiService get _api => ApiService(context.read<AuthRepository>());

  @override
  void initState() {
    super.initState();
    _loadRemotes();
  }

  Future<void> _loadRemotes() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (mounted) setState(() => _isLoading = true);
    try {
      final result = await _api.getRemoteList(lockId: widget.lockId);
      if (!mounted) return;
      setState(() {
        _remotes = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        scaffoldMessenger
            .showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
      }
    }
  }

  Future<void> _rename(Map remote) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: remote['remoteName'] ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.rename),
        content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.newName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.save)),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.updateRemote(remoteId: remote['remoteId'], name: newName);
      await _loadRemotes();
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _changePeriod(Map remote) async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: start,
      lastDate: DateTime(now.year + 10),
    );
    if (end == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api.updateRemote(
        remoteId: remote['remoteId'],
        startDate: start.millisecondsSinceEpoch,
        endDate: end.millisecondsSinceEpoch,
      );
      await _loadRemotes();
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _delete(Map remote) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api.deleteRemote(remoteId: remote['remoteId']);
      await _loadRemotes();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.deleteErrorWithMsg(e.toString()))));
    }
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearAll),
        content: Text(l10n.confirmClearAll),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.clearAll,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.clearRemotes(lockId: widget.lockId);
      await _loadRemotes();
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _addRemote() async {
    final l10n = AppLocalizations.of(context)!;
    final discovered = <TTRemoteAccessoryScanModel>[];
    TTRemoteKey.startScan((model) {
      if (mounted &&
          !discovered.any((d) => d.mac == model.mac)) {
        setState(() => discovered.add(model));
      }
    });

    final selected = await showModalBottomSheet<TTRemoteAccessoryScanModel>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSt) {
          TTRemoteKey.startScan((model) {
            if (!discovered.any((d) => d.mac == model.mac)) {
              setSt(() => discovered.add(model));
            }
          });
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.selectAccessory,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              if (discovered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(l10n.scanningAccessories,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: discovered.length,
                    itemBuilder: (_, i) {
                      final d = discovered[i];
                      return ListTile(
                        leading: const Icon(Icons.settings_remote,
                            color: Color(0xFF1E90FF)),
                        title: Text(
                            d.name.isNotEmpty ? d.name : d.mac,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(l10n.rssiLabel(d.rssi),
                            style: const TextStyle(color: Colors.grey)),
                        onTap: () => Navigator.of(sheetContext).pop(d),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );

    TTRemoteKey.stopScan();
    if (selected == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final initCompleter = Completer<TTLockSystemModel>();
      TTRemoteKey.init(
        selected.mac,
        widget.lockData,
        (model) => initCompleter.complete(model),
        (err, msg) => initCompleter.completeError(msg),
      );
      final systemModel =
          await initCompleter.future.timeout(const Duration(seconds: 15));

      final addCompleter = Completer<void>();
      final now = DateTime.now().millisecondsSinceEpoch;
      final fiveYearsLater =
          DateTime.now().add(const Duration(days: 365 * 5)).millisecondsSinceEpoch;
      TTLock.addRemoteKey(
        selected.mac,
        null,
        now,
        fiveYearsLater,
        widget.lockData,
        () => addCompleter.complete(),
        (errCode, msg) => addCompleter.completeError(msg),
      );
      await addCompleter.future.timeout(const Duration(seconds: 15));

      await _api.addRemote(
        lockId: widget.lockId,
        number: selected.mac,
        mac: selected.mac,
        electricQuantity: systemModel.electricQuantity ?? 0,
        firmwareInfo: {
          'modelNum': systemModel.modelNum ?? '',
          'hardwareRevision': systemModel.hardwareRevision ?? '',
          'firmwareRevision': systemModel.firmwareRevision ?? '',
        },
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _loadRemotes();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.accessoryAdded)));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeatureBasePage(
      title: l10n.remoteControls,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _remotes.isEmpty
              ? Center(
                  child: Text(l10n.noData,
                      style: const TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _loadRemotes,
                  child: ListView.builder(
                    itemCount: _remotes.length,
                    itemBuilder: (context, index) {
                      final remote = _remotes[index] as Map;
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.settings_remote,
                              color: Color(0xFF1E90FF)),
                          title: Text(
                              remote['remoteName'] ?? l10n.remoteControl,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text('ID: ${remote['remoteId']}',
                              style: const TextStyle(color: Colors.grey)),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white70),
                            onSelected: (value) {
                              switch (value) {
                                case 'rename':
                                  _rename(remote);
                                  break;
                                case 'period':
                                  _changePeriod(remote);
                                  break;
                                case 'delete':
                                  _delete(remote);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'rename', child: Text(l10n.rename)),
                              PopupMenuItem(
                                  value: 'period',
                                  child: Text(l10n.changePeriod)),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l10n.delete,
                                      style: const TextStyle(
                                          color: Colors.redAccent))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: l10n.clearAll,
          onPressed: _remotes.isEmpty ? null : _clearAll,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _addRemote,
        ),
      ],
    );
  }
}

// --- Wireless Keypad Page ---
class WirelessKeypadPage extends StatefulWidget {
  final int lockId;
  const WirelessKeypadPage({super.key, required this.lockId});

  @override
  State<WirelessKeypadPage> createState() => _WirelessKeypadPageState();
}

class _WirelessKeypadPageState extends State<WirelessKeypadPage> {
  List<dynamic> _keypads = [];
  bool _isLoading = true;

  ApiService get _api => ApiService(context.read<AuthRepository>());

  @override
  void initState() {
    super.initState();
    _loadKeypads();
  }

  Future<void> _loadKeypads() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (mounted) setState(() => _isLoading = true);
    try {
      final result = await _api.getWirelessKeypadList(lockId: widget.lockId);
      if (!mounted) return;
      setState(() {
        _keypads = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        scaffoldMessenger
            .showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
      }
    }
  }

  Future<void> _rename(Map keypad) async {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        TextEditingController(text: keypad['wirelessKeypadName'] ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.rename),
        content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.newName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.save)),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.renameWirelessKeypad(
        wirelessKeypadId: keypad['wirelessKeypadId'],
        wirelessKeypadName: newName,
      );
      await _loadKeypads();
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _delete(Map keypad) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api.deleteWirelessKeypad(
          wirelessKeypadId: keypad['wirelessKeypadId']);
      await _loadKeypads();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.deleteErrorWithMsg(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeatureBasePage(
      title: l10n.wirelessKeypads,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _keypads.isEmpty
              ? Center(
                  child: Text(l10n.noData,
                      style: const TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _loadKeypads,
                  child: ListView.builder(
                    itemCount: _keypads.length,
                    itemBuilder: (context, index) {
                      final keypad = _keypads[index] as Map;
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.dialpad,
                              color: Color(0xFF1E90FF)),
                          title: Text(
                              keypad['wirelessKeypadName'] ?? l10n.wirelessKeypad,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text('MAC: ${keypad['wirelessKeypadMac']}',
                              style: const TextStyle(color: Colors.grey)),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white70),
                            onSelected: (value) {
                              switch (value) {
                                case 'rename':
                                  _rename(keypad);
                                  break;
                                case 'delete':
                                  _delete(keypad);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'rename', child: Text(l10n.rename)),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l10n.delete,
                                      style: const TextStyle(
                                          color: Colors.redAccent))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.bluetoothAddInstructions))),
        ),
      ],
    );
  }
}

// --- Door Sensor Page ---
class DoorSensorPage extends StatefulWidget {
  final int lockId;
  final String lockData;
  const DoorSensorPage({super.key, required this.lockId, required this.lockData});

  @override
  State<DoorSensorPage> createState() => _DoorSensorPageState();
}

class _DoorSensorPageState extends State<DoorSensorPage> {
  Map<String, dynamic>? _sensor;
  bool _isLoading = true;

  ApiService get _api => ApiService(context.read<AuthRepository>());

  @override
  void initState() {
    super.initState();
    _loadSensor();
  }

  Future<void> _loadSensor() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final result = await _api.queryDoorSensor(lockId: widget.lockId);
      if (!mounted) return;
      setState(() {
        _sensor = result;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rename(Map sensor) async {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        TextEditingController(text: sensor['doorSensorName'] ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.rename),
        content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.newName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.save)),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.renameDoorSensor(
          doorSensorId: sensor['doorSensorId'], name: newName);
      await _loadSensor();
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _delete(Map sensor) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api.deleteDoorSensor(doorSensorId: sensor['doorSensorId']);
      if (!mounted) return;
      setState(() => _sensor = null);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.deleteErrorWithMsg(e.toString()))));
    }
  }

  Future<void> _addDoorSensor() async {
    final l10n = AppLocalizations.of(context)!;
    final discovered = <TTRemoteAccessoryScanModel>[];
    TTDoorSensor.startScan((model) {
      if (mounted && !discovered.any((d) => d.mac == model.mac)) {
        setState(() => discovered.add(model));
      }
    });

    final selected = await showModalBottomSheet<TTRemoteAccessoryScanModel>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSt) {
          TTDoorSensor.startScan((model) {
            if (!discovered.any((d) => d.mac == model.mac)) {
              setSt(() => discovered.add(model));
            }
          });
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.selectAccessory,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
              if (discovered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(l10n.scanningAccessories,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: discovered.length,
                    itemBuilder: (_, i) {
                      final d = discovered[i];
                      return ListTile(
                        leading:
                            const Icon(Icons.sensors, color: Color(0xFF1E90FF)),
                        title: Text(
                            d.name.isNotEmpty ? d.name : d.mac,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(l10n.rssiLabel(d.rssi),
                            style: const TextStyle(color: Colors.grey)),
                        onTap: () => Navigator.of(sheetContext).pop(d),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );

    TTDoorSensor.stopScan();
    if (selected == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final initCompleter = Completer<TTLockSystemModel>();
      TTDoorSensor.init(
        selected.mac,
        widget.lockData,
        (model) => initCompleter.complete(model),
        (err, msg) => initCompleter.completeError(msg),
      );
      final systemModel =
          await initCompleter.future.timeout(const Duration(seconds: 15));

      final addCompleter = Completer<void>();
      TTLock.addDoorSensor(
        selected.mac,
        widget.lockData,
        () => addCompleter.complete(),
        (errCode, msg) => addCompleter.completeError(msg),
      );
      await addCompleter.future.timeout(const Duration(seconds: 15));

      await _api.addDoorSensor(
        lockId: widget.lockId,
        number: selected.mac,
        mac: selected.mac,
        electricQuantity: systemModel.electricQuantity ?? 0,
        firmwareInfo: {
          'modelNum': systemModel.modelNum ?? '',
          'hardwareRevision': systemModel.hardwareRevision ?? '',
          'firmwareRevision': systemModel.firmwareRevision ?? '',
        },
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _loadSensor();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.accessoryAdded)));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeatureBasePage(
      title: l10n.doorSensor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sensor == null
              ? Center(
                  child: Text(l10n.sensorNotFound,
                      style: const TextStyle(color: Colors.grey)))
              : ListView(
                  children: [
                    Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.sensors,
                            color: Color(0xFF1E90FF)),
                        title: Text(
                            _sensor!['doorSensorName'] ?? l10n.doorSensor,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                            'MAC: ${_sensor!['doorSensorMac'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.grey)),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              color: Colors.white70),
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _rename(_sensor!);
                                break;
                              case 'delete':
                                _delete(_sensor!);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                                value: 'rename', child: Text(l10n.rename)),
                            PopupMenuItem(
                                value: 'delete',
                                child: Text(l10n.delete,
                                    style: const TextStyle(
                                        color: Colors.redAccent))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      actions: [
        if (_sensor == null)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addDoorSensor,
          ),
      ],
    );
  }
}

// --- QR Code Page ---
class QrCodePage extends StatefulWidget {
  final int lockId;
  const QrCodePage({super.key, required this.lockId});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  List<dynamic> _qrCodes = [];
  bool _isLoading = true;

  ApiService get _api => ApiService(context.read<AuthRepository>());

  @override
  void initState() {
    super.initState();
    _loadQrCodes();
  }

  Future<void> _loadQrCodes() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (mounted) setState(() => _isLoading = true);
    try {
      final result = await _api.getQrCodeList(lockId: widget.lockId);
      if (!mounted) return;
      setState(() {
        _qrCodes = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        scaffoldMessenger
            .showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
      }
    }
  }

  Future<void> _addQrCode() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api.addQrCode(
        lockId: widget.lockId,
        type: 1,
        name: l10n.newQrWithName("${DateTime.now().minute}"),
        startDate: DateTime.now().millisecondsSinceEpoch,
        endDate:
            DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      await _loadQrCodes();
      if (!mounted) return;
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text(l10n.qrCodeCreated)));
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
    }
  }

  Future<void> _rename(Map qr) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: qr['name'] ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.rename),
        content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.newName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.save)),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.updateQrCode(
        qrCodeId: qr['qrCodeId'],
        type: qr['type'] ?? 1,
        changeType: 0,
        name: newName,
      );
      await _loadQrCodes();
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _changePeriod(Map qr) async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: start,
      lastDate: DateTime(now.year + 10),
    );
    if (end == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api.updateQrCode(
        qrCodeId: qr['qrCodeId'],
        type: qr['type'] ?? 3,
        changeType: 0,
        startDate: start.millisecondsSinceEpoch,
        endDate: end.millisecondsSinceEpoch,
      );
      await _loadQrCodes();
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _delete(Map qr) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api.deleteQrCode(
          lockId: widget.lockId, qrCodeId: qr['qrCodeId']);
      await _loadQrCodes();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.deleteErrorWithMsg(e.toString()))));
    }
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearAll),
        content: Text(l10n.confirmClearAll),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.clearAll,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.clearQrCodes(lockId: widget.lockId);
      await _loadQrCodes();
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMsg(e.toString()))));
    }
  }

  Future<void> _showContent(Map qr) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final data = await _api.getQrCodeData(qrCodeId: qr['qrCodeId']);
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (c) => AlertDialog(
                title: Text(l10n.qrContent),
                content: Text(data['qrCodeContent'] ?? l10n.empty),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c), child: Text(l10n.ok))
                ],
              ));
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeatureBasePage(
      title: l10n.qrCodes,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _qrCodes.isEmpty
              ? Center(
                  child: Text(l10n.noData,
                      style: const TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _loadQrCodes,
                  child: ListView.builder(
                    itemCount: _qrCodes.length,
                    itemBuilder: (context, index) {
                      final qr = _qrCodes[index] as Map;
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.qr_code,
                              color: Color(0xFF1E90FF)),
                          title: Text(qr['name'] ?? l10n.qrCode,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text('ID: ${qr['qrCodeId']}',
                              style: const TextStyle(color: Colors.grey)),
                          onTap: () => _showContent(qr),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white70),
                            onSelected: (value) {
                              switch (value) {
                                case 'rename':
                                  _rename(qr);
                                  break;
                                case 'period':
                                  _changePeriod(qr);
                                  break;
                                case 'delete':
                                  _delete(qr);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'rename', child: Text(l10n.rename)),
                              PopupMenuItem(
                                  value: 'period',
                                  child: Text(l10n.changePeriod)),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l10n.delete,
                                      style: const TextStyle(
                                          color: Colors.redAccent))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: l10n.clearAll,
          onPressed: _qrCodes.isEmpty ? null : _clearAll,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _addQrCode,
        ),
      ],
    );
  }
}

// --- Wi-Fi Lock Page ---
class WifiLockPage extends StatefulWidget {
  final int lockId;
  const WifiLockPage({super.key, required this.lockId});

  @override
  State<WifiLockPage> createState() => _WifiLockPageState();
}

class _WifiLockPageState extends State<WifiLockPage> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final api = ApiService(context.read<AuthRepository>());
      final result = await api.getWifiLockDetail(lockId: widget.lockId);
      if (!mounted) return;
      setState(() {
        _detail = result;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        // Optional: still show snackbar or just show in body
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureBasePage(
      title: AppLocalizations.of(context)!.wifiLockDetails,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.orange, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.wifiLockOnlyNotice,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.wifiLockGatewayTip,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_detail != null) ...[
                        _buildInfoRow(
                            AppLocalizations.of(context)!.isOnline,
                            _detail!['isOnline'] == true
                                ? AppLocalizations.of(context)!.online
                                : AppLocalizations.of(context)!.offline),
                        _buildInfoRow(AppLocalizations.of(context)!.networkName,
                            _detail!['networkName'] ?? '-'),
                        _buildInfoRow('MAC', _detail!['wifiMac'] ?? '-'),
                        _buildInfoRow('IP', _detail!['ip'] ?? '-'),
                        _buildInfoRow(AppLocalizations.of(context)!.rssiGrade,
                            '${_detail!['rssiGrade'] ?? '0'}'),
                      ] else
                        Text(AppLocalizations.of(context)!.detailNotFound,
                            style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- Palm Vein Page ---
// Cloud-side management of palm vein credentials (list / rename / change
// period / delete / clear). New palm veins are enrolled on the device itself;
// this plugin's Bluetooth SDK does not expose palm-vein enrollment, so the
// "add" action only surfaces the on-device instructions.
class PalmVeinPage extends StatefulWidget {
  final int lockId;
  const PalmVeinPage({super.key, required this.lockId});

  @override
  State<PalmVeinPage> createState() => _PalmVeinPageState();
}

class _PalmVeinPageState extends State<PalmVeinPage> {
  List<dynamic> _palmVeins = [];
  bool _isLoading = true;

  ApiService get _api => ApiService(context.read<AuthRepository>());

  @override
  void initState() {
    super.initState();
    _loadPalmVeins();
  }

  Future<void> _loadPalmVeins() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (mounted) setState(() => _isLoading = true);
    try {
      final result = await _api.getPalmVeinList(lockId: widget.lockId);
      if (!mounted) return;
      setState(() {
        _palmVeins = result['list'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
    }
  }

  int _idOf(Map item) => (item['palmVeinId'] ?? item['id']) as int;
  String _nameOf(Map item, String fallback) =>
      (item['palmVeinName'] ?? item['name'] ?? fallback).toString();

  Future<void> _delete(int palmVeinId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api.deletePalmVein(palmVeinId: palmVeinId);
      await _loadPalmVeins();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.deleteErrorWithMsg(e.toString()))));
    }
  }

  Future<void> _rename(int palmVeinId, String currentName) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.rename),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.newName),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.save)),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _api.renamePalmVein(palmVeinId: palmVeinId, name: newName);
      await _loadPalmVeins();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
    }
  }

  Future<void> _changePeriod(int palmVeinId) async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year + 1, now.month, now.day),
      firstDate: start,
      lastDate: DateTime(now.year + 10),
    );
    if (end == null || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api.changePalmVeinPeriod(
        palmVeinId: palmVeinId,
        startDate: start.millisecondsSinceEpoch,
        endDate: end.millisecondsSinceEpoch,
      );
      await _loadPalmVeins();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
    }
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearAll),
        content: Text(l10n.confirmClearAll),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.clearAll,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _api.clearPalmVein(lockId: widget.lockId);
      await _loadPalmVeins();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('${l10n.errorLabel}: $e')));
    }
  }

  String _periodText(Map item, AppLocalizations l10n) {
    final startMs = item['startDate'];
    final endMs = item['endDate'];
    if (startMs is! int || endMs is! int || startMs == 0 || endMs == 0) {
      return l10n.validityPeriod;
    }
    String fmt(int ms) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    return '${l10n.startDatePrefix}${fmt(startMs)}  ${l10n.endDatePrefix}${fmt(endMs)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeatureBasePage(
      title: l10n.palmVeins,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: l10n.clearAll,
          onPressed: _palmVeins.isEmpty ? null : _clearAll,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.bluetoothAddInstructions))),
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _palmVeins.isEmpty
              ? Center(
                  child: Text(l10n.noPalmVeinsFound,
                      style: const TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _loadPalmVeins,
                  child: ListView.builder(
                    itemCount: _palmVeins.length,
                    itemBuilder: (context, index) {
                      final item = _palmVeins[index] as Map;
                      final id = _idOf(item);
                      final name = _nameOf(item, l10n.palmVein);
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.back_hand,
                              color: Color(0xFF1E90FF)),
                          title: Text(name,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(_periodText(item, l10n),
                              style: const TextStyle(color: Colors.grey)),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white70),
                            onSelected: (value) {
                              switch (value) {
                                case 'rename':
                                  _rename(id, name);
                                  break;
                                case 'period':
                                  _changePeriod(id);
                                  break;
                                case 'delete':
                                  _delete(id);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                  value: 'rename', child: Text(l10n.rename)),
                              PopupMenuItem(
                                  value: 'period',
                                  child: Text(l10n.changePeriod)),
                              PopupMenuItem(
                                  value: 'delete', child: Text(l10n.delete)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
