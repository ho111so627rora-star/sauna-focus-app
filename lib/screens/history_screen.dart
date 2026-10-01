import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../models/session_record.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
                // ヘッダー
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'セッション履歴',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // バランス調整
                  ],
                ),
                const SizedBox(height: 20),
                
                // タブ
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 
                                ? Colors.orange 
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '履歴',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1 
                                ? Colors.orange 
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'グラフ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // コンテンツ
                Expanded(
                  child: Consumer<SessionProvider>(
                    builder: (context, sessionProvider, child) {
                      if (sessionProvider.sessionHistory.isEmpty) {
                        return const Center(
                          child: Text(
                            'まだセッション履歴がありません\nセッションを開始して記録を作りましょう！',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white60,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      
                      if (_selectedTabIndex == 0) {
                        // 履歴リスト（新しいものから上に表示）
                        return ListView.builder(
                          itemCount: sessionProvider.sessionHistory.length,
                          itemBuilder: (context, index) {
                            // インデックスを逆順にして、最新のものが上に来るようにする
                            final reversedIndex = sessionProvider.sessionHistory.length - 1 - index;
                            final record = sessionProvider.sessionHistory[reversedIndex];
                            return _buildHistoryCard(record);
                          },
                        );
                      } else {
                        // グラフ表示
                        return _buildGraphView(sessionProvider.sessionHistory);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(SessionRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          // 日付と時刻
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                record.dateString,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                record.timeString,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // セット詳細
          ...record.setRecords.map((setRecord) => _buildSetDetail(setRecord)),
          
          // 総時間
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.timer,
                color: Colors.cyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '総時間: ${record.totalFocusTime}分',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // ロウリュウ使用情報
          if (record.usedLowryu) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'ロウリュウ使用',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          
          // 日記エントリー（存在する場合）
          if (record.diaryEntry != null && record.diaryEntry!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: Colors.purple,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '日記',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.diaryEntry!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          
          // 振り返り（存在する場合）
          if (record.reflection != null && record.reflection!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Colors.teal,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '振り返り',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    record.reflection!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    maxLines: 3,
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

  Widget _buildSetDetail(SetRecord setRecord) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セット番号
          Row(
            children: [
              Icon(
                Icons.repeat,
                color: Colors.purple,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'セット ${setRecord.setNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 実際の時間
          Row(
            children: [
              // サウナ室の時間 = サウナ時間 + ロウリュウ時間
              _buildPhaseTime('サウナ室', setRecord.actualSaunaTime + setRecord.lowryuTime, Colors.orange),
              const SizedBox(width: 8),
              _buildPhaseTime('水風呂', setRecord.actualColdBathTime, Colors.blue),
              const SizedBox(width: 8),
              _buildPhaseTime('外気浴', setRecord.actualAirBathTime, Colors.green),
            ],
          ),
          
          
          // セット総時間
          const SizedBox(height: 8),
          Text(
            'セット総時間: ${setRecord.totalTime}分',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
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

  Widget _buildPhaseTime(String label, int time, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  // グラフ表示用のメソッド
  Widget _buildGraphView(List<SessionRecord> sessionHistory) {
    // 日毎のデータを集計
    final Map<String, int> dailyData = {};
    
    for (final record in sessionHistory) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.startTime);
      dailyData[dateKey] = (dailyData[dateKey] ?? 0) + record.totalFocusTime;
    }
    
    // 日付順にソート
    final sortedDates = dailyData.keys.toList()..sort();
    
    if (sortedDates.isEmpty) {
      return const Center(
        child: Text(
          'グラフデータがありません',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white60,
          ),
        ),
      );
    }
    
    // グラフデータを作成
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyData[sortedDates[i]]!.toDouble()));
    }
    
    // 縦軸の最大値と目盛り間隔（目盛りがおよそ5本になるように）
    final maxValue = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final yInterval = max(10, (maxValue / 5 / 10).ceil() * 10).toDouble();
    final maxY = (maxValue / yInterval).ceil() * yInterval + yInterval;

    // 統計情報を計算
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    
    int weeklyTotal = 0;
    int monthlyTotal = 0;
    int totalFocusTime = 0;
    
    for (final record in sessionHistory) {
      totalFocusTime += record.totalFocusTime;
      
      if (record.startTime.isAfter(oneWeekAgo)) {
        weeklyTotal += record.totalFocusTime;
      }
      
      if (record.startTime.isAfter(oneMonthAgo)) {
        monthlyTotal += record.totalFocusTime;
      }
    }
    
    return Column(
      children: [
        // 統計情報カード
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                '集中時間統計',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('一週間', weeklyTotal, Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('一ヶ月', monthlyTotal, Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('総計', totalFocusTime, Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // グラフタイトル
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '日毎の総集中時間',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        
        // グラフ
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: yInterval,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        // 整数位置にだけ日付ラベルを表示（データが1日分の時の両端の余白には表示しない）
                        if (value == value.roundToDouble() &&
                            value.toInt() >= 0 &&
                            value.toInt() < sortedDates.length) {
                          final date = DateTime.parse(sortedDates[value.toInt()]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}分',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                // データが1日分だけの時に横軸の幅が0にならないよう左右に余白を取る
                minX: sortedDates.length == 1 ? -1 : 0,
                maxX: sortedDates.length == 1 ? 1 : (sortedDates.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.red],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.orange,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.orange.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // 統計カードウィジェット
  Widget _buildStatCard(String title, int minutes, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${minutes}分',
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}