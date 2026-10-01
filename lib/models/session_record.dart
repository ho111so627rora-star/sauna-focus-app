class SessionRecord {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int saunaDuration; // サウナ時間（分）
  final int coldBathDuration; // 水風呂時間（分）
  final int airBathDuration; // 外気浴時間（分）
  final String? diaryEntry; // 日記内容
  final String? reflection; // 振り返り内容
  final bool usedLowryu; // ロウリュウを使用したか
  final int totalFocusTime; // 総集中時間（分）
  final List<SetRecord> setRecords; // 各セットの詳細記録

  SessionRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.saunaDuration,
    required this.coldBathDuration,
    required this.airBathDuration,
    this.diaryEntry,
    this.reflection,
    this.usedLowryu = false,
    required this.totalFocusTime,
    required this.setRecords,
  });

  // JSONからオブジェクトを作成
  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      saunaDuration: json['saunaDuration'],
      coldBathDuration: json['coldBathDuration'],
      airBathDuration: json['airBathDuration'],
      diaryEntry: json['diaryEntry'],
      reflection: json['reflection'],
      usedLowryu: json['usedLowryu'] ?? false,
      totalFocusTime: json['totalFocusTime'],
      setRecords: (json['setRecords'] as List?)
          ?.map((setJson) => SetRecord.fromJson(setJson))
          .toList() ?? [],
    );
  }

  // オブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'saunaDuration': saunaDuration,
      'coldBathDuration': coldBathDuration,
      'airBathDuration': airBathDuration,
      'diaryEntry': diaryEntry,
      'reflection': reflection,
      'usedLowryu': usedLowryu,
      'totalFocusTime': totalFocusTime,
      'setRecords': setRecords.map((set) => set.toJson()).toList(),
    };
  }

  // セッションの総時間を取得（分）
  int get totalDuration => saunaDuration + coldBathDuration + airBathDuration;

  // セッションの日付を取得
  String get dateString {
    return '${startTime.year}/${startTime.month.toString().padLeft(2, '0')}/${startTime.day.toString().padLeft(2, '0')}';
  }

  // セッションの開始時刻を取得
  String get timeString {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }
}

// 各セットの詳細記録
class SetRecord {
  final int setNumber; // セット番号
  final int actualSaunaTime; // 実際のサウナ時間（分）
  final int actualColdBathTime; // 実際の水風呂時間（分）
  final int actualAirBathTime; // 実際の外気浴時間（分）
  final bool usedLowryu; // このセットでロウリュウを使用したか
  final int lowryuTime; // ロウリュウ時間（分）
  final String? diaryEntry; // このセットの日記内容
  final String? reflection; // このセットの振り返り内容

  SetRecord({
    required this.setNumber,
    required this.actualSaunaTime,
    required this.actualColdBathTime,
    required this.actualAirBathTime,
    this.usedLowryu = false,
    this.lowryuTime = 0,
    this.diaryEntry,
    this.reflection,
  });

  // JSONからオブジェクトを作成
  factory SetRecord.fromJson(Map<String, dynamic> json) {
    return SetRecord(
      setNumber: json['setNumber'],
      actualSaunaTime: json['actualSaunaTime'],
      actualColdBathTime: json['actualColdBathTime'],
      actualAirBathTime: json['actualAirBathTime'],
      usedLowryu: json['usedLowryu'] ?? false,
      lowryuTime: json['lowryuTime'] ?? 0,
      diaryEntry: json['diaryEntry'],
      reflection: json['reflection'],
    );
  }

  // オブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'actualSaunaTime': actualSaunaTime,
      'actualColdBathTime': actualColdBathTime,
      'actualAirBathTime': actualAirBathTime,
      'usedLowryu': usedLowryu,
      'lowryuTime': lowryuTime,
      'diaryEntry': diaryEntry,
      'reflection': reflection,
    };
  }

  // このセットの総時間を取得
  int get totalTime => actualSaunaTime + actualColdBathTime + actualAirBathTime + lowryuTime;
} 