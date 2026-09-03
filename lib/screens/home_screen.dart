import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/sos_model.dart';
import '../services/sos_service.dart';
import '../services/communication_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../widgets/sos_button.dart';
import '../widgets/sos_card.dart';
import '../widgets/install_app_banner.dart';
import 'voice_emergency_screen.dart';
import 'create_sos_screen.dart';
import 'sos_details_screen.dart';
import 'rescue_dashboard_screen.dart';
import 'nearby_devices_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SosService _sosService = SosService();
  final CommunicationService _commService = CommunicationService();
  final LocationService _locationService = LocationService();

  List<SosModel> _previousSosAlerts = [];
  int _nearbyDeviceCount = 0;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _initMeshAndData();
  }

  Future<void> _initMeshAndData() async {
    // Start mesh network node
    await _commService.startMeshNetwork(widget.user.name);

    // Add mock initial device for demonstration if empty
    if (_commService.nearbyDevices.isEmpty) {
      _commService.injectMockDevice("Phone B (Relay)");
      _commService.injectMockDevice("Phone C (Relay)");
    }

    _updateDevicesCount();
    _loadSosAlerts();

    _commService.deviceStream.listen((devices) {
      if (mounted) {
        setState(() {
          _nearbyDeviceCount = devices.where((d) => d.isConnected).length;
        });
      }
    });

    _sosService.sosStream.listen((list) {
      if (mounted) {
        setState(() => _previousSosAlerts = list);
      }
    });

    _commService.incomingSosStream.listen((sos) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Row(
              children: [
                const Text("🚨 ", style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    "NEW SOS RECEIVED: ${sos.sosId} (${sos.category})",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _updateDevicesCount() {
    setState(() {
      _nearbyDeviceCount = _commService.nearbyDevices.where((d) => d.isConnected).length;
    });
  }

  Future<void> _loadSosAlerts() async {
    final list = await _sosService.getAllSosAlerts();
    if (mounted) setState(() => _previousSosAlerts = list);
  }

  /// One-Tap Direct SOS Action
  Future<void> _handleDirectSosPress() async {
    setState(() => _isLoadingGps = true);
    final locResult = await _locationService.getCurrentLocation();
    setState(() => _isLoadingGps = false);

    double lat = locResult.latitude ?? 11.02345;
    double lng = locResult.longitude ?? 76.96231;

    if (!mounted) return;

    // Open Create SOS Screen pre-filled with GPS
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSosScreen(
          user: widget.user,
          initialLat: lat,
          initialLng: lng,
          gpsErrorMessage: locResult.isSuccess ? null : locResult.errorMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cell_tower, color: AppColors.primaryGlow),
            tooltip: "Mesh Network",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NearbyDevicesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.medical_services_outlined, color: AppColors.statusPending),
            tooltip: "Rescue Dashboard",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RescueDashboardScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InstallAppBanner(),
            // Welcome Header & Mesh Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, ${widget.user.name}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Blood Group: ${widget.user.bloodGroup}",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NearbyDevicesScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.priorityLow),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.priorityLow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Mesh: Active",
                          style: TextStyle(
                            color: AppColors.priorityLow,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Nearby Devices Indicator Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.devices, color: AppColors.accentBlue, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Nearby Devices: $_nearbyDeviceCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NearbyDevicesScreen()),
                      );
                    },
                    child: const Text("View Network ➔", style: TextStyle(color: AppColors.accentBlue)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Prominent SOS Emergency Pulse Button 🔴
            Center(
              child: _isLoadingGps
                  ? const Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text("Fetching GPS Location...", style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    )
                  : SosButton(onPressed: _handleDirectSosPress),
            ),

            const SizedBox(height: 28),

            // Action Options: Voice & Type Emergency
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VoiceEmergencyScreen(user: widget.user),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.primaryGlow, width: 1.2),
                      ),
                    ),
                    icon: const Text("🎙️", style: TextStyle(fontSize: 18)),
                    label: const Text(
                      "Voice Emergency",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleDirectSosPress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.accentBlue, width: 1.2),
                      ),
                    ),
                    icon: const Text("✍️", style: TextStyle(fontSize: 18)),
                    label: const Text(
                      "Type Emergency",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Navigation Cards for Rescue & Mesh
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RescueDashboardScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusPending.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Text("🚨", style: TextStyle(fontSize: 22)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Rescue Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text("Filter & respond", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NearbyDevicesScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accentBlue.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Text("📡", style: TextStyle(fontSize: 22)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Mesh Relay Log", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text("Phone A➔B➔C", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Previous SOS Alerts Section
            const Text(
              "Previous SOS Alerts",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            _previousSosAlerts.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.shield_moon_outlined, size: 36, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          "No active SOS alerts created yet.",
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _previousSosAlerts.length,
                    itemBuilder: (context, index) {
                      final sos = _previousSosAlerts[index];
                      return SosCard(
                        sos: sos,
                        index: index,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SosDetailsScreen(sosId: sos.sosId),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
