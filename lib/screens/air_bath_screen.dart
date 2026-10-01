import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/audio_settings_provider.dart';
import '../services/audio_service.dart';

class AirBathScreen extends StatefulWidget {
  const AirBathScreen({super.key});

  @override
  State<AirBathScreen> createState() => _AirBathScreenState();
}

class _AirBathScreenState extends State<AirBathScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late Timer _timer;
  late AnimationController _windController;
  late AnimationController _breathingController;
  final AudioService _audioService = AudioService();
  final TextEditingController _diaryController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();

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
      _audioService.playAirBathAmbient(audioSettings);
    });
  }

  void _initializeAnimations() {
    _windController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _breathingController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
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
    _windController.dispose();
    _breathingController.dispose();
    _diaryController.dispose();
    _reflectionController.dispose();
    // 音源の停止・切り替えは次の画面（またはセッション終了処理）で行う
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('外気浴画面: アプリがフォアグラウンドに復帰しました');
        // バックグラウンド復帰時に時間補正を実行
        final sessionProvider = context.read<SessionProvider>();
        sessionProvider.correctTimerOnResume();
        
        // 音源の継続を確認
        _audioService.ensurePersistentAudio();
        break;
      case AppLifecycleState.paused:
        print('外気浴画面: アプリがバックグラウンドに移行しました');
        // バックグラウンドでもタイマーを継続
        // _timer.cancel(); // タイマーを停止しない
        
        // バックグラウンド移行時に音源の継続を強化
        _audioService.ensurePersistentAudio();
        break;
      case AppLifecycleState.detached:
        print('外気浴画面: アプリが完全に終了しました');
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
            image: AssetImage('assets/images/screens/air_bath.jpg'),
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
                              '外気浴 (セット ${sessionProvider.currentSet}/${sessionProvider.setCount})',
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
                  const SizedBox(height: 20),
                  
                  // タイマー
                  Consumer<SessionProvider>(
                    builder: (context, sessionProvider, child) {
                      return Column(
                        children: [
                          Text(
                            sessionProvider.remainingTimeString,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '残り時間',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  
                  // 風のアニメーション
                  AnimatedBuilder(
                    animation: _windController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(20 * _windController.value, 0),
                        child: Opacity(
                          opacity: 0.4 * _windController.value,
                          child: const Icon(
                            Icons.air,
                            size: 60,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  
                  // 日記入力エリア
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // 日記入力
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.edit_note,
                                      color: Colors.purple,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '今日の気持ちを記録',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _diaryController,
                                  maxLines: 3,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '今日のセッションの感想を書いてみましょう...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    context.read<SessionProvider>().updateDiaryEntry(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // 振り返り入力
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.psychology,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'セッション振り返り',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _reflectionController,
                                  maxLines: 3,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '今回のセッションで気づいたことを振り返ってみましょう...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    context.read<SessionProvider>().updateReflection(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // スキップボタン
                          Consumer<SessionProvider>(
                            builder: (context, sessionProvider, child) {
                              final isLastSet = sessionProvider.currentSet >= sessionProvider.setCount;
                              return SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: () {
                                    // 最後のセットの場合、セッション完了処理の中で音源が停止される
                                    sessionProvider.skipToNextPhase();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    isLastSet ? 'セッション完了' : '次のセットにスキップ',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // 次のセット/完了ボタン
                          Consumer<SessionProvider>(
                            builder: (context, sessionProvider, child) {
                              if (sessionProvider.remainingTime == 0) {
                                final isLastSet = sessionProvider.currentSet >= sessionProvider.setCount;
                                return Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // 外気浴の時間を記録してから次のセットに進む（最後のセットならセッション完了）
                                          sessionProvider.skipToNextPhase();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 8,
                                        ),
                                        child: Text(
                                          isLastSet ? 'セッション完了' : '次のセット',
                                          style: const TextStyle(
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