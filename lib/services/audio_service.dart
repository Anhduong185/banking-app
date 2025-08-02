import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _audioPlayer;
  FlutterTts? _flutterTts;
  bool _isPlaying = false;

  // Khởi tạo AudioPlayer và TTS
  Future<void> initialize() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
      
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage("vi-VN");
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);
      
      print('Audio service đã được khởi tạo');
    } catch (e) {
      print('Lỗi khởi tạo audio service: $e');
    }
  }

  // Phát âm thanh thông báo nhận tiền
  Future<void> playMoneyNotificationSound() async {
    try {
      if (_audioPlayer == null) {
        await initialize();
      }

      if (_isPlaying) {
        await _audioPlayer!.stop();
      }

      // Tạo âm thanh beep đơn giản
      await _playSimpleTone();

    } catch (e) {
      print('Lỗi khi phát âm thanh: $e');
    }
  }

  // Tạo âm thanh đơn giản
  Future<void> _playSimpleTone() async {
    try {
      // Tạo âm thanh beep bằng cách sử dụng file WAV
      await _audioPlayer!.play(AssetSource('sounds/beep.wav'));
      _isPlaying = true;
      
      Timer(const Duration(milliseconds: 800), () {
        _audioPlayer!.stop();
        _isPlaying = false;
      });
    } catch (e) {
      print('Không thể phát âm thanh: $e');
      // Fallback: chỉ hiển thị thông báo
      _isPlaying = true;
      
      Timer(const Duration(milliseconds: 500), () {
        _audioPlayer!.stop();
        _isPlaying = false;
      });
    }
  }

  // Phát âm thanh với tần số và thời gian tùy chỉnh
  Future<void> playCustomTone({
    required double frequency,
    required int durationMs,
    double volume = 1.0,
  }) async {
    try {
      if (_audioPlayer == null) {
        await initialize();
      }

      // Sử dụng âm thanh beep đơn giản
      await _audioPlayer!.play(AssetSource('sounds/beep.wav'));
      await _audioPlayer!.setVolume(volume);
      
      _isPlaying = true;
      
      Timer(Duration(milliseconds: durationMs), () {
        _audioPlayer!.stop();
        _isPlaying = false;
      });
    } catch (e) {
      print('Lỗi khi phát âm thanh tùy chỉnh: $e');
    }
  }

  // Phát âm thanh thông báo với thông tin số tiền
  Future<void> playAmountNotification(double amount) async {
    try {
      // Chỉ đọc số tiền, không phát beep
      await _speakAmount(amount);
    } catch (e) {
      print('Lỗi khi phát thông báo số tiền: $e');
    }
  }

  // Đọc số tiền bằng text-to-speech
  Future<void> _speakAmount(double amount) async {
    try {
      if (_flutterTts == null) {
        await initialize();
      }

      // Chuyển đổi số tiền thành text tiếng Việt
      String amountText = _convertAmountToVietnamese(amount);
      String message = 'Bạn vừa nhận được $amountText';
      
      await _flutterTts!.speak(message);
      print('Đang đọc: $message');
    } catch (e) {
      print('Lỗi khi đọc số tiền: $e');
    }
  }

  // Chuyển đổi số tiền sang tiếng Việt
  String _convertAmountToVietnamese(double amount) {
    if (amount < 1000) {
      return '${amount.toInt()} đồng';
    } else if (amount < 1000000) {
      double thousands = amount / 1000;
      return '${thousands.toStringAsFixed(0)} nghìn đồng';
    } else if (amount < 1000000000) {
      double millions = amount / 1000000;
      return '${millions.toStringAsFixed(1)} triệu đồng';
    } else {
      double billions = amount / 1000000000;
      return '${billions.toStringAsFixed(1)} tỷ đồng';
    }
  }

  // Phát thông báo đầy đủ với tên người gửi và số tiền
  Future<void> playFullNotification({
    required String senderName,
    required double amount,
  }) async {
    try {
      // Chỉ đọc thông báo đầy đủ, không phát beep
      if (_flutterTts == null) {
        await initialize();
      }

      String amountText = _convertAmountToVietnamese(amount);
      String message = 'Bạn vừa nhận được $amountText từ $senderName';
      
      await _flutterTts!.speak(message);
      print('Đang đọc thông báo đầy đủ: $message');
    } catch (e) {
      print('Lỗi khi phát thông báo đầy đủ: $e');
    }
  }

  // Dừng phát âm thanh
  Future<void> stop() async {
    try {
      await _audioPlayer?.stop();
      await _flutterTts?.stop();
      _isPlaying = false;
    } catch (e) {
      print('Lỗi khi dừng âm thanh: $e');
    }
  }

  // Kiểm tra trạng thái phát
  bool get isPlaying => _isPlaying;

  // Giải phóng tài nguyên
  Future<void> dispose() async {
    await _audioPlayer?.dispose();
    await _flutterTts?.stop();
    _audioPlayer = null;
    _flutterTts = null;
    _isPlaying = false;
  }
} 