import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final voiceServiceProvider = Provider((ref) => VoiceService());

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Function(String)? _onStatusCallback;
  Function(String)? _onErrorCallback;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // Request permission first
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }

    try {
      _isInitialized = await _speech.initialize(
        onError: (e) {
          print('Voice Error: $e');
          _onErrorCallback?.call(e.errorMsg);
        },
        onStatus: (s) {
          print('Voice Status: $s');
          _onStatusCallback?.call(s);
        },
      );
      return _isInitialized;
    } catch (e) {
      print('Failed to initialize speech: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onStatus,
    Function(String)? onError,
  }) async {
    _onStatusCallback = onStatus;
    _onErrorCallback = onError;

    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        onStatus('Permission Denied');
        return;
      }
    }

    if (_speech.isListening) return;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: false,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
    
    onStatus('Listening...');
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  bool get isListening => _speech.isListening;
}
