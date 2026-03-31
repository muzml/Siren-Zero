import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

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
  }

  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;

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

  // ─── Permissions ───────────────────────────────────────────────────
  Future<bool> initPermissions() async {
    final results = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ].request();

    return results.values.every(
      (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
    );
  }

  // ─── Advertising (host) ────────────────────────────────────────────
  Future<void> startAdvertising(String userName) async {
    await Nearby().startAdvertising(
      userName,
      strategy,
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
  Future<void> startDiscovery() async {
    discoveredDevices.clear();
    onDiscoveredChanged?.call();

    await Nearby().startDiscovery(
      'SirenZero-Discoverer',
      strategy,
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
    _setState(MeshConnectionState.connecting);
    debugPrint('⚡ CONNECTING TO: ${device.id}  ${device.name}');

    final completer = <bool>[];

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
            completer.add(true);
            debugPrint('✅ MANUAL CONNECTED: $id');
          } else {
            _setState(MeshConnectionState.disconnected);
            completer.add(false);
            debugPrint('❌ CONNECTION REJECTED/ERROR: $status');
          }
        },
        onDisconnected: (id) {
          connectedDevices.remove(id);
          _connectedPeerName = null;
          _setState(MeshConnectionState.disconnected);
          onDevicesChanged?.call();
          debugPrint('❌ DISCONNECTED: $id');
        },
      );

      // Wait a moment for the result callback
      await Future.delayed(const Duration(seconds: 5));
      return completer.isNotEmpty && completer.first;
    } catch (e) {
      _setState(MeshConnectionState.disconnected);
      debugPrint('❌ CONNECT ERROR: $e');
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