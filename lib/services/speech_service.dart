import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    try {
      // Explicitly request microphone permission on mobile devices
      if (!kIsWeb) {
        var status = await Permission.microphone.status;
        if (!status.isGranted) {
          status = await Permission.microphone.request();
          if (!status.isGranted) {
            if (kDebugMode) print('Microphone permission denied.');
            _isAvailable = false;
            return false;
          }
        }
      }

      _isAvailable = await _speech.initialize(
        onError: (val) {
          if (kDebugMode) print('SpeechError: ${val.errorMsg}');
          _isListening = false;
        },
        onStatus: (val) {
          if (kDebugMode) print('SpeechStatus: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isAvailable;
    } catch (e) {
      if (kDebugMode) print('SpeechService init exception: $e');
      _isAvailable = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    required Function(String status) onStatusChange,
  }) async {
    try {
      // Force clean stop of any existing session before starting
      await stopListening();
      
      bool initSuccess = await initialize();
      if (!initSuccess) {
        onStatusChange("Microphone permission or Speech service unavailable.");
        return;
      }

      _isListening = true;
      onStatusChange("Listening... Speak your emergency details clearly.");

      String localeId = 'en_US';
      try {
        final systemLocale = await _speech.systemLocale();
        if (systemLocale != null) {
          localeId = systemLocale.localeId;
        }
      } catch (_) {}

      await _speech.listen(
        onResult: (val) {
          if (val.recognizedWords.isNotEmpty) {
            onResult(val.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 6),
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Speech listen exception: $e');
      onStatusChange("Voice recording paused. Tap Mic to record again.");
      _isListening = false;
      _isAvailable = false;
    }
  }

  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
    _isListening = false;
  }
}
