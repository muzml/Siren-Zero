import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a discovered (not yet connected) nearby device.
class DiscoveredDevice {
  final String id;
  final String name;
  final String serviceId;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.serviceId,
    this.lat,
    this.long,
  });

  double? lat;
  double? long;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DiscoveredDevice && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Connection state for mesh UI.
enum MeshConnectionState {
  idle,
  scanning,
  connecting,
  connected,
  disconnected,
}

class MeshService {
  static final MeshService _instance = MeshService._internal();
  factory MeshService() => _instance;

  MeshService._internal() {
    debugPrint('🚀 MeshService initialized');
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('mesh_user_name') ?? 'SirenUser';
    debugPrint('👤 Loaded Custom Name: $userName');
  }

  Future<void> updateUserName(String newName) async {
    userName = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mesh_user_name', newName);
    debugPrint('💾 Saved New Custom Name: $newName');
    
    // Broadcast change to active peers
    await broadcastNameUpdate(newName);
  }

  Future<void> broadcastNameUpdate(String newName) async {
    final msg = 'NAME_UPDATE:|$newName';
    await sendMessage(msg);
  }

  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;
  static const String _serviceId = 'com.sirenzero.mesh-v3';
  String userName = 'SirenUser';

  // ─── State ─────────────────────────────────────────────────────────
  MeshConnectionState connectionState = MeshConnectionState.idle;
  Set<String> connectedDevices = {};
  final List<DiscoveredDevice> discoveredDevices = [];
  final Map<String, List<double>> peerLocations = {}; // endpointId -> [lat, long]
  String? _connectedPeerName;
  String? get connectedPeerName => _connectedPeerName;

  // ─── Callbacks for UI ──────────────────────────────────────────────
  Function(String message)? onMessageReceived;
  VoidCallback? onDevicesChanged;       // connectedDevices changed
  VoidCallback? onDiscoveredChanged;    // discoveredDevices list changed
  Function(MeshConnectionState)? onConnectionStateChanged;
  Function(String newName)? onPeerNameChanged;

  // ─── Permissions ───────────────────────────────────────────────────
  Future<bool> initPermissions() async {
    if (!Platform.isAndroid) return true;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    final List<Permission> permissions = [
      Permission.location,
    ];

    if (sdkInt >= 33) {
      // Android 13+
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.nearbyWifiDevices,
      ]);
    } else if (sdkInt >= 31) {
      // Android 12
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ]);
    } else {
      // Android 11 and below doesn't use runtime bluetooth permissions
      // nearby_connections will handle the standard BLUETOOTH permissions internally
      // if declared in manifest. Only location is needed at runtime here.
    }

    final results = await permissions.request();

    return results.values.every(
      (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
    );
  }

  // ─── Advertising (host) ────────────────────────────────────────────
  Future<void> startAdvertising(String name) async {
    await Nearby().startAdvertising(
      name,
      strategy,
      serviceId: _serviceId,
      onConnectionInitiated: (id, info) {
        _connectedPeerName = info.endpointName;
        Nearby().acceptConnection(
          id,
          onPayLoadRecieved: (endId, payload) {
            if (payload.type == PayloadType.BYTES) {
              final msg = String.fromCharCodes(payload.bytes!);
              _handleIncomingMessage(msg);
            }
          },
        );
      },
      onConnectionResult: (id, status) {
        if (status == Status.CONNECTED) {
          connectedDevices.add(id);
          _setState(MeshConnectionState.connected);
          onDevicesChanged?.call();
          debugPrint('✅ ADVERTISER CONNECTED: $id');
        } else if (status == Status.REJECTED || status == Status.ERROR) {
          _setState(MeshConnectionState.disconnected);
        }
      },
      onDisconnected: (id) {
        connectedDevices.remove(id);
        _connectedPeerName = null;
        _setState(connectedDevices.isEmpty
            ? MeshConnectionState.disconnected
            : MeshConnectionState.connected);
        onDevicesChanged?.call();
        debugPrint('❌ ADVERTISER DISCONNECTED: $id');
      },
    );
  }

  // ─── Discovery ─────────────────────────────────────────────────────
  Future<void> startDiscovery(String name) async {
    discoveredDevices.clear();
    onDiscoveredChanged?.call();

    await Nearby().startDiscovery(
      name,
      strategy,
      serviceId: _serviceId,
      onEndpointFound: (id, name, serviceId) {
        debugPrint('🔥 FOUND DEVICE: $id  $name');
        // Avoid duplicates
        if (discoveredDevices.any((d) => d.id == id)) return;
        discoveredDevices.add(
          DiscoveredDevice(id: id, name: name, serviceId: serviceId),
        );
        onDiscoveredChanged?.call();
      },
      onEndpointLost: (id) {
        discoveredDevices.removeWhere((d) => d.id == id);
        onDiscoveredChanged?.call();
        debugPrint('⚠️ DEVICE LOST: $id');
      },
    );
  }

  // ─── Manual Connect ────────────────────────────────────────────────
  Future<bool> connectToDevice(
    DiscoveredDevice device,
    String userName,
  ) async {
    // 🔍 Pre-check if already in our set of connected devices
    if (connectedDevices.contains(device.id)) {
      debugPrint('ℹ️ ALREADY CONNECTED to: ${device.id}');
      _setState(MeshConnectionState.connected);
      return true;
    }

    _setState(MeshConnectionState.connecting);
    debugPrint('⚡ CONNECTING TO: ${device.id}  ${device.name}');

    final completer = Completer<bool>();
    bool hasCompleted = false;

    void safeComplete(bool result) {
      if (!hasCompleted) {
        hasCompleted = true;
        completer.complete(result);
      }
    }

    try {
      await Nearby().requestConnection(
        userName,
        device.id,
        onConnectionInitiated: (id, info) {
          _connectedPeerName = device.name;
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endId, payload) {
              if (payload.type == PayloadType.BYTES) {
                final msg = String.fromCharCodes(payload.bytes!);
                _handleIncomingMessage(msg);
              }
            },
          );
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            connectedDevices.add(id);
            _setState(MeshConnectionState.connected);
            onDevicesChanged?.call();
            debugPrint('✅ MANUAL CONNECTED: $id');
            safeComplete(true);
          } else {
            _setState(MeshConnectionState.disconnected);
            debugPrint('❌ CONNECTION REJECTED/ERROR: $status');
            safeComplete(false);
          }
        },
        onDisconnected: (id) {
          connectedDevices.remove(id);
          _connectedPeerName = null;
          _setState(MeshConnectionState.disconnected);
          onDevicesChanged?.call();
          debugPrint('❌ DISCONNECTED: $id');
          safeComplete(false);
        },
      );

      // Robust timeout for the handshake
      return await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('⏳ CONNECTION TIMEOUT');
          _setState(MeshConnectionState.disconnected);
          safeComplete(false);
          return false;
        },
      );
    } catch (e) {
      // 🧠 Handle "Already Connected" PlatformException (Error 8003)
      if (e.toString().contains('8003') || e.toString().contains('STATUS_ALREADY_CONNECTED')) {
        debugPrint('ℹ️ PLATFORM SAYS ALREADY CONNECTED: ${device.id}');
        connectedDevices.add(device.id); // Ensure it is tracked
        _setState(MeshConnectionState.connected);
        safeComplete(true);
        return true;
      }
      
      _setState(MeshConnectionState.disconnected);
      debugPrint('❌ CONNECT ERROR: $e');
      safeComplete(false);
      rethrow;
    }
  }

  // ─── Send Message ──────────────────────────────────────────────────
  Future<void> sendMessage(String message) async {
    // Prefix with a unique session tag to avoid cross-dedup issues
    final tagged = '${DateTime.now().millisecondsSinceEpoch}|$message';
    final bytes = Uint8List.fromList(tagged.codeUnits);

    for (final id in connectedDevices) {
      try {
        await Nearby().sendBytesPayload(id, bytes);
        debugPrint('📤 SENT TO: $id');
      } catch (e) {
        debugPrint('❌ SEND FAILED to $id: $e');
      }
    }
  }

  // ─── Location Broadcast ───────────────────────────────────────────
  Future<void> broadcastLocation(double lat, double long) async {
    final msg = 'LOC:|$lat|$long';
    await sendMessage(msg);
  }

  // ─── Receive Handler ───────────────────────────────────────────────
  void _handleIncomingMessage(String raw) {
    // Strip timestamp prefix if present
    final separatorIndex = raw.indexOf('|');
    final message =
        separatorIndex != -1 ? raw.substring(separatorIndex + 1) : raw;

    debugPrint('📥 RECEIVED: $message');

    // 👤 HANDLE NAME UPDATES
    if (message.startsWith('NAME_UPDATE:|')) {
      try {
        final parts = message.split('|');
        if (parts.length >= 2) {
          final newName = parts[1];
          _connectedPeerName = newName;
          onPeerNameChanged?.call(newName);
          debugPrint('👤 PEER UPDATED NAME: $newName');
        }
      } catch (e) {
        debugPrint('❌ NAME PARSE ERROR: $e');
      }
      return;
    }

    // 📍 HANDLE LOCATION UPDATES
    if (message.startsWith('LOC:|')) {
      try {
        final parts = message.split('|');
        if (parts.length >= 3) {
          final lat = double.parse(parts[1]);
          final long = double.parse(parts[2]);
          // For now, let's assume the first connected device if we can't map ID perfectly here
          // In a real app, you'd include the sender ID in the payload
          if (connectedDevices.isNotEmpty) {
            peerLocations[connectedDevices.first] = [lat, long];
            onDevicesChanged?.call();
          }
        }
      } catch (e) {
        debugPrint('❌ LOC PARSE ERROR: $e');
      }
      return;
    }

    onMessageReceived?.call(message);
  }

  // ─── State Helper ──────────────────────────────────────────────────
  void _setState(MeshConnectionState state) {
    connectionState = state;
    onConnectionStateChanged?.call(state);
  }

  // ─── Cleanup ───────────────────────────────────────────────────────
  void stopAll() {
    try {
      Nearby().stopAllEndpoints();
      Nearby().stopAdvertising();
      Nearby().stopDiscovery();
    } catch (_) {}
    connectedDevices.clear();
    discoveredDevices.clear();
    _connectedPeerName = null;
    _setState(MeshConnectionState.idle);
    onMessageReceived = null;
    onDevicesChanged = null;
    onDiscoveredChanged = null;
    onConnectionStateChanged = null;
  }

  /// Stops scanning/advertising without clearing message callbacks.
  void stopScanAndAdvertise() {
    try {
      Nearby().stopAdvertising();
      Nearby().stopDiscovery();
    } catch (_) {}
  }
}