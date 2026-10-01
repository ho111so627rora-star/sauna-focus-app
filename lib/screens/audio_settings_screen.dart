import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_settings_provider.dart';

class AudioSettingsScreen extends StatelessWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '音声設定',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1F2937), // ダークグレー
              Color(0xFF111827), // より暗いグレー
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<AudioSettingsProvider>(
              builder: (context, audioSettings, child) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 全体音声設定
                      _buildSectionCard(
                        title: '全体設定',
                        icon: Icons.volume_up,
                        children: [
                          _buildSwitchTile(
                            title: '音声を有効にする',
                            value: audioSettings.isAudioEnabled,
                            onChanged: (value) => audioSettings.toggleAudio(),
                            icon: Icons.volume_up,
                          ),
                          if (audioSettings.isAudioEnabled) ...[
                            const SizedBox(height: 16),
                            _buildVolumeSlider(
                              title: '音量調整',
                              value: audioSettings.volume,
                              onChanged: (value) => audioSettings.setVolume(value),
                              context: context,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 各音声の個別設定
                      _buildSectionCard(
                        title: '音声の個別設定',
                        icon: Icons.settings,
                        children: [
                          _buildSwitchTile(
                            title: 'サウナ室の音声',
                            value: audioSettings.isSaunaAudioEnabled,
                            onChanged: (value) => audioSettings.toggleSaunaAudio(),
                            icon: Icons.thermostat,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildSwitchTile(
                            title: '水風呂の音声',
                            value: audioSettings.isColdBathAudioEnabled,
                            onChanged: (value) => audioSettings.toggleColdBathAudio(),
                            icon: Icons.water_drop,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildSwitchTile(
                            title: '外気浴の音声',
                            value: audioSettings.isAirBathAudioEnabled,
                            onChanged: (value) => audioSettings.toggleAirBathAudio(),
                            icon: Icons.eco,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildSwitchTile(
                            title: 'ロウリュウの音声',
                            value: audioSettings.isLowryuAudioEnabled,
                            onChanged: (value) => audioSettings.toggleLowryuAudio(),
                            icon: Icons.local_fire_department,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          _buildSwitchTile(
                            title: '完了時の音声',
                            value: audioSettings.isCompletionAudioEnabled,
                            onChanged: (value) => audioSettings.toggleCompletionAudio(),
                            icon: Icons.celebration,
                            color: Colors.yellow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 説明
                      _buildSectionCard(
                        title: '設定について',
                        icon: Icons.info,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '設定の説明',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '• 全体設定で音声を無効にすると、すべての音声が再生されません\n'
                                  '• 個別設定で特定の音声のみを無効にできます\n'
                                  '• 音量は0%から100%まで調整可能です\n'
                                  '• 設定は自動的に保存されます',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.orange,
            activeTrackColor: Colors.orange.withOpacity(0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.volume_up,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.orange,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
            thumbColor: Colors.orange,
            overlayColor: Colors.orange.withOpacity(0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
            divisions: 20,
          ),
        ),
      ],
    );
  }
} 