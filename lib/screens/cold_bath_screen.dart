import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/audio_settings_provider.dart';
import '../services/audio_service.dart';

class ColdBathScreen extends StatefulWidget {
  const ColdBathScreen({super.key});

  @override
  State<ColdBathScreen> createState() => _ColdBathScreenState();
}

class _ColdBathScreenState extends State<ColdBathScreen>
    with WidgetsBindingObserver {
  late Timer _timer;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _startTimer();
    
    // アプリのライフサイクルを監視
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audioSettings = context.read<AudioSettingsProvider>();
      _audioService.playColdBathAmbient(audioSettings);
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final sessionProvider = context.read<SessionProvider>();
      sessionProvider.updateTimer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    // 音源の停止・切り替えは次の画面（またはセッション終了処理）で行う
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('水風呂画面: アプリがフォアグラウンドに復帰しました');
        // バックグラウンド復帰時に時間補正を実行
        final sessionProvider = context.read<SessionProvider>();
        sessionProvider.correctTimerOnResume();
        
        // 割り込み（電話など）で止まった環境音を再開
        _audioService.resumeIfNeeded();
        break;
      case AppLifecycleState.paused:
        print('水風呂画面: アプリがバックグラウンドに移行しました');
        // バックグラウンドでもタイマーを継続
        // _timer.cancel(); // タイマーを停止しない
        
        // バックグラウンド移行時に音源の継続を強化
        _audioService.ensurePersistentAudio();
        break;
      case AppLifecycleState.detached:
        print('水風呂画面: アプリが完全に終了しました');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/screens/cold_bath.jpg'),
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
                              '水風呂 (セット ${sessionProvider.currentSet}/${sessionProvider.setCount})',
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
                      const SizedBox(width: 48), // バランス調整
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // メインコンテンツ
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // シンプルな水のアイコン
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.water_drop,
                              size: 60,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // タイマー
                          Consumer<SessionProvider>(
                            builder: (context, sessionProvider, child) {
                              return Column(
                                children: [
                                  Text(
                                    sessionProvider.remainingTimeString,
                                    style: const TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '残り時間',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 60),
                          
                          // シンプルな呼吸アイコン
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.air,
                              size: 40,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // スキップボタン
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
                                    '外気浴にスキップ',
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
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 8,
                                        ),
                                        child: const Text(
                                          '外気浴に進む',
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
      ),
    );
  }
} 