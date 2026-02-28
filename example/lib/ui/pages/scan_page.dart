import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/blocs/scan/scan_bloc.dart';
import 'package:yavuz_lock/blocs/scan/scan_event.dart';
import 'package:yavuz_lock/blocs/scan/scan_state.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:yavuz_lock/wifi_page.dart';

class ScanPage extends StatelessWidget {
  final bool isGateway;
  const ScanPage({super.key, this.isGateway = false});

  String _getLocalizedErrorMessage(String error, AppLocalizations l10n) {
    if (error == 'bluetoothDisabledError') return l10n.bluetoothDisabledError;
    if (error == 'lockNotInSettingMode') return l10n.lockNotInSettingMode;
    if (error == 'lockAlreadyRegistered') return l10n.lockAlreadyRegistered;
    if (error == 'bluetoothConnectionRejected') return l10n.bluetoothConnectionRejected;
    if (error == 'bluetoothConnectionFailed') return l10n.bluetoothConnectionFailed;
    if (error == 'lockNotResponding') return l10n.lockNotResponding;
    if (error == 'apiLockRegisteredToAnother') return l10n.apiLockRegisteredToAnother;
    if (error == 'apiNotAuthorized') return l10n.apiNotAuthorized;
    if (error == 'apiSessionExpired') return l10n.apiSessionExpired;
    if (error == 'apiLockFrozen') return l10n.apiLockFrozen;
    if (error == 'apiTimestampError') return l10n.apiTimestampError;
    if (error == 'apiDeletePreviousLocks') return l10n.apiDeletePreviousLocks;
    if (error == 'apiClientAuthError') return l10n.apiClientAuthError;
    if (error == 'apiServerError') return l10n.apiServerError;
    if (error == 'apiOperationRejected') return l10n.apiOperationRejected;

    if (error.startsWith('btErrorPrefix:')) {
      final parts = error.split(':');
      if (parts.length >= 3) {
        final code = parts[1];
        final detailsKey = parts[2];
        final details = _getLocalizedErrorMessage(detailsKey, l10n);
        return l10n.btErrorPrefix(code, details);
      }
    }
    if (error.startsWith('cloudRegistrationError:')) {
      final detailsKey = error.substring('cloudRegistrationError:'.length);
      return l10n.cloudRegistrationError(_getLocalizedErrorMessage(detailsKey, l10n));
    }
    if (error.startsWith('unexpectedErrorPrefix:')) {
      return l10n.unexpectedErrorPrefix(error.substring('unexpectedErrorPrefix:'.length));
    }

    return error;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => ScanBloc(
        apiService: RepositoryProvider.of<ApiService>(context),
      )..add(StartScan(isGateway: isGateway)),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          title: Text(
            isGateway ? l10n.scanGatewayTitle : l10n.scanLockTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            BlocBuilder<ScanBloc, ScanState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    state is ScanLoading ? Icons.stop : Icons.refresh,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (state is ScanLoading) {
                      context.read<ScanBloc>().add(StopScan());
                    } else {
                      context.read<ScanBloc>().add(StartScan(isGateway: isGateway));
                    }
                  },
                  tooltip: state is ScanLoading ? l10n.stopScan : l10n.reScan,
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<ScanBloc, ScanState>(
          listener: (context, state) {
            if (state is AddLockSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.deviceAddedSuccess),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, {
                'action': 'ttlock_added',
                'lock': state.addedLock,
              });
            }
            if (state is ScanFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_getLocalizedErrorMessage(state.error, l10n)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ScanConnecting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.5),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E90FF).withValues(alpha: 0.2 - (value - 1.0) * 0.2), // Fading ripple
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isGateway ? Icons.router : Icons.lock_open,
                              color: const Color(0xFF1E90FF),
                              size: 48,
                            ),
                          ),
                        );
                      },
                      onEnd: () {}, 
                    ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(
                      color: Color(0xFF1E90FF),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.connectingTo(state.lockName),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGateway ? l10n.scanningGatewayStatus : l10n.scanningLockStatus,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is ScanLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isGateway ? l10n.scanningGateways : l10n.scanningLocks,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.ensureBluetooth,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is ScanLoaded) {
              final items = isGateway ? state.gateways : state.locks;
              
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        color: Colors.grey[600],
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isGateway ? l10n.gatewayNotFound : l10n.lockNotFound,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.scanNotFoundMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<ScanBloc>().add(StartScan(isGateway: isGateway));
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text(
                          l10n.reScan,
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF1E1E1E),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bluetooth_searching,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.foundDevices(items.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        if (isGateway) {
                          final gateway = items[index] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.router, color: Colors.blue),
                              title: Text(gateway['gatewayName'] ?? l10n.unknownGateway, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(gateway['gatewayMac'] ?? '', style: TextStyle(color: Colors.grey[400])),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WifiPage(mac: gateway['gatewayMac']),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                child: Text(l10n.add, style: const TextStyle(color: Colors.white)),
                              ),
                            ),
                          );
                        } else {
                          final lock = items[index] as TTLockScanModel;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                lock.lockName.isNotEmpty ? lock.lockName : l10n.unnamedLock,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MAC: ${lock.lockMac}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Versiyon: ${lock.lockVersion}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  context.read<ScanBloc>().add(AddLock(lock));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: Text(
                                  l10n.add,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.scanning,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
