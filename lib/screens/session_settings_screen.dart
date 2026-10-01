import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';

class SessionSettingsScreen extends StatefulWidget {
  const SessionSettingsScreen({super.key});

  @override
  State<SessionSettingsScreen> createState() => _SessionSettingsScreenState();
}

class _SessionSettingsScreenState extends State<SessionSettingsScreen> {
  int _saunaDuration = 25;
  int _coldBathDuration = 5;
  int _airBathDuration = 5;
  int _setCount = 1;

  @override
  void initState() {
    super.initState();
    // 現在の設定値から編集を始める（毎回デフォルト値に戻らないように）
    final sessionProvider = context.read<SessionProvider>();
    _saunaDuration = sessionProvider.saunaDuration;
    _coldBathDuration = sessionProvider.coldBathDuration;
    _airBathDuration = sessionProvider.airBathDuration;
    _setCount = sessionProvider.setCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/sauna_room.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'セッション設定',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // サウナ室設定
                          _buildSettingCard(
                            title: 'サウナ室',
                            icon: Icons.thermostat,
                            color: Colors.orange,
                            currentValue: _saunaDuration,
                            minValue: 5,
                            maxValue: 60,
                            step: 5,
                            onChanged: (value) {
                              setState(() {
                                _saunaDuration = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // 水風呂設定
                          _buildSettingCard(
                            title: '水風呂',
                            icon: Icons.water_drop,
                            color: Colors.blue,
                            currentValue: _coldBathDuration,
                            minValue: 1,
                            maxValue: 10,
                            step: 1,
                            onChanged: (value) {
                              setState(() {
                                _coldBathDuration = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // 外気浴設定
                          _buildSettingCard(
                            title: '外気浴',
                            icon: Icons.eco,
                            color: Colors.green,
                            currentValue: _airBathDuration,
                            minValue: 1,
                            maxValue: 15,
                            step: 1,
                            onChanged: (value) {
                              setState(() {
                                _airBathDuration = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // セット数設定
                          _buildSetCountCard(),
                          const SizedBox(height: 40),

                          // 合計時間表示
                          Container(
                            width: double.infinity,
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
                                  '合計時間',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${(_saunaDuration + _coldBathDuration + _airBathDuration) * _setCount}分',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyan,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_setCount}セット × ${_saunaDuration + _coldBathDuration + _airBathDuration}分',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ボタン
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              // 設定をプロバイダーに保存
                              context.read<SessionProvider>().updateDurations(
                                saunaDuration: _saunaDuration,
                                coldBathDuration: _coldBathDuration,
                                airBathDuration: _airBathDuration,
                              );
                              context.read<SessionProvider>().updateSetCount(_setCount);
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              '設定を保存',
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
                              // 設定をプロバイダーに保存
                              context.read<SessionProvider>().updateDurations(
                                saunaDuration: _saunaDuration,
                                coldBathDuration: _coldBathDuration,
                                airBathDuration: _airBathDuration,
                              );
                              context.read<SessionProvider>().updateSetCount(_setCount);
                              context.read<SessionProvider>().startSession();
                              // ホーム画面に戻る
                              Navigator.pop(context);
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
                              'セッション開始',
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
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    required Color color,
    required int currentValue,
    required int minValue,
    required int maxValue,
    required int step,
    required Function(int) onChanged,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: currentValue > minValue
                    ? () => onChanged(currentValue - step)
                    : null,
                icon: const Icon(Icons.remove, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  '${currentValue}分',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: currentValue < maxValue
                    ? () => onChanged(currentValue + step)
                    : null,
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetCountCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.repeat, color: Colors.purple, size: 24),
              const SizedBox(width: 12),
              const Text(
                'セット数',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final setNumber = index + 1;
              final isSelected = _setCount == setNumber;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _setCount = setNumber;
                  });
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.purple.withOpacity(0.8)
                        : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.purple : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$setNumber',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
} 