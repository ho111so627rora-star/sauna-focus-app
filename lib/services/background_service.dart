import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/audio_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Timer? _backgroundTimer;
  Timer? _audioCheckTimer;
  DateTime? _lastUpdateTime;
  int _totalElapsedSeconds = 0;
  bool _isRunning = false;
  final AudioService _audioService = AudioService();

  // バックグラウンド処理を開始
  void startBackgroundProcessing() {
    if (_isRunning) return;
    
    _isRunning = true;
    _lastUpdateTime = DateTime.now();
    _totalElapsedSeconds = 0;
    
    _backgroundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRunning) {
        _totalElapsedSeconds++;
        print('バックグラウンド処理: 経過時間 = ${_totalElapsedSeconds}秒');
      }
    });
    
    // 電源オフ時の音源監視を開始
    _audioCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isRunning) {
        _ensureAudioContinuity();
      }
    });
    
    print('バックグラウンド処理を開始しました');
  }

  // バックグラウンド処理を停止
  void stopBackgroundProcessing() {
    _isRunning = false;
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _audioCheckTimer?.cancel();
    _audioCheckTimer = null;
    _lastUpdateTime = null;
    _totalElapsedSeconds = 0;
    
    print('バックグラウンド処理を停止しました');
  }

  // 経過時間を取得
  int get elapsedSeconds => _totalElapsedSeconds;

  // 処理が実行中かどうか
  bool get isRunning => _isRunning;

  // 最後の更新時間を取得
  DateTime? get lastUpdateTime => _lastUpdateTime;

      // 電源オフ時の音源継続を保証
    void _ensureAudioContinuity() {
      try {
        print('=== 電源オフ時音源継続チェックを開始 ===');
        
        // AudioServiceの音源状態を確認
        // 音源が停止している場合は再開を試行
        _audioService.ensurePersistentAudio();
        
        print('=== 電源オフ時音源継続チェックが完了しました ===');
      } catch (e) {
        print('電源オフ時の音源継続チェックでエラーが発生しました: $e');
      }
    }
} 