import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_record.dart';
import '../services/background_service.dart';
import '../services/audio_service.dart';

enum SessionPhase {
  home,
  sauna,
  lowryu,
  coldBath,
  airBath,
  completed,
}

class SessionProvider extends ChangeNotifier {
  SessionPhase _currentPhase = SessionPhase.home;
  SessionPhase get currentPhase => _currentPhase;

  int _saunaDuration = 25; // デフォルト25分
  int get saunaDuration => _saunaDuration;
  
  int _coldBathDuration = 5; // デフォルト5分
  int get coldBathDuration => _coldBathDuration;
  
  int _airBathDuration = 5; // デフォルト5分
  int get airBathDuration => _airBathDuration;

  DateTime? _sessionStartTime;
  DateTime? get sessionStartTime => _sessionStartTime;

  int _remainingTime = 0;
  int get remainingTime => _remainingTime;

  bool _isTimerRunning = false;
  bool get isTimerRunning => _isTimerRunning;

  List<SessionRecord> _sessionHistory = [];
  List<SessionRecord> get sessionHistory => _sessionHistory;

  String? _currentDiaryEntry;
  String? get currentDiaryEntry => _currentDiaryEntry;
  
  String? _currentReflection;
  String? get currentReflection => _currentReflection;
  
  bool _isLowryuMode = false;
  bool get isLowryuMode => _isLowryuMode;

  int _setCount = 1;
  int get setCount => _setCount;
  
  int _currentSet = 1;
  int get currentSet => _currentSet;

  // 詳細なセッション記録用
  List<SetRecord> _currentSetRecords = [];
  List<SetRecord> get currentSetRecords => _currentSetRecords;
  DateTime? _currentPhaseStartTime;
  int _currentPhaseInitialTime = 0;
  bool _currentSetUsedLowryu = false;

  // セッション開始
  void startSession() {
    print('セッション開始: 前回のデータをクリア中...');
    
    // 前回のセッションデータをクリア
    _currentSetRecords = [];
    _currentPhaseStartTime = null;
    _currentPhaseInitialTime = 0;
    _currentSetUsedLowryu = false;
    _currentDiaryEntry = null;
    _currentReflection = null;
    
    // セッション完了フラグをリセット
    AudioService().resetSessionCompleteFlag();
    
    print('セッション開始: 新しいセッションを初期化中...');
    print('セッション開始: セット数 = $_setCount, 現在のセット = 1');
    _sessionStartTime = DateTime.now();
    _currentPhase = SessionPhase.sauna;
    _remainingTime = _saunaDuration * 60; // 秒に変換
    _isTimerRunning = true;
    _isLowryuMode = false;
    _currentSet = 1;
    _currentPhaseStartTime = DateTime.now();
    _currentPhaseInitialTime = _saunaDuration * 60;
    
    // バックグラウンド処理を開始
    BackgroundService().startBackgroundProcessing();
    
    print('セッション開始: フェーズ = $_currentPhase, 残り時間 = $_remainingTime秒, セット = $_currentSet/$_setCount');
    notifyListeners();
  }

  // タイマー更新
  void updateTimer() {
    if (!_isTimerRunning) {
      return;
    }

    // 残り時間はフェーズ開始時刻からの実経過時間で計算する
    // （1秒ごとに減らす方式だと、バックグラウンドやタブ非表示でタイマーが間引かれた時にずれるため）
    if (_currentPhaseStartTime != null) {
      final elapsedSeconds = DateTime.now().difference(_currentPhaseStartTime!).inSeconds;
      _remainingTime = max(0, _currentPhaseInitialTime - elapsedSeconds);
    }

    // ロウリュタイミング（残り5分）- 自動的にロウリュウモードに移行
    if (_currentPhase == SessionPhase.sauna &&
        !_isLowryuMode &&
        _currentPhaseInitialTime > 300 &&
        _remainingTime > 0 &&
        _remainingTime <= 300) {
      // startLowryu()を呼んでサウナ時間を記録してからロウリュウモードに移行
      startLowryu();
      return;
    }

    if (_remainingTime > 0) {
      notifyListeners();
      return;
    }

    // 残り時間が0になったら次のフェーズへ
    _advancePhase();
  }

  // 現在のフェーズを終了して次のフェーズへ進む
  void _advancePhase() {
    // ロウリュウモードの場合はfinishLowryu()を呼ぶ
    if (_currentPhase == SessionPhase.lowryu || _isLowryuMode) {
      finishLowryu();
      return;
    }

    switch (_currentPhase) {
      case SessionPhase.sauna:
        _recordPhaseCompletion();
        _currentPhase = SessionPhase.coldBath;
        _remainingTime = _coldBathDuration * 60;
        _currentPhaseStartTime = DateTime.now();
        _currentPhaseInitialTime = _coldBathDuration * 60;
        notifyListeners();
        break;
      case SessionPhase.coldBath:
        _recordPhaseCompletion();
        _currentPhase = SessionPhase.airBath;
        _remainingTime = _airBathDuration * 60;
        _currentPhaseStartTime = DateTime.now();
        _currentPhaseInitialTime = _airBathDuration * 60;
        notifyListeners();
        break;
      case SessionPhase.airBath:
        _recordPhaseCompletion();
        print('外気浴終了: 現在のセット = $_currentSet, セット数 = $_setCount');
        if (_currentSet < _setCount) {
          print('次のセットに進みます: $_currentSet → ${_currentSet + 1}');
          nextSet();
        } else {
          print('最後のセットなのでセッション完了します');
          _completeSession();
        }
        break;
      default:
        break;
    }
  }

  // バックグラウンド復帰時の時間補正
  void correctTimerOnResume() {
    if (_currentPhaseStartTime != null && _isTimerRunning) {
      final now = DateTime.now();
      final elapsedTime = now.difference(_currentPhaseStartTime!);
      final elapsedSeconds = elapsedTime.inSeconds;
      
      print('バックグラウンド復帰時の時間補正:');
      print('経過時間: ${elapsedSeconds}秒');
      print('初期時間: ${_currentPhaseInitialTime}秒');
      print('現在の残り時間: $_remainingTime秒');
      
      // 実際に経過した時間に基づいて残り時間を計算
      final actualRemainingTime = _currentPhaseInitialTime - elapsedSeconds;
      
      if (actualRemainingTime > 0) {
        _remainingTime = actualRemainingTime;
        print('補正後の残り時間: $_remainingTime秒');
      } else {
        // 時間が過ぎている場合は0に設定
        _remainingTime = 0;
        print('時間が過ぎているため、残り時間を0に設定');
      }
      
      notifyListeners();
    }
  }

  // フェーズ完了を記録
  void _recordPhaseCompletion() {
    if (_currentPhaseStartTime != null) {
      // 実際の経過時間を計算（秒単位で計算してから分に変換）
      final actualTimeSeconds = DateTime.now().difference(_currentPhaseStartTime!).inSeconds;
      final actualMinutes = (actualTimeSeconds / 60).ceil(); // 秒を分に変換（切り上げ）
      
      // 現在のセットレコードを更新または作成
      SetRecord? currentSetRecord;
      if (_currentSetRecords.isNotEmpty && _currentSetRecords.last.setNumber == _currentSet) {
        currentSetRecord = _currentSetRecords.last;
      }
      
      if (currentSetRecord == null) {
        // 新しいセットレコードを作成
        currentSetRecord = SetRecord(
          setNumber: _currentSet,
          actualSaunaTime: 0,
          actualColdBathTime: 0,
          actualAirBathTime: 0,
          usedLowryu: _currentSetUsedLowryu,
          lowryuTime: 0, // 初期値は0、実際の時間は後で計算
          diaryEntry: _currentDiaryEntry,
          reflection: _currentReflection,
        );
        _currentSetRecords.add(currentSetRecord);
      }
      
      // フェーズに応じて時間を記録
      switch (_currentPhase) {
        case SessionPhase.sauna:
          currentSetRecord = SetRecord(
            setNumber: currentSetRecord.setNumber,
            actualSaunaTime: actualMinutes,
            actualColdBathTime: currentSetRecord.actualColdBathTime,
            actualAirBathTime: currentSetRecord.actualAirBathTime,
            usedLowryu: currentSetRecord.usedLowryu,
            lowryuTime: currentSetRecord.lowryuTime,
            diaryEntry: currentSetRecord.diaryEntry,
            reflection: currentSetRecord.reflection,
          );
          break;
        case SessionPhase.coldBath:
          currentSetRecord = SetRecord(
            setNumber: currentSetRecord.setNumber,
            actualSaunaTime: currentSetRecord.actualSaunaTime,
            actualColdBathTime: actualMinutes,
            actualAirBathTime: currentSetRecord.actualAirBathTime,
            usedLowryu: currentSetRecord.usedLowryu,
            lowryuTime: currentSetRecord.lowryuTime,
            diaryEntry: currentSetRecord.diaryEntry,
            reflection: currentSetRecord.reflection,
          );
          break;
        case SessionPhase.airBath:
          currentSetRecord = SetRecord(
            setNumber: currentSetRecord.setNumber,
            actualSaunaTime: currentSetRecord.actualSaunaTime,
            actualColdBathTime: currentSetRecord.actualColdBathTime,
            actualAirBathTime: actualMinutes,
            usedLowryu: currentSetRecord.usedLowryu,
            lowryuTime: currentSetRecord.lowryuTime,
            diaryEntry: _currentDiaryEntry, // 外気浴で日記を保存
            reflection: _currentReflection, // 外気浴で振り返りを保存
          );
          break;
        default:
          break;
      }
      
      // レコードを更新
      if (_currentSetRecords.isNotEmpty) {
        _currentSetRecords[_currentSetRecords.length - 1] = currentSetRecord;
      }
    }
  }

  // ロウリュウモード開始
  void startLowryu() {
    _isLowryuMode = true;
    _currentSetUsedLowryu = true;
    
    // ロウリュウ開始前のサウナ時間を記録（秒単位で計算してから分に変換）
    if (_currentPhaseStartTime != null) {
      final saunaDurationSeconds = DateTime.now().difference(_currentPhaseStartTime!).inSeconds;
      final saunaDurationMinutes = (saunaDurationSeconds / 60).ceil(); // 秒を分に変換（切り上げ）
      
      print('ロウリュウ開始: サウナ時間計算: ${saunaDurationSeconds}秒 = ${saunaDurationMinutes}分');
      
      // 現在のセットレコードを更新または作成してサウナ時間を記録
      SetRecord? currentSetRecord;
      if (_currentSetRecords.isNotEmpty && _currentSetRecords.last.setNumber == _currentSet) {
        currentSetRecord = _currentSetRecords.last;
      }
      
      if (currentSetRecord == null) {
        // 新しいセットレコードを作成
        currentSetRecord = SetRecord(
          setNumber: _currentSet,
          actualSaunaTime: saunaDurationMinutes,
          actualColdBathTime: 0,
          actualAirBathTime: 0,
          usedLowryu: true,
          lowryuTime: 0, // ロウリュウ時間は後で計算
          diaryEntry: _currentDiaryEntry,
          reflection: _currentReflection,
        );
        _currentSetRecords.add(currentSetRecord);
        print('ロウリュウ開始: 新しいセットレコードを作成しました（サウナ時間: ${saunaDurationMinutes}分）');
      } else {
        // 既存のセットレコードを更新
        _currentSetRecords[_currentSetRecords.length - 1] = SetRecord(
          setNumber: currentSetRecord.setNumber,
          actualSaunaTime: saunaDurationMinutes,
          actualColdBathTime: currentSetRecord.actualColdBathTime,
          actualAirBathTime: currentSetRecord.actualAirBathTime,
          usedLowryu: true,
          lowryuTime: 0, // ロウリュウ時間は後で計算
          diaryEntry: currentSetRecord.diaryEntry,
          reflection: currentSetRecord.reflection,
        );
        print('ロウリュウ開始: 既存のセットレコードを更新しました（サウナ時間: ${saunaDurationMinutes}分）');
      }
    } else {
      print('警告: _currentPhaseStartTimeがnullです。サウナ時間を記録できません。');
    }
    
    _currentPhase = SessionPhase.lowryu; // フェーズをロウリュウに変更
    _remainingTime = 5 * 60; // 5分に設定
    _currentPhaseStartTime = DateTime.now();
    _currentPhaseInitialTime = 5 * 60;
    notifyListeners();
  }

  // ロウリュウモード終了
  void finishLowryu() {
    _isLowryuMode = false;
    
    // ロウリュウモードで実際に過ごした時間を計算（秒単位で計算してから分に変換）
    if (_currentPhaseStartTime != null) {
      final lowryuDurationSeconds = DateTime.now().difference(_currentPhaseStartTime!).inSeconds;
      final lowryuDurationMinutes = (lowryuDurationSeconds / 60).ceil(); // 秒を分に変換（切り上げ）
      
      print('ロウリュウ時間計算: ${lowryuDurationSeconds}秒 = ${lowryuDurationMinutes}分');
      
      // 現在のセットレコードを更新してロウリュウ時間を記録
      if (_currentSetRecords.isNotEmpty) {
        final lastRecord = _currentSetRecords.last;
        _currentSetRecords[_currentSetRecords.length - 1] = SetRecord(
          setNumber: lastRecord.setNumber,
          actualSaunaTime: lastRecord.actualSaunaTime, // サウナ時間は既に記録済み
          actualColdBathTime: lastRecord.actualColdBathTime,
          actualAirBathTime: lastRecord.actualAirBathTime,
          usedLowryu: true,
          lowryuTime: lowryuDurationMinutes, // ロウリュウ時間を記録
          diaryEntry: lastRecord.diaryEntry,
          reflection: lastRecord.reflection,
        );
        print('ロウリュウ時間を記録しました: ${lowryuDurationMinutes}分');
      } else {
        print('警告: セットレコードが見つかりません');
      }
    } else {
      print('警告: _currentPhaseStartTimeがnullです');
    }
    
    _currentPhase = SessionPhase.coldBath;
    _remainingTime = _coldBathDuration * 60;
    _currentPhaseStartTime = DateTime.now();
    _currentPhaseInitialTime = _coldBathDuration * 60;
    notifyListeners();
  }

  // セッション完了
  void _completeSession() {
    _isTimerRunning = false;
    _currentPhase = SessionPhase.completed;
    
    // バックグラウンド処理を停止
    BackgroundService().stopBackgroundProcessing();
    
    // セッション完了専用の最強音源停止を確実に実行
    AudioService().stopAudioOnSessionComplete();
    print('セッション完了: セッション完了専用音源停止を実行しました');
    
    if (_sessionStartTime != null) {
      // 総集中時間を計算
      int totalActualTime = 0;
      for (var setRecord in _currentSetRecords) {
        totalActualTime += setRecord.totalTime;
      }
      
      final sessionRecord = SessionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: _sessionStartTime!,
        endTime: DateTime.now(),
        saunaDuration: _saunaDuration,
        coldBathDuration: _coldBathDuration,
        airBathDuration: _airBathDuration,
        diaryEntry: _currentDiaryEntry,
        reflection: _currentReflection,
        usedLowryu: _currentSetRecords.any((set) => set.usedLowryu),
        totalFocusTime: totalActualTime,
        setRecords: List.from(_currentSetRecords),
      );
      
      _sessionHistory.add(sessionRecord);
      _saveSessionHistory();
    }
    
    // セッション完了後、新しいセッションのためにデータをクリア
    _currentSetRecords = [];
    _currentPhaseStartTime = null;
    _currentPhaseInitialTime = 0;
    _currentSetUsedLowryu = false;
    _currentDiaryEntry = null;
    _currentReflection = null;
    

    notifyListeners();
  }

  // 日記エントリー更新
  void updateDiaryEntry(String entry) {
    _currentDiaryEntry = entry;
    notifyListeners();
  }

  // 振り返り更新
  void updateReflection(String reflection) {
    _currentReflection = reflection;
    notifyListeners();
  }

  // セッションリセット
  void resetSession() {
    print('セッションリセット: ホーム画面に戻ります');
    
    // 最初にセッション完了専用音源停止
    AudioService().stopAudioOnSessionComplete();
    print('セッション完了専用音源停止を実行しました');
    
    // セッション完了フラグをリセット
    AudioService().resetSessionCompleteFlag();
    
    _currentPhase = SessionPhase.home;
    _sessionStartTime = null;
    _remainingTime = 0;
    _isTimerRunning = false;
    _currentDiaryEntry = null;
    _currentReflection = null;
    _currentSet = 1;
    _isLowryuMode = false;
    _currentSetRecords = [];
    _currentPhaseStartTime = null;
    _currentPhaseInitialTime = 0;
    _currentSetUsedLowryu = false;
    
    // バックグラウンド処理を停止
    BackgroundService().stopBackgroundProcessing();
    
    print('セッションリセット: フェーズ = $_currentPhase');
    // 即座に通知して確実にホーム画面に戻る
    notifyListeners();
  }

  // 時間設定更新
  void updateDurations({
    int? saunaDuration,
    int? coldBathDuration,
    int? airBathDuration,
  }) {
    if (saunaDuration != null) _saunaDuration = saunaDuration;
    if (coldBathDuration != null) _coldBathDuration = coldBathDuration;
    if (airBathDuration != null) _airBathDuration = airBathDuration;
    notifyListeners();
  }

  // セット数更新
  void updateSetCount(int setCount) {
    print('セット数更新: $_setCount → $setCount');
    _setCount = setCount;
    notifyListeners();
  }

  // 次のセットに進む
  void nextSet() {
    print('nextSet()呼び出し: 現在のセット = $_currentSet, セット数 = $_setCount');
    if (_currentSet < _setCount) {
      _currentSet++;
      print('次のセットに進みました: セット $_currentSet/$_setCount');
      _currentPhase = SessionPhase.sauna;
      _remainingTime = _saunaDuration * 60;
      _isTimerRunning = true;
      _isLowryuMode = false;
      _currentPhaseStartTime = DateTime.now();
      _currentPhaseInitialTime = _saunaDuration * 60;
      _currentSetUsedLowryu = false;
      // 前のセットの日記・振り返りが次のセットに引き継がれないようにクリア
      _currentDiaryEntry = null;
      _currentReflection = null;
      notifyListeners();
    } else {
      print('nextSet()内: 最後のセットなのでセッション完了します');
      _completeSession();
    }
  }

  // 次のフェーズにスキップ
  void skipToNextPhase() {
    _advancePhase();
  }

  // セッション履歴をローカルストレージに保存
  Future<void> _saveSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _sessionHistory.map((record) => record.toJson()).toList();
      await prefs.setString('session_history', jsonEncode(historyJson));
    } catch (e) {
      print('セッション履歴の保存に失敗しました: $e');
    }
  }

  // セッション履歴をローカルストレージから読み込み
  Future<void> loadSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyString = prefs.getString('session_history');
      
      if (historyString != null) {
        final historyJson = jsonDecode(historyString) as List;
        _sessionHistory = historyJson
            .map((json) => SessionRecord.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('セッション履歴の読み込みに失敗しました: $e');
    }
  }

  // 残り時間を分:秒形式で取得
  String get remainingTimeString {
    final minutes = _remainingTime ~/ 60;
    final seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
} 