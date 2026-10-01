import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/audio_settings_provider.dart';
import '../services/audio_service.dart';
import '../models/session_record.dart';
import 'history_screen.dart';

class CompletionScreen extends StatefulWidget {
  const CompletionScreen({super.key});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _pulseController;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 完了画面ではセッション完了専用音源停止
      await _audioService.stopAudioOnSessionComplete();
      print('完了画面: セッション完了専用音源停止を実行しました');
      if (!mounted) return;

      final audioSettings = context.read<AudioSettingsProvider>();
      _audioService.playSessionComplete(audioSettings);
    });
  }

  void _initializeAnimations() {
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF059669), // 緑
              Color(0xFF047857), // ダークグリーン
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // お祝いアニメーション
                AnimatedBuilder(
                  animation: _celebrationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _celebrationController.value * 0.1,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.yellow,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.celebration,
                          size: 60,
                          color: Colors.yellow,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // 完了メッセージ
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (0.05 * _pulseController.value),
                      child: const Text(
                        'お疲れさまでした！',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                Consumer<SessionProvider>(
                  builder: (context, sessionProvider, child) {
                    return Text(
                      '${sessionProvider.setCount}セット完了！\n素晴らしい集中時間でした',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // 実際のセッション詳細
                Consumer<SessionProvider>(
                  builder: (context, sessionProvider, child) {
                    // 完了時に作業中の記録はクリアされるため、保存済みの最新セッションを表示する
                    final lastRecord = sessionProvider.sessionHistory.isNotEmpty
                        ? sessionProvider.sessionHistory.last
                        : null;
                    final setRecords = lastRecord?.setRecords ?? const <SetRecord>[];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '今回のセッション詳細',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 各セットの詳細を表示
                          ...setRecords.map(_buildSetDetail),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '総集中時間: ${lastRecord?.totalFocusTime ?? 0}分',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // ボタン
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HistoryScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '履歴を見る',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // resetSession()の中で音源も停止される
                            context.read<SessionProvider>().resetSession();
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
                            'ホームに戻る',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetDetail(SetRecord setRecord) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'セット ${setRecord.setNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (setRecord.usedLowryu) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'ロウリュウ使用 (${setRecord.lowryuTime}分)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // サウナ室の時間 = サウナ時間 + ロウリュウ時間（履歴画面と同じ表示）
              _buildPhaseTime('サウナ室', setRecord.actualSaunaTime + setRecord.lowryuTime, Colors.orange),
              _buildPhaseTime('水風呂', setRecord.actualColdBathTime, Colors.blue),
              _buildPhaseTime('外気浴', setRecord.actualAirBathTime, Colors.green),
            ],
          ),
          
          // セットの日記（存在する場合）
          if (setRecord.diaryEntry != null && setRecord.diaryEntry!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
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
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '日記',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    setRecord.diaryEntry!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          
          // セットの振り返り（存在する場合）
          if (setRecord.reflection != null && setRecord.reflection!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.teal.withOpacity(0.3),
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
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '振り返り',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    setRecord.reflection!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseTime(String phase, int time, Color color) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForPhase(phase),
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          phase,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${time}分',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getIconForPhase(String phase) {
    switch (phase) {
      case 'サウナ室':
        return Icons.thermostat;
      case '水風呂':
        return Icons.water_drop;
      case '外気浴':
        return Icons.eco;
      default:
        return Icons.timer;
    }
  }
} 