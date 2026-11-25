import 'package:flutter/material.dart';
import '../services/communication_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/device_card.dart';

class NearbyDevicesScreen extends StatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  State<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends State<NearbyDevicesScreen> {
  final CommunicationService _commService = CommunicationService();
  final StorageService _storage = StorageService();

  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _commService.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.insert(0, log);
          if (_logs.length > 50) _logs.removeLast();
        });
      }
    });
  }

  /// Interactive Multi-Hop Relay Simulation Trigger (Phone A -> Phone B -> Phone C -> Rescue Phone D)
  Future<void> _runMultiHopSimulation() async {
    final sosAlerts = await _storage.getAllSos();
    if (sosAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please create an SOS alert on the Home screen first.")),
      );
      return;
    }

    final targetSos = sosAlerts.first;

    // Step 1: Relay Phone A -> Phone B
    await _commService.simulateMultiHopRelay(
      sos: targetSos,
      relayFromNode: "Phone-A (Victim)",
      relayToNode: "Phone-B (Relay Node 1)",
    );

    await Future.delayed(const Duration(milliseconds: 800));

    // Step 2: Relay Phone B -> Phone C
    await _commService.simulateMultiHopRelay(
      sos: targetSos,
      relayFromNode: "Phone-B (Relay Node 1)",
      relayToNode: "Phone-C (Relay Node 2)",
    );

    await Future.delayed(const Duration(milliseconds: 800));

    // Step 3: Relay Phone C -> Rescue Phone D
    await _commService.simulateMultiHopRelay(
      sos: targetSos,
      relayFromNode: "Phone-C (Relay Node 2)",
      relayToNode: "Rescue-Phone-D (Command Center)",
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.priorityLow,
          content: Text("✅ Multi-Hop Mesh Simulation Completed: Phone A ➔ B ➔ C ➔ Rescue D"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = _commService.nearbyDevices;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("📡 Mesh Relay Network", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accentBlue),
            tooltip: "Restart BLE Scanning & Advertising",
            onPressed: () async {
              await _commService.requestPermissions();
              await _commService.startAdvertising();
              await _commService.startDiscovery();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Restarted BLE Scanning & Advertising")),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mesh Topology Overview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Mesh Topology",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.priorityLow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.priorityLow),
                        ),
                        child: const Text(
                          "P2P Cluster Active",
                          style: TextStyle(color: AppColors.priorityLow, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Local Node ID: ${_commService.currentDeviceId}",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Victim Phone A ➔ Relay Phone B ➔ Relay Phone C ➔ Rescue Phone D",
                    style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Multi-Hop Simulation Action Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentBlue.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "⚡ Test Multi-Hop Protocol (A ➔ B ➔ C ➔ D)",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Simulates store-and-forward TTL decrement, duplicate prevention, and priority relaying across multi-node chain.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _runMultiHopSimulation,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                      icon: const Icon(Icons.alt_route, color: Colors.white, size: 18),
                      label: const Text("Simulate Multi-Hop Mesh Relay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Discovered Devices Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Nearby DisasterMesh Devices",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    _commService.injectMockDevice("Phone ${String.fromCharCode(68 + devices.length)} (Relay)");
                    setState(() {});
                  },
                  icon: const Icon(Icons.add, size: 16, color: AppColors.accentBlue),
                  label: const Text("Add Peer", style: TextStyle(color: AppColors.accentBlue, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            devices.isEmpty
                ? const Text("No nearby devices discovered yet.", style: TextStyle(color: AppColors.textMuted))
                : Column(
                    children: devices.map((d) => DeviceCard(device: d)).toList(),
                  ),

            const SizedBox(height: 24),

            // Mesh Network Logs Stream Box
            const Text(
              "Transmission & Relay Logs",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: _logs.isEmpty
                  ? const Center(child: Text("Waiting for P2P mesh packets...", style: TextStyle(color: AppColors.textMuted, fontSize: 12)))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (ctx, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _logs[i],
                            style: const TextStyle(color: AppColors.priorityLow, fontFamily: 'monospace', fontSize: 11),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
