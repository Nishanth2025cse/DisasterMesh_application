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
    if (!_isAvailable) {
      bool initSuccess = await initialize();
      if (!initSuccess) {
        onStatusChange("Microphone permission or Speech service unavailable.");
        return;
      }
    }

    _isListening = true;
    onStatusChange("Listening... Speak your emergency details.");

    try {
      final systemLocale = await _speech.systemLocale();
      final localeId = systemLocale?.localeId ?? 'en_US';

      await _speech.listen(
        onResult: (val) {
          onResult(val.recognizedWords);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Speech listen exception: $e');
      onStatusChange("Voice recording error: $e");
      _isListening = false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
}
