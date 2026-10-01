import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../providers/audio_settings_provider.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer(); // エフェクト音用の別プレイヤー
  bool _isInitialized = false;
  bool _isSessionComplete = false; // セッション完了フラグ

  // 現在再生中の環境音（停止中はnull）
  String? _currentAudioSource;
  double _currentVolume = 0.7;

  // 再生・停止の要求ごとに増やす番号。
  // await中に新しい要求が来た場合、古い処理が後から音を鳴らしたり止めたりしないようにする
  int _requestId = 0;

  // 環境音が止まっていないかを監視するタイマー（常に1つだけ）
  Timer? _watchdogTimer;

  // 音声ファイルのパス
  static const String _saunaAmbient = 'audio/sauna_ambient.mp3';
  static const String _coldBathAmbient = 'audio/cold_bath_ambient.mp3';
  static const String _airBathAmbient = 'audio/air_bath_ambient.mp3';
  static const String _lowryuEffect = 'audio/lowryu_effect.mp3'; // ロウリュウエフェクト音

  // 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      // 環境音はプレイヤー側のループ機能でループ再生する
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _effectPlayer.setReleaseMode(ReleaseMode.release);

      if (!kIsWeb) {
        // 画面オフ・バックグラウンドでも再生を続ける設定
        // Android: プレイヤーに PARTIAL_WAKE_LOCK を持たせる（無いと画面オフ中にCPUが眠って音が止まることがある）
        // iOS: .playback カテゴリ（Info.plist の UIBackgroundModes=audio と合わせてバックグラウンド再生）
        final audioContext = AudioContextConfig(stayAwake: true).build();
        await AudioPlayer.global.setAudioContext(audioContext);
        await _audioPlayer.setAudioContext(audioContext);
        await _effectPlayer.setAudioContext(audioContext);
      }
    } catch (e) {
      print('音声の初期化に失敗しました: $e');
    }
  }

  // 電源オフ・バックグラウンド時に環境音が止まった場合に再開する監視を開始
  // （何度呼ばれても監視タイマーは1つだけ）
  Future<void> ensurePersistentAudio() async {
    if (_isSessionComplete || _watchdogTimer != null) return;
    _watchdogTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkAndRestartAudioIfNeeded();
    });
  }

  // アプリがフォアグラウンドに戻った時に環境音を再開
  // 電話・アラーム・Siriなどの割り込みでOS側が再生を止めた場合、プレイヤーの状態は
  // 「再生中」のまま変わらないため監視タイマーでは検知できない。resume()は再生中なら何もしない。
  Future<void> resumeIfNeeded() async {
    if (_isSessionComplete || _currentAudioSource == null) return;
    try {
      await _audioPlayer.setVolume(_currentVolume);
      await _audioPlayer.resume();
    } catch (e) {
      print('環境音の再開に失敗しました: $e');
    }
  }

  // 環境音が止まっていたら再開
  Future<void> _checkAndRestartAudioIfNeeded() async {
    final source = _currentAudioSource;
    if (_isSessionComplete || source == null) return;

    final state = _audioPlayer.state;
    if (state != PlayerState.stopped && state != PlayerState.completed) return;

    final requestId = _requestId;
    try {
      print('環境音が停止しています。再開します: $source');
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_currentVolume);
      if (requestId != _requestId) return;
      await _audioPlayer.play(AssetSource(source));
    } catch (e) {
      print('環境音の再開に失敗しました: $e');
    }
  }

  // 環境音を再生（同じ音源が再生中なら最初からやり直さない）
  Future<void> _playAmbient(String source, double volume) async {
    final requestId = ++_requestId;
    try {
      if (_currentAudioSource == source && _audioPlayer.state == PlayerState.playing) {
        _currentVolume = volume;
        await _audioPlayer.setVolume(volume);
        return;
      }

      // 切り替え中に監視タイマーが古い音源を再開しないようにする
      // （stop()は挟まずにそのまま次の音源へ切り替える。iOSのバックグラウンドでは
      //   無音の時間ができるとアプリが一時停止され、次の音源が鳴らなくなるため）
      _currentAudioSource = null;
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(volume);
      if (requestId != _requestId) return;

      _currentAudioSource = source;
      _currentVolume = volume;
      await _audioPlayer.play(AssetSource(source));
      await ensurePersistentAudio();
    } catch (e) {
      print('環境音の再生に失敗しました ($source): $e');
    }
  }

  // サウナ室の環境音を再生
  Future<void> playSaunaAmbient(AudioSettingsProvider? audioSettings) async {
    if (audioSettings?.canPlaySaunaAudio() == true) {
      await _playAmbient(_saunaAmbient, audioSettings!.getEffectiveVolume());
      print('サウナ環境音を再生中... (音量: ${(_currentVolume * 100).round()}%)');
    } else {
      print('サウナ環境音は無効になっています');
      await stopAudio();
    }
  }

  // 水風呂の環境音を再生
  Future<void> playColdBathAmbient(AudioSettingsProvider? audioSettings) async {
    if (audioSettings?.canPlayColdBathAudio() == true) {
      // 水風呂の音量を1.2倍にする（最大1.0に制限）
      final volume = (audioSettings!.getEffectiveVolume() * 1.2).clamp(0.0, 1.0);
      await _playAmbient(_coldBathAmbient, volume);
      print('水風呂環境音を再生中... (音量: ${(_currentVolume * 100).round()}%)');
    } else {
      print('水風呂環境音は無効になっています');
      await stopAudio();
    }
  }

  // 外気浴の環境音を再生
  Future<void> playAirBathAmbient(AudioSettingsProvider? audioSettings) async {
    if (audioSettings?.canPlayAirBathAudio() == true) {
      await _playAmbient(_airBathAmbient, audioSettings!.getEffectiveVolume());
      print('外気浴環境音を再生中... (音量: ${(_currentVolume * 100).round()}%)');
    } else {
      print('外気浴環境音は無効になっています');
      await stopAudio();
    }
  }

  // ロウリュ中の環境音（サウナ環境音を継続）
  Future<void> playLowryuSound(AudioSettingsProvider? audioSettings) async {
    if (audioSettings?.canPlayLowryuAudio() == true) {
      await _playAmbient(_saunaAmbient, audioSettings!.getEffectiveVolume());
    } else {
      print('ロウリュ音は無効になっています');
    }
  }

  // ロウリュウエフェクト音を再生（一回だけ）
  Future<void> playLowryuEffect(AudioSettingsProvider? audioSettings) async {
    try {
      if (audioSettings?.canPlayLowryuAudio() == true) {
        await _effectPlayer.setVolume(audioSettings!.getEffectiveVolume());
        await _effectPlayer.play(AssetSource(_lowryuEffect));
        print('ロウリュウエフェクト音を再生中... (音量: ${(audioSettings.getEffectiveVolume() * 100).round()}%)');
      } else {
        print('ロウリュウエフェクト音は無効になっています');
      }
    } catch (e) {
      print('ロウリュウエフェクト音の再生に失敗しました: $e');
    }
  }

  // セッション完了音を再生（無音）
  Future<void> playSessionComplete(AudioSettingsProvider? audioSettings) async {
    print('セッション完了: 無音');
    _isSessionComplete = true;
  }

  // 音声を停止
  Future<void> stopAudio() async {
    _requestId++;
    _currentAudioSource = null;
    try {
      await _audioPlayer.stop();
      await _effectPlayer.stop();
    } catch (e) {
      print('音声停止に失敗しました: $e');
    }
  }

  // セッション完了・終了時の停止（監視も止めて自動再開させない）
  Future<void> stopAudioOnSessionComplete() async {
    _isSessionComplete = true;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    await stopAudio();
  }

  // セッション完了フラグをリセット（新しいセッション開始時用）
  void resetSessionCompleteFlag() {
    _isSessionComplete = false;
    _currentVolume = 0.7;
  }

  // 音量設定
  Future<void> setVolume(double volume) async {
    try {
      _currentVolume = volume;
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      print('音量設定に失敗しました: $e');
    }
  }

  // リソース解放
  Future<void> dispose() async {
    try {
      _watchdogTimer?.cancel();
      _watchdogTimer = null;
      await _audioPlayer.dispose();
      await _effectPlayer.dispose();
    } catch (e) {
      print('音声リソースの解放に失敗しました: $e');
    }
  }
}
