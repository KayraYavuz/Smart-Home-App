import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_state.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';

class GatewayLocksPage extends StatefulWidget {
  final String gatewayId;
  final String gatewayName;

  const GatewayLocksPage(
      {super.key, required this.gatewayId, required this.gatewayName});

  @override
  State<GatewayLocksPage> createState() => _GatewayLocksPageState();
}

class _GatewayLocksPageState extends State<GatewayLocksPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _locks = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchGatewayLocks();
  }

  Future<void> _fetchGatewayLocks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      try {
        final apiService = ApiService(context.read<AuthRepository>());
        final locks =
            await apiService.getGatewayLocks(gatewayId: widget.gatewayId);
        if (!mounted) return;
        setState(() {
          _locks = locks;
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
        title: Text(l10n.locksForGateway(widget.gatewayName)),
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

    if (_locks.isEmpty) {
      return Center(
        child: Text(l10n.noLocksFound,
            style: const TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: _locks.length,
      itemBuilder: (context, index) {
        final lock = _locks[index];
        return ListTile(
          leading: const Icon(Icons.lock, color: Color(0xFF1E90FF)),
          title: Text(lock['lockAlias'] ?? 'Unknown Lock',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          subtitle: Text(lock['lockMac'] ?? '',
              style: TextStyle(color: Colors.grey[400])),
        );
      },
    );
  }
}
