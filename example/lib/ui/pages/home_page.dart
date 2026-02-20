import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/blocs/auth/auth_bloc.dart';
import 'package:yavuz_lock/blocs/auth/auth_event.dart';
import 'package:yavuz_lock/blocs/auth/auth_state.dart'; // Import AuthState
import 'package:yavuz_lock/blocs/lock/lock_bloc.dart';
import 'package:yavuz_lock/blocs/lock/app_lock_state.dart';
import 'package:yavuz_lock/blocs/lock/lock_event.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/pages/add_device_page.dart';
import 'package:yavuz_lock/ui/pages/lock_detail_page.dart';
import 'package:yavuz_lock/ui/pages/gateway_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        String? accessToken;
        if (authState is Authenticated) {
          accessToken = authState.accessToken;
        }
        final authRepository = AuthRepository();
        return LockBloc(
          ApiService(authRepository),
          accessToken: accessToken,
        )..add(FetchLocks());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Locks'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBloc>().add(LoggedOut());
              },
            )
          ],
        ),
        body: BlocBuilder<LockBloc, AppLockState>(
          builder: (context, state) {
            if (state is LockLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LockLoaded) {
              final items = [...state.gateways, ...state.locks];
              
              if (items.isEmpty) {
                return const Center(child: Text('No devices found.'));
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isGateway = item.containsKey('gatewayId');

                  if (isGateway) {
                    return Card(
                      child: ListTile(
                        title: Text(item['gatewayName'] ?? 'Gateway'),
                        subtitle: Text(item['isOnline'] == 1 ? 'Online' : 'Offline'),
                        leading: const Icon(Icons.router),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GatewayDetailPage(gateway: item),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  final lock = item;
                  return Card(
                    child: ListTile(
                      title: Text(lock['name'] ?? lock['lockAlias'] ?? 'Unknown Lock'),
                      subtitle: Text(lock['status'] ?? ''),
                      leading: const Icon(Icons.lock),
                      trailing: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bluetooth),
                            const SizedBox(width: 4),
                            const Icon(Icons.wifi),
                            const SizedBox(width: 4),
                            Text('${lock['battery'] ?? 0}%'),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LockDetailPage(lock: lock),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }
            if (state is LockFailure) {
              return Center(child: Text('Failed to load devices: ${state.error}'));
            }
            return const Center(child: Text('No devices found.'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddDevicePage()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

