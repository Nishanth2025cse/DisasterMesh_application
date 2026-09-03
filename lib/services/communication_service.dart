import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:uuid/uuid.dart';
import '../models/sos_model.dart';
import '../models/message_model.dart';
import '../models/device_model.dart';
import '../services/storage_service.dart';
import '../services/sos_service.dart';
import '../utils/constants.dart';

class CommunicationService {
  static final CommunicationService _instance = CommunicationService._internal();
  factory CommunicationService() => _instance;
  CommunicationService._internal();

  final StorageService _storage = StorageService();
  final SosService _sosService = SosService();
  final Uuid _uuid = const Uuid();

  final Strategy _strategy = Strategy.P2P_CLUSTER;
  String _currentDeviceId = "DEV-${const Uuid().v4().substring(0, 5)}";
  
  final List<DeviceModel> _discoveredDevices = [];
  final List<MeshMessage> _relayPriorityQueue = [];
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;

  final StreamController<List<DeviceModel>> _deviceStreamController = StreamController<List<DeviceModel>>.broadcast();
  Stream<List<DeviceModel>> get deviceStream => _deviceStreamController.stream;

  final StreamController<SosModel> _incomingSosStreamController = StreamController<SosModel>.broadcast();
  Stream<SosModel> get incomingSosStream => _incomingSosStreamController.stream;

  final StreamController<String> _logStreamController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logStreamController.stream;

  String get currentDeviceId => _currentDeviceId;
  int get nearbyDevicesCount => _discoveredDevices.where((d) => d.isConnected).length;
  List<DeviceModel> get nearbyDevices => List.unmodifiable(_discoveredDevices);

  void _log(String message) {
    if (kDebugMode) print('[MeshEngine] $message');
    _logStreamController.add("[${DateTime.now().toString().split('.').first.split(' ').last}] $message");
  }

  /// Initialize Mesh Network Communication
  Future<void> startMeshNetwork(String userName) async {
    _currentDeviceId = "DEV-${userName.replaceAll(' ', '')}-${_uuid.v4().substring(0, 4)}";
    _log("Initializing DisasterMesh node: $_currentDeviceId");

    // Start Nearby Advertising & Discovery
    await startAdvertising();
    await startDiscovery();
  }

  /// Start Advertising endpoint to nearby devices
  Future<void> startAdvertising() async {
    try {
      _isAdvertising = await Nearby().startAdvertising(
        _currentDeviceId,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (endpointId, status) {
          _log("Connection result with $endpointId: $status");
          if (status == Status.CONNECTED) {
            _updateDeviceConnection(endpointId, true);
            _processPriorityQueue(); // Flush pending relay messages
          }
        },
        onDisconnected: (endpointId) {
          _log("Device disconnected: $endpointId");
          _updateDeviceConnection(endpointId, false);
        },
        serviceId: AppConstants.serviceId,
      );
      _log("Nearby Advertising started.");
    } catch (e) {
      _log("Advertising error (Simulator/Permission fallback mode): ${e.toString()}");
    }
  }

  /// Start Discovering nearby DisasterMesh endpoints
  Future<void> startDiscovery() async {
    try {
      _isDiscovering = await Nearby().startDiscovery(
        _currentDeviceId,
        _strategy,
        onEndpointFound: (endpointId, endpointName, serviceId) {
          _log("Found endpoint: $endpointName ($endpointId)");
          _addDiscoveredDevice(endpointId, endpointName);
          // Request connection automatically for mesh node peering
          Nearby().requestConnection(
            _currentDeviceId,
            endpointId,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: (id, status) {
              _log("Connection result with $id: $status");
              if (status == Status.CONNECTED) {
                _updateDeviceConnection(id, true);
                _processPriorityQueue();
              }
            },
            onDisconnected: (id) {
              _updateDeviceConnection(id, false);
            },
          );
        },
        onEndpointLost: (endpointId) {
          _log("Endpoint lost: $endpointId");
          if (endpointId != null) {
            _removeDiscoveredDevice(endpointId);
          }
        },
        serviceId: AppConstants.serviceId,
      );
      _log("Nearby Discovery started.");
    } catch (e) {
      _log("Discovery error (Simulator/Permission fallback mode): ${e.toString()}");
    }
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo connectionInfo) {
    _log("Accepting connection from ${connectionInfo.endpointName}");
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (id, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          final String rawJson = utf8.decode(payload.bytes!);
          _handleIncomingRawPayload(rawJson, senderEndpointId: id);
        }
      },
    );
  }

  /// Broadcasts an SOS Alert across the mesh network
  Future<void> broadcastSos(SosModel sos) async {
    final MeshMessage message = MeshMessage(
      messageId: "MSG-${_uuid.v4().substring(0, 8)}",
      sosId: sos.sosId,
      payloadType: "SOS_ALERT",
      payloadJson: sos.toJson(),
      senderDeviceId: _currentDeviceId,
      timestamp: DateTime.now(),
      ttl: sos.ttl,
      hopsCount: 0,
    );

    _log("Broadcasting SOS ${sos.sosId} (Priority: ${sos.priority}, TTL: ${sos.ttl})");
    await _storage.recordRelayMessage(message);
    await _sendOrQueueMessage(message);
  }

  /// Handles Incoming Raw Payload received over Mesh
  Future<void> _handleIncomingRawPayload(String rawJson, {required String senderEndpointId}) async {
    try {
      final Map<String, dynamic> map = jsonDecode(rawJson);
      final MeshMessage message = MeshMessage.fromMap(map);

      _log("Received raw mesh payload ${message.messageId} for SOS ${message.sosId} from $senderEndpointId");

      // 1. DUPLICATE CHECK
      bool isDuplicate = await _storage.isDuplicateMessage(message.messageId);
      if (isDuplicate) {
        _log("Ignoring duplicate message ${message.messageId}");
        return;
      }

      // Record message as processed
      await _storage.recordRelayMessage(message);

      // 2. PARSE SOS MODEL
      final SosModel incomingSos = SosModel.fromJson(message.payloadJson);

      // Check if existing local SOS has newer version
      final existingLocal = await _storage.getSosById(incomingSos.sosId);
      if (existingLocal != null && existingLocal.version >= incomingSos.version) {
        _log("Local SOS version (${existingLocal.version}) is up to date or newer than incoming (${incomingSos.version}). Skipping duplicate store.");
      } else {
        // Store locally in SQLite database
        await _storage.saveSos(incomingSos);
        await _sosService.refreshSosList();
        _incomingSosStreamController.add(incomingSos);
        _log("🚨 NEW SOS STORED LOCALLY: ${incomingSos.sosId} from ${incomingSos.victimName}");
      }

      // 3. TTL / HOP LIMIT CHECK
      if (message.ttl <= 1) {
        _log("TTL reached 0 for message ${message.messageId}. Stopping relay.");
        return;
      }

      // 4. MULTI-HOP STORE-AND-FORWARD RELAY
      final MeshMessage forwardMessage = message.copyForForward(currentDeviceId: _currentDeviceId);
      _log("Prepared multi-hop forward payload for ${forwardMessage.sosId} (New TTL: ${forwardMessage.ttl}, Hops: ${forwardMessage.hopsCount})");

      await _sendOrQueueMessage(forwardMessage);
    } catch (e) {
      _log("Failed to process incoming payload: ${e.toString()}");
    }
  }

  /// Sends payload directly to connected endpoints or adds to Priority Queue
  Future<void> _sendOrQueueMessage(MeshMessage message) async {
    final connectedDevices = _discoveredDevices.where((d) => d.isConnected).toList();

    if (connectedDevices.isNotEmpty) {
      final Uint8List bytes = Uint8List.fromList(utf8.encode(message.toJson()));
      for (var device in connectedDevices) {
        try {
          await Nearby().sendBytesPayload(device.endpointId, bytes);
          _log("Sent payload ${message.messageId} to ${device.endpointName}");
        } catch (e) {
          _log("Failed sending payload to ${device.endpointName}: $e");
        }
      }
    } else {
      _log("No connected endpoints online. Adding message ${message.messageId} to offline Priority Queue.");
      _addToPriorityQueue(message);
    }
  }

  /// Priority Queue Management (🔴 HIGH priority transmitted first)
  void _addToPriorityQueue(MeshMessage message) {
    // Check if already in queue
    if (!_relayPriorityQueue.any((m) => m.messageId == message.messageId)) {
      _relayPriorityQueue.add(message);
      _sortPriorityQueue();
    }
  }

  void _sortPriorityQueue() {
    _relayPriorityQueue.sort((a, b) {
      try {
        final sosA = SosModel.fromJson(a.payloadJson);
        final sosB = SosModel.fromJson(b.payloadJson);
        int pA = _priorityValue(sosA.priority);
        int pB = _priorityValue(sosB.priority);
        if (pA != pB) return pB.compareTo(pA); // HIGH first
      } catch (_) {}
      return a.ttl.compareTo(b.ttl);
    });
  }

  int _priorityValue(String p) {
    if (p == 'HIGH') return 3;
    if (p == 'MEDIUM') return 2;
    return 1;
  }

  Future<void> _processPriorityQueue() async {
    if (_relayPriorityQueue.isEmpty) return;
    _log("Processing offline priority queue (${_relayPriorityQueue.length} messages)...");
    final List<MeshMessage> copy = List.from(_relayPriorityQueue);
    _relayPriorityQueue.clear();

    for (var msg in copy) {
      await _sendOrQueueMessage(msg);
    }
  }

  // --- DEMO / MULTI-HOP RELAY SIMULATION METHOD ---
  /// Allows testing Phone A -> Phone B -> Phone C -> Rescue Phone relay simulation
  Future<void> simulateMultiHopRelay({
    required SosModel sos,
    required String relayFromNode,
    required String relayToNode,
  }) async {
    _log("⚡ SIMULATING MESH RELAY: $relayFromNode ➔ $relayToNode (SOS: ${sos.sosId})");

    final MeshMessage message = MeshMessage(
      messageId: "SIM-MSG-${_uuid.v4().substring(0, 6)}",
      sosId: sos.sosId,
      payloadType: "SOS_ALERT",
      payloadJson: sos.toJson(),
      senderDeviceId: relayFromNode,
      timestamp: DateTime.now(),
      ttl: sos.ttl,
      hopsCount: 1,
    );

    // Simulate receiving on local node
    await _handleIncomingRawPayload(message.toJson(), senderEndpointId: relayFromNode);
  }

  // --- DEVICE MANAGERS ---

  void _addDiscoveredDevice(String id, String name) {
    if (!_discoveredDevices.any((d) => d.endpointId == id)) {
      _discoveredDevices.add(DeviceModel(
        endpointId: id,
        endpointName: name,
        isConnected: false,
        lastSeen: DateTime.now(),
      ));
      _deviceStreamController.add(List.from(_discoveredDevices));
    }
  }

  void _updateDeviceConnection(String id, bool connected) {
    final idx = _discoveredDevices.indexWhere((d) => d.endpointId == id);
    if (idx != -1) {
      _discoveredDevices[idx] = _discoveredDevices[idx].copyWith(
        isConnected: connected,
        lastSeen: DateTime.now(),
      );
      _deviceStreamController.add(List.from(_discoveredDevices));
    }
  }

  void _removeDiscoveredDevice(String id) {
    _discoveredDevices.removeWhere((d) => d.endpointId == id);
    _deviceStreamController.add(List.from(_discoveredDevices));
  }

  /// Inject virtual mock device for simulator testing
  void injectMockDevice(String name) {
    final id = "MOCK-${_uuid.v4().substring(0, 4)}";
    _discoveredDevices.add(DeviceModel(
      endpointId: id,
      endpointName: name,
      isConnected: true,
      lastSeen: DateTime.now(),
    ));
    _deviceStreamController.add(List.from(_discoveredDevices));
    _log("Injected simulated mesh device: $name ($id)");
  }
}
