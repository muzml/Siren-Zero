import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/mesh_service.dart';
import '../theme/app_theme.dart';
import 'mesh_chat_page.dart';

/// Mesh Device Discovery Screen
/// Scan for nearby devices, select one, and connect before chatting.
class MeshDeviceDiscoveryView extends StatefulWidget {
  const MeshDeviceDiscoveryView({super.key});

  @override
  State<MeshDeviceDiscoveryView> createState() =>
      _MeshDeviceDiscoveryViewState();
}

class _MeshDeviceDiscoveryViewState extends State<MeshDeviceDiscoveryView>
    with SingleTickerProviderStateMixin {
  final MeshService _mesh = MeshService();
  late AnimationController _radarController;

  MeshConnectionState _state = MeshConnectionState.idle;
  String? _connectingDeviceId;
  String? _errorMessage;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _mesh.onDiscoveredChanged = () {
      if (mounted) setState(() {});
    };
    _mesh.onConnectionStateChanged = (state) {
      if (mounted) {
        setState(() {
          _state = state;
          if (state != MeshConnectionState.connecting) {
            _connectingDeviceId = null;
          }
        });
        
        // Auto-navigate to chat upon connection for BOTH peers
        if (state == MeshConnectionState.connected && !_hasNavigated) {
          _hasNavigated = true;
          _mesh.stopScanAndAdvertise();
          _radarController.stop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MeshChatPage(
                peerName: _mesh.connectedPeerName ?? 'Unknown Service',
              ),
            ),
          );
        }
      }
    };
  }

  @override
  void dispose() {
    _radarController.dispose();
    _mesh.onDiscoveredChanged = null;
    _mesh.onConnectionStateChanged = null;
    // Don't call stopAll — mesh connection may persist into chat page
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────

  Future<void> _startScan() async {
    setState(() {
      _errorMessage = null;
      _state = MeshConnectionState.scanning;
    });
    _radarController.repeat();

    try {
      final granted = await _mesh.initPermissions();
      if (!granted) {
        _showError(
            'Permissions denied. Please enable Location and Bluetooth in Settings.');
        return;
      }

      await _mesh.startAdvertising('SirenUser');
      await _mesh.startDiscovery();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar('Scanning for nearby devices…', Icons.radar),
        );
      }
    } catch (e) {
      _showError(_friendlyError(e));
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _connectingDeviceId = device.id;
      _errorMessage = null;
    });

    try {
      final success = await _mesh.connectToDevice(device, 'SirenUser');

      if (!mounted) return;

      if (success) {
        // Navigation is now handled generically by onConnectionStateChanged
      } else {
        _showError('Could not connect to ${device.name}. Try again.');
      }
    } catch (e) {
      _showError(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _connectingDeviceId = null);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() {
      _errorMessage = msg;
      _state = MeshConnectionState.idle;
    });
    _radarController.stop();
    _radarController.reset();
  }

  String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('permission')) return 'Permission denied. Check app settings.';
    if (s.contains('bluetooth')) return 'Bluetooth is off. Please enable it.';
    if (s.contains('location')) return 'Location services are off. Please enable them.';
    return 'Something went wrong. Please try again.';
  }

  SnackBar _snackBar(String text, IconData icon) => SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(text),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : AppColors.lightBg, // Dope dark slate or premium light bg
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Find Nearby Devices',
            style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.lightTextPrimary),
          onPressed: () {
            _mesh.stopScanAndAdvertise();
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const RadialGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  center: Alignment.topCenter,
                  radius: 1.5,
                )
              : null, // Radial doesn't look as good in light mode
          color: Theme.of(context).brightness == Brightness.dark
              ? null
              : AppColors.lightBg,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusBanner(),
                const SizedBox(height: 32),
                _buildRadarAndScanButton(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  _buildErrorBanner(),
                ],
                const SizedBox(height: 32),
                if (_mesh.discoveredDevices.isNotEmpty) ...[
                  Text(
                    'NEARBY DEVICES',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.blueAccent.withOpacity(0.8),
                          letterSpacing: 1.5,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                  ).animate().fadeIn().slideX(),
                  const SizedBox(height: 16),
                  Expanded(child: _buildDeviceList()),
                ] else
                  Expanded(child: _buildEmptyDevicesState()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color bannerColor;
    IconData bannerIcon;
    String bannerText;

    switch (_state) {
      case MeshConnectionState.scanning:
        bannerColor = const Color(0xFF2563EB);
        bannerIcon = Icons.radar;
        bannerText = 'Scanning for nearby devices…';
        break;
      case MeshConnectionState.connecting:
        bannerColor = AppColors.alertOrange;
        bannerIcon = Icons.link;
        bannerText = 'Connecting…';
        break;
      case MeshConnectionState.connected:
        bannerColor = AppColors.safeGreen;
        bannerIcon = Icons.check_circle_rounded;
        bannerText = 'Connected!';
        break;
      case MeshConnectionState.disconnected:
        bannerColor = AppColors.emergencyRed;
        bannerIcon = Icons.link_off_rounded;
        bannerText = 'Disconnected';
        break;
      case MeshConnectionState.idle:
        bannerColor = Colors.white54;
        bannerIcon = Icons.wifi_tethering_off_rounded;
        bannerText = 'Ready to scan';
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCirc,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerColor, size: 22),
          const SizedBox(width: 14),
          Text(
            bannerText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: bannerColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
          ),
          if (_state == MeshConnectionState.scanning) ...[
            const Spacer(),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: bannerColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadarAndScanButton() {
    final isScanning = _state == MeshConnectionState.scanning;

    return Center(
      child: Column(
        children: [
          // Radar animation
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
              // Glowing backdrop
              if (isScanning)
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.3),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),

              // Pulsing rings
              if (isScanning)
                ...List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _radarController,
                    builder: (_, __) {
                      final progress =
                          ((_radarController.value + i * 0.33) % 1.0);
                      return Opacity(
                        opacity: (1 - progress).clamp(0.0, 0.8),
                        child: Container(
                          width: 90 + progress * 120,
                          height: 90 + progress * 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withOpacity(0.8),
                              width: 2.5 - (progress * 2),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

              // Center icon button
              GestureDetector(
                onTap: isScanning ? null : _startScan,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isScanning
                          ? [const Color(0xFF38BDF8), const Color(0xFF3B82F6)]
                          : [const Color(0xFF1E293B), const Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isScanning
                            ? const Color(0xFF38BDF8).withOpacity(0.5)
                            : Colors.black45,
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(isScanning ? 0.2 : 0.05),
                        blurRadius: 8,
                        spreadRadius: -2,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isScanning ? Icons.radar_rounded : Icons.wifi_tethering_rounded,
                    color: isScanning ? Colors.white : Colors.white70,
                    size: 38,
                  ),
                ),
              ),
              ],
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 20),

          SizedBox(
            height: 60,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isScanning
                ? Text(
                    'Looking for devices…',
                    key: const ValueKey('scanning'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF38BDF8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      key: const ValueKey('scan_button'),
                      onPressed: _startScan,
                      icon: const Icon(Icons.radar_rounded, color: Colors.white),
                      label: const Text('Start Scanning',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emergencyRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.emergencyRed.withOpacity(0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.emergencyRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.emergencyRed,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shakeX(hz: 3, amount: 4);
  }

  Widget _buildEmptyDevicesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
            child: Icon(
              Icons.devices_other_rounded,
              size: 64,
              color: Colors.blueAccent.withOpacity(0.5),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 2000.ms),
          const SizedBox(height: 24),
          Text(
            _state == MeshConnectionState.scanning
                ? 'Searching the area…'
                : 'Tap "Start Scanning" to find peers',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.9)
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ensure other devices have Siren-Zero open\nand Bluetooth/WiFi enabled.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.5)
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildDeviceList() {
    return ListView.separated(
      itemCount: _mesh.discoveredDevices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final device = _mesh.discoveredDevices[index];
        final isConnecting = _connectingDeviceId == device.id;

        return _DeviceCard(
          device: device,
          isConnecting: isConnecting,
          onConnect: () => _connectToDevice(device),
        ).animate().fadeIn(duration: 350.ms, delay: (index * 60).ms).slideY(
              begin: 0.15,
              end: 0,
              duration: 350.ms,
              delay: (index * 60).ms,
            );
      },
    );
  }
}

// ─── Device Card ─────────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final DiscoveredDevice device;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.device,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B).withOpacity(0.7)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Device icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.smartphone_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),

          // Name & ID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.isNotEmpty ? device.name : 'Unknown Device',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.id.length > 20
                      ? '${device.id.substring(0, 20)}…'
                      : device.id,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : AppColors.lightTextSecondary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Connect button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isConnecting
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFF38BDF8),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    ),
                    child: TextButton(
                      onPressed: onConnect,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Connect',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
