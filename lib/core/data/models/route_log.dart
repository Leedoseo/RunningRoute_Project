import 'latlng_dto.dart';
import 'tag.dart';

class RouteLog {
  final String id;
  final String title;
  final DateTime startedAt;
  final DateTime endedAt;
  final List<LatLngDto> path;         // 경로 좌표
  final double distanceMeters;        // 총 거리(m)
  final Duration movingTime;          // 이동 시간
  final double? avgPaceSecPerKm;      // 초/킬로 (null 허용)
  final List<Tag> tags;
  final String? notes;
  final String source;                // 'recorded' | 'imported' 등

  const RouteLog({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.endedAt,
    required this.path,
    required this.distanceMeters,
    required this.movingTime,
    required this.avgPaceSecPerKm,
    required this.tags,
    required this.source,
    this.notes,
  });

  // 편의 메서드/게터
  double get distanceKm => distanceMeters / 1000.0;

  /// 평균 페이스를 "m'ss\"/km" 포맷으로 반환 (없으면 "-")
  String get avgPaceText {
    final p = avgPaceSecPerKm;
    if (p == null || p.isNaN || p.isInfinite || p <= 0) return "-";
    final m = p ~/ 60;
    final s = (p % 60).round().toString().padLeft(2, '0');
    return "$m'$s\"/km";
  }

  /// 이동 시간을 "hh:mm:ss" 또는 "mm:ss"로 반환
  String get movingTimeText {
    final h = movingTime.inHours;
    final m = movingTime.inMinutes % 60;
    final s = movingTime.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 거리 텍스트(소수 2자리, 10km 이상이면 정수)
  String get distanceText {
    final km = distanceKm;
    return km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(2)} km';
  }

  Duration get elapsed => endedAt.difference(startedAt);

  // copyWith
  RouteLog copyWith({
    String? id,
    String? title,
    DateTime? startedAt,
    DateTime? endedAt,
    List<LatLngDto>? path,
    double? distanceMeters,
    Duration? movingTime,
    double? avgPaceSecPerKm,
    List<Tag>? tags,
    String? notes,
    String? source,
  }) {
    return RouteLog(
      id: id ?? this.id,
      title: title ?? this.title,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      path: path ?? this.path,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      movingTime: movingTime ?? this.movingTime,
      avgPaceSecPerKm: avgPaceSecPerKm ?? this.avgPaceSecPerKm,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      source: source ?? this.source,
    );
  }

  // 직렬화
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'path': path.map((e) => e.toJson()).toList(),
    'distanceMeters': distanceMeters,
    'movingTimeSec': movingTime.inSeconds,
    'avgPaceSecPerKm': avgPaceSecPerKm,
    'tags': tags.map((e) => e.toJson()).toList(),
    'notes': notes,
    'source': source,
  };

  factory RouteLog.fromJson(Map<String, dynamic> json) => RouteLog(
    id: json['id'] as String,
    title: json['title'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: DateTime.parse(json['endedAt'] as String),
    path: (json['path'] as List).map((e) => LatLngDto.fromJson(e)).toList(),
    distanceMeters: (json['distanceMeters'] as num).toDouble(),
    movingTime: Duration(seconds: json['movingTimeSec'] as int),
    avgPaceSecPerKm: (json['avgPaceSecPerKm'] as num?)?.toDouble(),
    tags: (json['tags'] as List).map((e) => Tag.fromJson(e)).toList(),
    notes: json['notes'] as String?,
    source: json['source'] as String,
  );

  // 동등성/디버그
  @override
  String toString() =>
      'RouteLog(id: $id, title: $title, distance: ${distanceText}, time: $movingTimeText, pace: $avgPaceText)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteLog &&
        other.id == id &&
        other.title == title &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        _listEqualsLatLng(other.path, path) &&
        other.distanceMeters == distanceMeters &&
        other.movingTime == movingTime &&
        other.avgPaceSecPerKm == avgPaceSecPerKm &&
        _listEqualsTag(other.tags, tags) &&
        other.notes == notes &&
        other.source == source;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      startedAt.hashCode ^
      endedAt.hashCode ^
      _deepHashLatLng(path) ^
      distanceMeters.hashCode ^
      movingTime.hashCode ^
      (avgPaceSecPerKm?.hashCode ?? 0) ^
      _deepHashTag(tags) ^
      (notes?.hashCode ?? 0) ^
      source.hashCode;

  // 리스트 동등성/해시 보조
  static bool _listEqualsLatLng(List<LatLngDto> a, List<LatLngDto> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _listEqualsTag(List<Tag> a, List<Tag> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _deepHashLatLng(List<LatLngDto> list) {
    var h = 0;
    for (final e in list) {
      h = 0x1fffffff & (h + e.hashCode);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= (h >> 6);
    }
    return h;
  }

  static int _deepHashTag(List<Tag> list) {
    var h = 0;
    for (final e in list) {
      h = 0x1fffffff & (h + e.hashCode);
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= (h >> 6);
    }
    return h;
  }
}
