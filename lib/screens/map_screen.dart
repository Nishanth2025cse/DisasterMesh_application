import 'package:flutter/material.dart';
import '../models/sos_model.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'sos_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final StorageService _storage = StorageService();
  List<SosModel> _sosAlerts = [];
  bool _isLoading = true;
  SosModel? _selectedSos;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await _storage.getSosByPriority();
    if (mounted) {
      setState(() {
        _sosAlerts = list;
        _isLoading = false;
      });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return AppColors.priorityHigh;
      case 'MEDIUM':
        return AppColors.priorityMedium;
      case 'LOW':
        return AppColors.priorityLow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.map, color: AppColors.accentBlue),
            SizedBox(width: 8),
            Text(
              "📍 DISASTER MAP VISUALIZER",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accentBlue),
            onPressed: _loadData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                // Interactive Grid Map Visualizer Canvas
                InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(100),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: Container(
                      width: 360,
                      height: 520,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: GridMapPainter(_sosAlerts),
                        child: Stack(
                          children: _sosAlerts.map((sos) => _buildMarker(sos)).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Information Banner
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Active Victims: ${_sosAlerts.length}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Row(
                          children: [
                            _legendDot(AppColors.priorityHigh, "HIGH"),
                            const SizedBox(width: 8),
                            _legendDot(AppColors.priorityMedium, "MED"),
                            const SizedBox(width: 8),
                            _legendDot(AppColors.priorityLow, "LOW"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Selected SOS Bottom Info Card
                if (_selectedSos != null)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _getPriorityColor(_selectedSos!.priority), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${_selectedSos!.sosId} • ${_selectedSos!.victimName}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(_selectedSos!.priority).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _getPriorityColor(_selectedSos!.priority)),
                                ),
                                child: Text(
                                  _selectedSos!.priority,
                                  style: TextStyle(
                                    color: _getPriorityColor(_selectedSos!.priority),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Emergency: ${_selectedSos!.category}",
                            style: const TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedSos!.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "GPS: ${_selectedSos!.latitude.toStringAsFixed(4)}, ${_selectedSos!.longitude.toStringAsFixed(4)}",
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SosDetailsScreen(sosId: _selectedSos!.sosId),
                                    ),
                                  );
                                },
                                child: const Text("View Details", style: TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMarker(SosModel sos) {
    // Map latitude and longitude to canvas coordinates
    double minLat = 11.0000;
    double maxLat = 11.0500;
    double minLng = 76.9000;
    double maxLng = 76.9900;

    double latNorm = (sos.latitude - minLat) / (maxLat - minLat);
    double lngNorm = (sos.longitude - minLng) / (maxLng - minLng);

    latNorm = latNorm.clamp(0.1, 0.9);
    lngNorm = lngNorm.clamp(0.1, 0.9);

    double posX = lngNorm * 300;
    double posY = (1.0 - latNorm) * 440;

    Color pinColor = _getPriorityColor(sos.priority);
    bool isSelected = _selectedSos?.sosId == sos.sosId;

    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSos = sos;
          });
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : pinColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: pinColor.withOpacity(0.8),
                    blurRadius: isSelected ? 12 : 6,
                    spreadRadius: isSelected ? 3 : 1,
                  )
                ],
              ),
              child: Icon(
                Icons.location_on,
                color: isSelected ? pinColor : Colors.white,
                size: isSelected ? 24 : 18,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sos.sosId,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridMapPainter extends CustomPainter {
  final List<SosModel> sosList;

  GridMapPainter(this.sosList);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF2E3A52)
      ..strokeWidth = 1.0;

    double step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
