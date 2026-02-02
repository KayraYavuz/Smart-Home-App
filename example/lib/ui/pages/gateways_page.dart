import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/ui/pages/gateway_detail_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_state.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class GatewaysPage extends StatefulWidget {
  const GatewaysPage({super.key});

  @override
  _GatewaysPageState createState() => _GatewaysPageState();
}

class _GatewaysPageState extends State<GatewaysPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _gateways = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchGateways();
  }

  Future<void> _fetchGateways() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      try {
        final apiService = ApiService(context.read<AuthRepository>());
        final gateways = await apiService.getGatewayList();
        setState(() {
          _gateways = gateways;
          _isLoading = false;
        });
      } catch (e) {
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
        title: Text(l10n.gateways),
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

    if (_gateways.isEmpty) {
      return Center(
        child: Text(l10n.noGatewaysFound, style: const TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: _gateways.length,
      itemBuilder: (context, index) {
        final gateway = _gateways[index];
        final isOnline = gateway['isOnline'] == 1;
        return ListTile(
          leading: Icon(Icons.router, color: isOnline ? Colors.green : Colors.grey),
          title: Text(gateway['gatewayName'] ?? l10n.unknownGateway, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          subtitle: Text(gateway['gatewayMac'] ?? '', style: TextStyle(color: Colors.grey[400])),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GatewayDetailPage(gateway: gateway)),
            );
          },
        );
      },
    );
  }
}
