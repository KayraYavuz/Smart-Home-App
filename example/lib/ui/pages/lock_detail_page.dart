import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ttlock_flutter_example/blocs/device/device_bloc.dart';
import 'package:ttlock_flutter_example/blocs/device/device_event.dart';
import 'package:ttlock_flutter_example/blocs/device/device_state.dart';
import 'package:ttlock_flutter_example/settings_page.dart';

class LockDetailPage extends StatelessWidget {
  final Map<String, dynamic> lock;
  final String? seamDeviceId;
  final bool isSeamDevice;

  const LockDetailPage({
    Key? key,
    required this.lock,
    this.seamDeviceId,
    this.isSeamDevice = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  lock['name'],
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (isSeamDevice)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E90FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Seam',
                    style: TextStyle(
                      color: Color(0xFF1E90FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        body: BlocConsumer<DeviceBloc, DeviceState>(
          listener: (context, state) {
            if (state is DeviceSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Operation successful')),
              );
            }
            if (state is DeviceFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Operation failed: ${state.error}')),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildMainControlButton(context, state),
                ),
                _buildBottomActionMenu(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(),
          Text(
            lock['name'],
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Spacer(),
          Row(
            children: [
              Icon(Icons.battery_charging_full, color: Colors.orange, size: 20),
              SizedBox(width: 4),
              Text('${lock['battery']}%', style: TextStyle(color: Colors.orange, fontSize: 14)),
              SizedBox(width: 8),
              Icon(Icons.help_outline, color: Colors.white70, size: 22),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMainControlButton(BuildContext context, DeviceState state) {
    bool isLocked = lock['isLocked'];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (isLocked) {
              context.read<DeviceBloc>().add(UnlockDevice(lock));
            } else {
              context.read<DeviceBloc>().add(LockDevice(lock));
            }
          },
          onLongPress: () {
            // Uzun basma için gelecekte başka işlemler eklenebilir
            // Örneğin: kilit ayarları, geçmiş vb.
          },
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1E90FF).withOpacity(0.6),
                  blurRadius: 30.0,
                  spreadRadius: 5.0,
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (state is DeviceLoading)
                  CircularProgressIndicator()
                else
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF1E90FF).withOpacity(0.5), width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        isLocked ? Icons.lock : Icons.lock_open,
                        color: Color(0xFF1E90FF),
                        size: 80,
                      ),
                    ),
                  ),
                Positioned(
                  right: 15,
                  bottom: 15,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF1E90FF),
                    child: Icon(Icons.bluetooth, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Açmak için dokunun, kilitlemek için uzun basın',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBottomActionMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0, top: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: Colors.grey[800], height: 1),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMenuItem(
                context,
                icon: Icons.history,
                label: 'Kayıtlar',
                onTap: () {
                  // TODO: Navigate to logs page
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.password,
                label: 'Şifreler',
                onTap: () {
                  // TODO: Navigate to passcode page
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.credit_card,
                label: 'Kartlar',
                onTap: () {
                  // TODO: Navigate to card page
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.settings,
                label: 'Ayarlar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF1E90FF), size: 28),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Color(0xFF1E90FF), fontSize: 14)),
        ],
      ),
    );
  }
}
