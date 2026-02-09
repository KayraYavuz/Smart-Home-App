import 'package:yavuz_lock/ui/pages/gateway_locks_page.dart';
import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_state.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class GatewayDetailPage extends StatefulWidget {
  final Map<String, dynamic> gateway;

  const GatewayDetailPage({super.key, required this.gateway});

  @override
  State<GatewayDetailPage> createState() => _GatewayDetailPageState();
}

class _GatewayDetailPageState extends State<GatewayDetailPage> {
  Map<String, dynamic>? _gatewayDetails;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchGatewayDetails();
  }

  Future<void> _fetchGatewayDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      try {
        final apiService = ApiService(context.read<AuthRepository>());
        final details = await apiService.getGatewayDetail(gatewayId: widget.gateway['gatewayId'].toString());
        if (!mounted) return;
        setState(() {
          _gatewayDetails = details;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = "User not authenticated";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(widget.gateway['gatewayName'] ?? l10n.gatewayDetailTitle),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      );
    }
    
    if (_gatewayDetails == null) {
      return Center(
        child: Text(l10n.detailNotFound, style: const TextStyle(color: Colors.white)),
      );
    }

    return ListView(
      children: [
        ListTile(
          title: Text(l10n.gatewayName, style: const TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['gatewayName'] ?? 'N/A', style: const TextStyle(color: Colors.grey)),
        ),
        ListTile(
          title: Text(l10n.gatewayMac, style: const TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['gatewayMac'] ?? 'N/A', style: const TextStyle(color: Colors.grey)),
        ),
        ListTile(
          title: Text(l10n.networkName, style: const TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['networkName'] ?? 'N/A', style: const TextStyle(color: Colors.grey)),
        ),
        ListTile(
          title: Text(l10n.isOnline, style: const TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['isOnline'] == 1 ? l10n.yes : l10n.no, style: const TextStyle(color: Colors.grey)),
        ),
        ListTile(
          title: Text(l10n.lockCountLabel, style: const TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['lockNum']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.grey)),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _renameGateway,
                child: Text(l10n.renameGateway),
              ),
              ElevatedButton(
                onPressed: _deleteGateway,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(l10n.deleteGatewayAction),
              ),
              ElevatedButton(
                onPressed: _transferGateway,
                child: Text(l10n.transferGatewayAction),
              ),
              ElevatedButton(
                onPressed: _checkUpgrade,
                child: Text(l10n.checkUpgrade),
              ),
              ElevatedButton(
                onPressed: _setUpgradeMode,
                child: Text(l10n.setUpgradeMode),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GatewayLocksPage(
                        gatewayId: widget.gateway['gatewayId'].toString(),
                        gatewayName: _gatewayDetails!['gatewayName'] ?? widget.gateway['gatewayName'] ?? 'Gateway',
                      ),
                    ),
                  );
                },
                child: Text(l10n.viewLocks),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _renameGateway() {
    final TextEditingController nameController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.renameGateway),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: l10n.enterNewGatewayName),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final authState = this.context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  try {
                    final apiService = ApiService(this.context.read<AuthRepository>());
                    await apiService.renameGateway(
                      gatewayId: widget.gateway['gatewayId'].toString(),
                      gatewayName: nameController.text,
                    );
                    if (!mounted) return;
                    navigator.pop();
                    _fetchGatewayDetails();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(l10n.gatewayRenamedSuccess)),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(l10n.errorRenamingGateway(e.toString()))),
                    );
                  }
                }
              },
              child: Text(l10n.rename),
            ),
          ],
        );
      },
    );
  }

  void _deleteGateway() {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deleteGatewayAction),
          content: Text(l10n.deleteGatewayConfirmation),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final authState = this.context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  try {
                    final apiService = ApiService(this.context.read<AuthRepository>());
                    await apiService.deleteGateway(
                      gatewayId: widget.gateway['gatewayId'].toString(),
                    );
                    if (!mounted) return;
                    navigator.pop();
                    navigator.pop(); // Go back to the gateways list
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(l10n.gatewayDeletedSuccess)),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(l10n.errorDeletingGateway(e.toString()))),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }

  void _transferGateway() {
    final TextEditingController usernameController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.transferGatewayAction),
          content: TextField(
            controller: usernameController,
            decoration: InputDecoration(hintText: l10n.enterReceiverUsername),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                final authState = this.context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  try {
                    final apiService = ApiService(this.context.read<AuthRepository>());
                    await apiService.transferGateway(
                      receiverUsername: usernameController.text,
                      gatewayIdList: [widget.gateway['gatewayId'] as int],
                    );
                    if (!mounted) return;
                    navigator.pop();
                    navigator.pop(); // Go back to the gateways list
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(l10n.gatewayTransferredSuccess)),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(l10n.errorTransferringGateway(e.toString()))),
                    );
                  }
                }
              },
              child: Text(l10n.transferAction),
            ),
          ],
        );
      },
    );
  }

  void _checkUpgrade() async {
    final authState = context.read<AuthBloc>().state;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (authState is Authenticated) {
      try {
        final apiService = ApiService(context.read<AuthRepository>());
        final result = await apiService.gatewayUpgradeCheck(
          gatewayId: widget.gateway['gatewayId'].toString(),
        );
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(l10n.upgradeCheckTitle),
              content: Text(
                  '${l10n.needUpgrade}: ${result['needUpgrade'] == 1 ? l10n.yes : l10n.no}\n'
                  '${l10n.version}: ${result['version'] ?? 'N/A'}'
              ),
              actions: [
                TextButton(
                  onPressed: () => navigator.pop(),
                  child: Text(l10n.ok),
                ),
              ],
            );
          },
        );
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.errorCheckingUpgrade(e.toString()))),
        );
      }
    }
  }

  void _setUpgradeMode() async {
    final authState = context.read<AuthBloc>().state;
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (authState is Authenticated) {
      try {
        final apiService = ApiService(context.read<AuthRepository>());
        await apiService.setGatewayUpgradeMode(
          gatewayId: widget.gateway['gatewayId'].toString(),
        );
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.gatewaySetToUpgradeMode)),
        );
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.errorSettingUpgradeMode(e.toString()))),
        );
      }
    }
  }
}
