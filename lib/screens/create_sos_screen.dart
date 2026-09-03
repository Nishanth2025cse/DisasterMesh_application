import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/sos_service.dart';
import '../services/communication_service.dart';
import '../services/location_service.dart';
import '../services/classification_service.dart';
import '../services/priority_service.dart';
import '../utils/constants.dart';
import '../widgets/priority_badge.dart';
import 'home_screen.dart';

class CreateSosScreen extends StatefulWidget {
  final UserModel user;
  final String? initialMessage;
  final double? initialLat;
  final double? initialLng;
  final String? gpsErrorMessage;

  const CreateSosScreen({
    super.key,
    required this.user,
    this.initialMessage,
    this.initialLat,
    this.initialLng,
    this.gpsErrorMessage,
  });

  @override
  State<CreateSosScreen> createState() => _CreateSosScreenState();
}

class _CreateSosScreenState extends State<CreateSosScreen> {
  final _sosService = SosService();
  final _commService = CommunicationService();
  final _locationService = LocationService();
  final _classifier = ClassificationService();
  final _prioritizer = PriorityService();

  late TextEditingController _messageController;
  late double _latitude;
  late double _longitude;
  
  String _category = AppCategories.general;
  String _priority = AppPriorities.low;
  bool _isSubmitting = false;
  bool _isRefreshingGps = false;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage ?? '');
    _latitude = widget.initialLat ?? 11.02345;
    _longitude = widget.initialLng ?? 76.96231;
    _gpsError = widget.gpsErrorMessage;

    _updateClassification(_messageController.text);
  }

  void _updateClassification(String text) {
    setState(() {
      _category = _classifier.classifyMessage(text);
      _priority = _prioritizer.calculatePriority(_category, text);
    });
  }

  Future<void> _refreshGps() async {
    setState(() {
      _isRefreshingGps = true;
      _gpsError = null;
    });

    final res = await _locationService.getCurrentLocation();
    setState(() {
      _isRefreshingGps = false;
      if (res.isSuccess) {
        _latitude = res.latitude ?? 11.02345;
        _longitude = res.longitude ?? 76.96231;
      } else {
        _gpsError = res.errorMessage;
      }
    });
  }

  Future<void> _submitSos() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emergency message cannot be empty.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Create SOS & Save locally in SQLite
      final sos = await _sosService.createSos(
        user: widget.user,
        message: _messageController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        deviceId: _commService.currentDeviceId,
      );

      // 2. Broadcast across P2P mesh network
      await _commService.broadcastSos(sos);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.priorityLow,
          content: Text("🚨 SOS ${sos.sosId} Broadcasted Successfully!"),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(user: widget.user)),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create SOS: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("✍️ Create SOS Alert", style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Describe Emergency",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Enter clear details (e.g. 'I am trapped inside my house. Water level is increasing.').",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              onChanged: _updateClassification,
              decoration: InputDecoration(
                hintText: "Type emergency description here...",
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Real-time Classification & Priority Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Auto Category", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          _category,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Emergency Priority", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        PriorityBadge(priority: _priority),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // GPS Coordinates Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gpsError != null ? AppColors.priorityHigh : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.gps_fixed, color: AppColors.primaryGlow, size: 18),
                          SizedBox(width: 8),
                          Text("GPS Satellite Coordinates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      IconButton(
                        icon: _isRefreshingGps
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.refresh, color: AppColors.accentBlue, size: 20),
                        onPressed: _isRefreshingGps ? null : _refreshGps,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Latitude: ${_latitude.toStringAsFixed(5)}",
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                  Text(
                    "Longitude: ${_longitude.toStringAsFixed(5)}",
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  ),
                  if (_gpsError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _gpsError!,
                      style: const TextStyle(color: AppColors.priorityHigh, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Broadcast SOS Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitSos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                label: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "BROADCAST SOS ALERT 🔴",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
