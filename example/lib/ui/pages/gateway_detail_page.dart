import 'package:yavuz_lock/ui/pages/gateway_locks_page.dart';
import 'package:flutter/material.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_state.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';

class GatewayDetailPage extends StatefulWidget {
  final Map<String, dynamic> gateway;

  const GatewayDetailPage({Key? key, required this.gateway}) : super(key: key);

  @override
  _GatewayDetailPageState createState() => _GatewayDetailPageState();
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
        setState(() {
          _gatewayDetails = details;
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
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(widget.gateway['gatewayName'] ?? 'Gateway Detail'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
      );
    }
    
    if (_gatewayDetails == null) {
      return Center(
        child: Text('Gateway details not found.', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView(
      children: [
        ListTile(
          title: Text('Gateway Name', style: TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['gatewayName'] ?? 'N/A', style: TextStyle(color: Colors.grey)),
        ),
        ListTile(
          title: Text('Gateway MAC', style: TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['gatewayMac'] ?? 'N/A', style: TextStyle(color: Colors.grey)),
        ),
        ListTile(
          title: Text('Network Name', style: TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['networkName'] ?? 'N/A', style: TextStyle(color: Colors.grey)),
        ),
        ListTile(
          title: Text('Is Online', style: TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['isOnline'] == 1 ? 'Yes' : 'No', style: TextStyle(color: Colors.grey)),
        ),
        ListTile(
          title: Text('Lock Count', style: TextStyle(color: Colors.white)),
          subtitle: Text(_gatewayDetails!['lockNum']?.toString() ?? 'N/A', style: TextStyle(color: Colors.grey)),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _renameGateway,
                child: Text('Rename Gateway'),
              ),
              ElevatedButton(
                onPressed: _deleteGateway,
                child: Text('Delete Gateway'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              ElevatedButton(
                onPressed: _transferGateway,
                child: Text('Transfer Gateway'),
              ),
              ElevatedButton(
                onPressed: _checkUpgrade,
                child: Text('Check for Upgrade'),
              ),
              ElevatedButton(
                onPressed: _setUpgradeMode,
                child: Text('Set to Upgrade Mode'),
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
                child: Text('View Locks'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _renameGateway() {
    final TextEditingController _nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename Gateway'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: "Enter new gateway name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  try {
                    final apiService = ApiService(context.read<AuthRepository>());
                    await apiService.renameGateway(
                      gatewayId: widget.gateway['gatewayId'].toString(),
                      gatewayName: _nameController.text,
                    );
                    Navigator.of(context).pop();
                    _fetchGatewayDetails();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gateway renamed successfully')),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error renaming gateway: $e')),
                    );
                  }
                }
              },
              child: Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _deleteGateway() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Gateway'),
          content: Text('Are you sure you want to delete this gateway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  try {
                    final apiService = ApiService(context.read<AuthRepository>());
                    await apiService.deleteGateway(
                      gatewayId: widget.gateway['gatewayId'].toString(),
                    );
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Go back to the gateways list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gateway deleted successfully')),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting gateway: $e')),
                    );
                  }
                }
              },
              child: Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  void _transferGateway() {
    final TextEditingController _usernameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Transfer Gateway'),
          content: TextField(
            controller: _usernameController,
            decoration: InputDecoration(hintText: "Enter receiver's username"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  try {
                    final apiService = ApiService(context.read<AuthRepository>());
                    await apiService.transferGateway(
                      receiverUsername: _usernameController.text,
                      gatewayIdList: [widget.gateway['gatewayId'] as int],
                    );
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Go back to the gateways list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gateway transferred successfully')),
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error transferring gateway: $e')),
                    );
                  }
                }
              },
              child: Text('Transfer'),
            ),
          ],
        );
      },
    );
  }

  void _checkUpgrade() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      try {
        final apiService = ApiService(context.read<AuthRepository>());
        final result = await apiService.gatewayUpgradeCheck(
          gatewayId: widget.gateway['gatewayId'].toString(),
        );
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Upgrade Check'),
              content: Text(
                  'Need Upgrade: ${result['needUpgrade'] == 1 ? 'Yes' : 'No'}\n'
                  'Version: ${result['version'] ?? 'N/A'}'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking for upgrade: $e')),
        );
      }
    }
  }

  void _setUpgradeMode() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      try {
        final apiService = ApiService(context.read<AuthRepository>());
        await apiService.setGatewayUpgradeMode(
          gatewayId: widget.gateway['gatewayId'].toString(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gateway is set to upgrade mode')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting upgrade mode: $e')),
        );
      }
    }
  }
}
