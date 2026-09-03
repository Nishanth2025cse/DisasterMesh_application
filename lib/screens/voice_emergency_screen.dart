import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/speech_service.dart';
import '../services/location_service.dart';
import '../services/classification_service.dart';
import '../services/priority_service.dart';
import '../utils/constants.dart';
import '../widgets/priority_badge.dart';
import 'create_sos_screen.dart';

class VoiceEmergencyScreen extends StatefulWidget {
  final UserModel user;

  const VoiceEmergencyScreen({super.key, required this.user});

  @override
  State<VoiceEmergencyScreen> createState() => _VoiceEmergencyScreenState();
}

class _VoiceEmergencyScreenState extends State<VoiceEmergencyScreen> {
  final SpeechService _speechService = SpeechService();
  final LocationService _locationService = LocationService();
  final ClassificationService _classifier = ClassificationService();
  final PriorityService _prioritizer = PriorityService();

  final TextEditingController _transcriptController = TextEditingController();
  String _listeningStatus = "Tap microphone to speak your emergency message.";
  bool _isListening = false;
  
  String _previewCategory = AppCategories.general;
  String _previewPriority = AppPriorities.low;
  double? _latitude;
  double? _longitude;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _fetchGpsLocation();
    _startVoiceRecognition();
  }

  Future<void> _fetchGpsLocation() async {
    setState(() => _isLoadingGps = true);
    final loc = await _locationService.getCurrentLocation();
    setState(() {
      _isLoadingGps = false;
      _latitude = loc.latitude ?? 11.02345;
      _longitude = loc.longitude ?? 76.96231;
    });
  }

  Future<void> _startVoiceRecognition() async {
    setState(() => _isListening = true);

    await _speechService.startListening(
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _transcriptController.text = text;
          _updatePreviews(text);
        });
      },
      onStatusChange: (status) {
        if (!mounted) return;
        setState(() {
          _listeningStatus = status;
          if (status.contains("done") || status.contains("notListening")) {
            _isListening = false;
          }
        });
      },
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      if (mounted) {
        setState(() {
          _isListening = false;
          _listeningStatus = "Voice recording paused. Tap Mic to record.";
        });
      }
    } else {
      await _startVoiceRecognition();
    }
  }

  void _updatePreviews(String text) {
    setState(() {
      _previewCategory = _classifier.classifyMessage(text);
      _previewPriority = _prioritizer.calculatePriority(_previewCategory, text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("🎙️ Voice Emergency", style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header & Mic Toggle Button
            InkWell(
              onTap: _toggleListening,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isListening ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isListening ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isListening ? AppColors.primary : AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_off,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isListening ? "🎙️ Listening... (Tap to Pause)" : "🎙️ Tap Mic to Record Voice",
                            style: TextStyle(
                              color: _isListening ? AppColors.primaryGlow : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _listeningStatus,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isListening ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppColors.primaryGlow, size: 32),
                      onPressed: _toggleListening,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Transcript Display & Edit Area
            const Text(
              "Emergency Message (Speech-to-Text):",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transcriptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              onChanged: _updatePreviews,
              decoration: InputDecoration(
                hintText: "Speak clearly into the microphone (e.g. 'I am trapped and I need medical help.')...",
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

            // Live Classifier Preview Cards
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
                          _previewCategory,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                        const Text("Assigned Priority", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        PriorityBadge(priority: _previewPriority),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // GPS Coordinates Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("GPS Coordinates (Offline)", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        Text(
                          _isLoadingGps ? "Acquiring satellite lock..." : "Lat: ${_latitude?.toStringAsFixed(5)}, Lng: ${_longitude?.toStringAsFixed(5)}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Confirm & Review Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_transcriptController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please speak or type an emergency message.")),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateSosScreen(
                        user: widget.user,
                        initialMessage: _transcriptController.text.trim(),
                        initialLat: _latitude ?? 11.02345,
                        initialLng: _longitude ?? 76.96231,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Confirm & Review SOS Alert ➔",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
