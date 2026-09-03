import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_model.dart';
import '../services/sos_service.dart';
import '../services/storage_service.dart';
import '../services/communication_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/priority_badge.dart';

class SosDetailsScreen extends StatefulWidget {
  final String sosId;

  const SosDetailsScreen({super.key, required this.sosId});

  @override
  State<SosDetailsScreen> createState() => _SosDetailsScreenState();
}

class _SosDetailsScreenState extends State<SosDetailsScreen> {
  final StorageService _storage = StorageService();
  final SosService _sosService = SosService();
  final CommunicationService _commService = CommunicationService();

  SosModel? _sos;
  bool _isLoading = true;
  final TextEditingController _updateMsgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final sos = await _storage.getSosById(widget.sosId);
    if (mounted) {
      setState(() {
        _sos = sos;
        _isLoading = false;
      });
    }
  }

  /// Dynamic SOS Update while retaining the same SOS ID!
  Future<void> _showUpdateDialog() async {
    _updateMsgController.text = _sos?.message ?? '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            "Update Emergency Alert (${_sos?.sosId})",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Update description without changing SOS ID:",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _updateMsgController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "e.g. Person has collapsed and is unconscious.",
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newText = _updateMsgController.text.trim();
                if (newText.isEmpty) return;

                Navigator.pop(ctx);
                final updatedSos = await _sosService.updateExistingSos(
                  sosId: widget.sosId,
                  updatedMessage: newText,
                );

                // Broadcast updated payload over mesh
                await _commService.broadcastSos(updatedSos);

                await _loadDetails();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Updated ${_sos?.sosId} dynamically and re-broadcasted over mesh!")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Save & Re-Broadcast", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  /// Open external map app if available
  Future<void> _openExternalMap() async {
    if (_sos == null) return;
    final Uri mapUri = Uri.parse("geo:${_sos!.latitude},${_sos!.longitude}?q=${_sos!.latitude},${_sos!.longitude}(Victim+Location)");
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri);
      } else {
        final Uri googleWebUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${_sos!.latitude},${_sos!.longitude}");
        await launchUrl(googleWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Coordinates: ${_sos!.latitude}, ${_sos!.longitude}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface, title: const Text("SOS Details")),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_sos == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface, title: const Text("SOS Details")),
        body: const Center(child: Text("SOS Record Not Found", style: TextStyle(color: Colors.white))),
      );
    }

    final sos = _sos!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text("Alert Details (${sos.sosId})", style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.accentBlue),
            tooltip: "Dynamic Update SOS",
            onPressed: _showUpdateDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
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
                      Text(
                        sos.sosId,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      PriorityBadge(priority: sos.priority),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailRow(Icons.person, "Victim Name", sos.victimName),
                  if (sos.victimPhone != null && sos.victimPhone!.isNotEmpty)
                    _detailRow(Icons.phone, "Phone Number", sos.victimPhone!),
                  _detailRow(Icons.category, "Emergency Category", sos.category),
                  _detailRow(Icons.access_time, "Timestamp", Helpers.formatFullDateTime(sos.timestamp)),
                  _detailRow(Icons.tag, "Update Version", "v${sos.version}"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Emergency Message Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("EMERGENCY MESSAGE", style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    sos.message,
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location Box & Map Option
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
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.primaryGlow, size: 20),
                          SizedBox(width: 8),
                          Text("GPS Coordinates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _openExternalMap,
                        icon: const Icon(Icons.map, size: 16, color: AppColors.accentBlue),
                        label: const Text("Open Map", style: TextStyle(color: AppColors.accentBlue, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("Latitude: ${sos.latitude.toStringAsFixed(5)}", style: const TextStyle(color: AppColors.textSecondary)),
                  Text("Longitude: ${sos.longitude.toStringAsFixed(5)}", style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dynamic Update History Timeline
            if (sos.updateHistory.isNotEmpty) ...[
              const Text("Update History Log", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: sos.updateHistory.reversed.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.history, size: 16, color: AppColors.accentBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.message, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                Text(
                                  "${entry.category} | ${entry.priority} | ${Helpers.formatTime(entry.timestamp)}",
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _showUpdateDialog,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentBlue),
                icon: const Icon(Icons.update, color: Colors.white),
                label: const Text("Dynamic Update SOS Record", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
