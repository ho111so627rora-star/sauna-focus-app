import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSettingsProvider extends ChangeNotifier {
  bool _isAudioEnabled = true;
  bool get isAudioEnabled => _isAudioEnabled;

  double _volume = 0.7; // デフォルト音量70%
  double get volume => _volume;

  bool _isSaunaAudioEnabled = true;
  bool get isSaunaAudioEnabled => _isSaunaAudioEnabled;

  bool _isColdBathAudioEnabled = true;
  bool get isColdBathAudioEnabled => _isColdBathAudioEnabled;

  bool _isAirBathAudioEnabled = true;
  bool get isAirBathAudioEnabled => _isAirBathAudioEnabled;

  bool _isLowryuAudioEnabled = true;
  bool get isLowryuAudioEnabled => _isLowryuAudioEnabled;

  bool _isCompletionAudioEnabled = true;
  bool get isCompletionAudioEnabled => _isCompletionAudioEnabled;

  AudioSettingsProvider() {
    _loadSettings();
  }

  // 設定をローカルストレージから読み込み
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAudioEnabled = prefs.getBool('isAudioEnabled') ?? true;
      _volume = prefs.getDouble('volume') ?? 0.7;
      _isSaunaAudioEnabled = prefs.getBool('isSaunaAudioEnabled') ?? true;
      _isColdBathAudioEnabled = prefs.getBool('isColdBathAudioEnabled') ?? true;
      _isAirBathAudioEnabled = prefs.getBool('isAirBathAudioEnabled') ?? true;
      _isLowryuAudioEnabled = prefs.getBool('isLowryuAudioEnabled') ?? true;
      _isCompletionAudioEnabled = prefs.getBool('isCompletionAudioEnabled') ?? true;
      notifyListeners();
    } catch (e) {
      print('音声設定の読み込みに失敗しました: $e');
    }
  }

  // 設定をローカルストレージに保存
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAudioEnabled', _isAudioEnabled);
      await prefs.setDouble('volume', _volume);
      await prefs.setBool('isSaunaAudioEnabled', _isSaunaAudioEnabled);
      await prefs.setBool('isColdBathAudioEnabled', _isColdBathAudioEnabled);
      await prefs.setBool('isAirBathAudioEnabled', _isAirBathAudioEnabled);
      await prefs.setBool('isLowryuAudioEnabled', _isLowryuAudioEnabled);
      await prefs.setBool('isCompletionAudioEnabled', _isCompletionAudioEnabled);
    } catch (e) {
      print('音声設定の保存に失敗しました: $e');
    }
  }

  // 音声全体のON/OFF切り替え
  void toggleAudio() {
    _isAudioEnabled = !_isAudioEnabled;
    _saveSettings();
    notifyListeners();
  }

  // 音量調整
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _saveSettings();
    notifyListeners();
  }

  // サウナ音声のON/OFF切り替え
  void toggleSaunaAudio() {
    _isSaunaAudioEnabled = !_isSaunaAudioEnabled;
    _saveSettings();
    notifyListeners();
  }

  // 水風呂音声のON/OFF切り替え
  void toggleColdBathAudio() {
    _isColdBathAudioEnabled = !_isColdBathAudioEnabled;
    _saveSettings();
    notifyListeners();
  }

  // 外気浴音声のON/OFF切り替え
  void toggleAirBathAudio() {
    _isAirBathAudioEnabled = !_isAirBathAudioEnabled;
    _saveSettings();
    notifyListeners();
  }

  // ロウリュウ音声のON/OFF切り替え
  void toggleLowryuAudio() {
    _isLowryuAudioEnabled = !_isLowryuAudioEnabled;
    _saveSettings();
    notifyListeners();
  }

  // 完了音声のON/OFF切り替え
  void toggleCompletionAudio() {
    _isCompletionAudioEnabled = !_isCompletionAudioEnabled;
    _saveSettings();
    notifyListeners();
  }

  // 実際の音量を取得（音声が無効の場合は0）
  double getEffectiveVolume() {
    return _isAudioEnabled ? _volume : 0.0;
  }

  // 特定の音声が再生可能かチェック
  bool canPlaySaunaAudio() {
    return _isAudioEnabled && _isSaunaAudioEnabled;
  }

  bool canPlayColdBathAudio() {
    return _isAudioEnabled && _isColdBathAudioEnabled;
  }

  bool canPlayAirBathAudio() {
    return _isAudioEnabled && _isAirBathAudioEnabled;
  }

  bool canPlayLowryuAudio() {
    return _isAudioEnabled && _isLowryuAudioEnabled;
  }

  bool canPlayCompletionAudio() {
    return _isAudioEnabled && _isCompletionAudioEnabled;
  }
} 