import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/audio_settings_provider.dart';
import '../services/audio_service.dart';
import '../services/background_service.dart';

class SaunaScreen extends StatefulWidget {
  const SaunaScreen({super.key});

  @override
  State<SaunaScreen> createState() => _SaunaScreenState();
}

class _SaunaScreenState extends State<SaunaScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late Timer _timer;
  late Timer _clockTimer;
  late AnimationController _breathingController;
  late AnimationController _steamController;
  final AudioService _audioService = AudioService();
  bool _wasLowryuMode = false; // ロウリュウモードへの切り替わりを検知する用

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startTimer();
    
    // アプリのライフサイクルを監視
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audioSettings = context.read<AudioSettingsProvider>();
      print('サウナ画面: 音声設定 = ${audioSettings.isSaunaAudioEnabled}');
      print('サウナ画面: 音量 = ${audioSettings.volume}');
      _audioService.playSaunaAmbient(audioSettings);
    });
  }

  // ロウリュウモード開始時の音（ボタン押下・残り5分の自動移行どちらでも1回だけ鳴らす）
  void _playLowryuAudio() {
    final audioSettings = context.read<AudioSettingsProvider>();
    _audioService.playLowryuSound(audioSettings);
    _audioService.playLowryuEffect(audioSettings);
  }

  void _initializeAnimations() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _steamController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final sessionProvider = context.read<SessionProvider>();
      sessionProvider.updateTimer();
    });
    
    // 時計を1秒ごとに更新（バックグラウンド処理と同期）
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // バックグラウンド処理の経過時間を取得して時計を更新
        final backgroundService = BackgroundService();
        if (backgroundService.isRunning) {
          // バックグラウンド処理が動作中の場合、その経過時間を使用
          print('バックグラウンド処理経過時間: ${backgroundService.elapsedSeconds}秒');
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _clockTimer.cancel();
    _breathingController.dispose();
    _steamController.dispose();
    // 音源の停止・切り替えは次の画面（またはセッション終了処理）で行う。
    // ここで停止すると、次の画面で再生を始めた環境音まで止めてしまうため。
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('サウナ画面: アプリがフォアグラウンドに復帰しました');
        // バックグラウンド復帰時に時間補正を実行
        final sessionProvider = context.read<SessionProvider>();
        sessionProvider.correctTimerOnResume();
        
        // 割り込み（電話など）で止まった環境音を再開
        _audioService.resumeIfNeeded();
        break;
      case AppLifecycleState.paused:
        print('サウナ画面: アプリがバックグラウンドに移行しました');
        // バックグラウンドでもタイマーを継続
        // _timer.cancel(); // タイマーを停止しない
        
        // バックグラウンド移行時に音源の継続を強化
        _audioService.ensurePersistentAudio();
        break;
      case AppLifecycleState.detached:
        print('サウナ画面: アプリが完全に終了しました');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          // ロウリュウモードに切り替わった時だけ音を鳴らす
          // （毎秒の再描画ごとに再生すると音源が先頭から鳴り直してしまう）
          if (sessionProvider.isLowryuMode != _wasLowryuMode) {
            _wasLowryuMode = sessionProvider.isLowryuMode;
            if (_wasLowryuMode) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _playLowryuAudio();
              });
            }
          }
          
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  sessionProvider.isLowryuMode 
                    ? 'assets/images/screens/lowryu_steam.png'
                    : 'assets/images/screens/sauna_room.jpg'
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3), // 半透明のオーバーレイ
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // ヘッダー
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              // resetSession()の中で音源も停止される
                              context.read<SessionProvider>().resetSession();
                            },
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Expanded(
                            child: Consumer<SessionProvider>(
                              builder: (context, sessionProvider, child) {
                                return Text(
                                  'サウナ室 (セット ${sessionProvider.currentSet}/${sessionProvider.setCount})',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 48), // バランス用
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      // タイマー表示
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // アナログ時計（12分間で一周）
                              Consumer<SessionProvider>(
                                builder: (context, sessionProvider, child) {
                                  // セッション開始からの経過時間を計算
                                  final now = DateTime.now();
                                  final sessionStartTime = sessionProvider.sessionStartTime;
                                  int elapsedSeconds = 0;
                                  
                                  if (sessionStartTime != null) {
                                    final difference = now.difference(sessionStartTime);
                                    elapsedSeconds = difference.inSeconds;
                                  }
                                  
                                  // 長針：1分間で1周（1秒 = 6度）- 12の位置からスタート
                                  final minuteAngle = (elapsedSeconds * 6) * (3.14159 / 180);
                                  
                                  // 短針：12分間で1周（1分 = 30度）- 12の位置からスタート
                                  final hourAngle = ((elapsedSeconds / 60.0) * 30) * (3.14159 / 180);
                                  
                                  // デバッグ用：開始時の角度を確認
                                  if (elapsedSeconds == 0) {
                                    print('時計開始: 長針角度 = ${minuteAngle * 180 / 3.14159}°, 短針角度 = ${hourAngle * 180 / 3.14159}°');
                                  }
                                  
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: sessionProvider.isLowryuMode 
                                          ? Colors.orange 
                                          : Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // 時計の数字（1-12）
                                        ...List.generate(12, (index) {
                                          final angle = (index * 30 - 90) * (3.14159 / 180);
                                          final radius = 45.0;
                                          final x = radius * cos(angle);
                                          final y = radius * sin(angle);
                                          
                                          return Positioned(
                                            left: 60 + x - 8,
                                            top: 60 + y - 8,
                                            child: Text(
                                              '${index == 0 ? 12 : index}',
                                              style: TextStyle(
                                                color: sessionProvider.isLowryuMode 
                                                  ? Colors.orange 
                                                  : Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }),
                                        
                                        // 短針（12分間で1周）- 中心から指す方向のみ
                                        Transform.rotate(
                                          angle: hourAngle,
                                          child: Container(
                                            width: 4,
                                            height: 25,
                                            decoration: BoxDecoration(
                                              color: sessionProvider.isLowryuMode 
                                                ? Colors.orange 
                                                : Colors.white,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                        
                                        // 長針（1分間で1周）- 中心から指す方向のみ
                                        Transform.rotate(
                                          angle: minuteAngle,
                                          child: Container(
                                            width: 2,
                                            height: 35,
                                            decoration: BoxDecoration(
                                              color: sessionProvider.isLowryuMode 
                                                ? Colors.orange 
                                                : Colors.white,
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                          ),
                                        ),
                                        
                                        // 中心点
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: sessionProvider.isLowryuMode 
                                              ? Colors.orange 
                                              : Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                              
                              // タイマー
                              Consumer<SessionProvider>(
                                builder: (context, sessionProvider, child) {
                                  return Column(
                                    children: [
                                      Text(
                                        sessionProvider.remainingTimeString,
                                        style: TextStyle(
                                          fontSize: 72,
                                          fontWeight: FontWeight.bold,
                                          color: sessionProvider.isLowryuMode 
                                            ? Colors.orange  // ロウリュウ時はオレンジ色
                                            : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        sessionProvider.isLowryuMode 
                                          ? '🔥 ロウリュウモード 🔥'  // ロウリュウ時は特別なメッセージ
                                          : '残り時間',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: sessionProvider.isLowryuMode 
                                            ? Colors.orange  // ロウリュウ時はオレンジ色
                                            : Colors.white.withOpacity(0.8),
                                          fontWeight: sessionProvider.isLowryuMode 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 60),
                              
                              // 呼吸アニメーション
                              AnimatedBuilder(
                                animation: _breathingController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + (0.1 * _breathingController.value),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.orange,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.air,
                                        size: 40,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                              
                              // ロウリュウボタン
                              Consumer<SessionProvider>(
                                builder: (context, sessionProvider, child) {
                                  if (sessionProvider.currentPhase == SessionPhase.sauna &&
                                      sessionProvider.remainingTime >= 0 &&
                                      !sessionProvider.isLowryuMode) {
                                    return Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          height: 60,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              // 音はロウリュウモードへの切り替わり検知で再生する
                                              sessionProvider.startLowryu();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              elevation: 8,
                                            ),
                                            child: const Text(
                                              '🔥 ロウリュウ 🔥',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              
                              // ロウリュウモード表示
                              Consumer<SessionProvider>(
                                builder: (context, sessionProvider, child) {
                                  if (sessionProvider.isLowryuMode) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Text(
                                        '🔥 ロウリュウモード 🔥',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              
                              // スキップボタン
                              const SizedBox(height: 20),
                              Consumer<SessionProvider>(
                                builder: (context, sessionProvider, child) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        sessionProvider.skipToNextPhase();
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text(
                                        '水風呂にスキップ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              // 次のフェーズに進むボタン
                              Consumer<SessionProvider>(
                                builder: (context, sessionProvider, child) {
                                  if (sessionProvider.remainingTime == 0) {
                                    return Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              sessionProvider.updateTimer();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              elevation: 8,
                                            ),
                                            child: const Text(
                                              '水風呂に進む',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 