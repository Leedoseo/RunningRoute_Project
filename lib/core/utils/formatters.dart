/// 공통 포맷팅 유틸리티
class Formatters {
  Formatters._(); // private 생성자로 인스턴스 생성 방지

  /// Duration을 "hh:mm:ss" 또는 "mm:ss" 형식으로 변환
  ///
  /// [duration]: 포맷할 시간
  /// [forceHours]: true이면 항상 시간을 표시 (기본값: false)
  ///
  /// 예시:
  /// - Duration(seconds: 45) → "00:45"
  /// - Duration(minutes: 5, seconds: 30) → "05:30"
  /// - Duration(hours: 1, minutes: 23, seconds: 45) → "1:23:45"
  static String formatDuration(Duration duration, {bool forceHours = false}) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;

    if (h > 0 || forceHours) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 거리(미터)를 "X.XX km" 형식으로 변환
  ///
  /// [meters]: 거리 (미터)
  /// [precision]: 소수점 자리수 (기본값: 2)
  /// [useIntForLarge]: 10km 이상일 때 정수로 표시 (기본값: true)
  ///
  /// 예시:
  /// - 1500 → "1.50 km"
  /// - 5280 → "5.28 km"
  /// - 12000 → "12 km" (useIntForLarge: true)
  static String formatDistance(
    double meters, {
    int precision = 2,
    bool useIntForLarge = true,
  }) {
    final km = meters / 1000.0;

    if (useIntForLarge && km >= 10) {
      return '${km.toStringAsFixed(0)} km';
    }
    return '${km.toStringAsFixed(precision)} km';
  }

  /// 페이스(초/km)를 "m'ss\"/km" 형식으로 변환
  ///
  /// [secondsPerKm]: 초당 킬로미터
  ///
  /// 예시:
  /// - 330 → "5'30\"/km" (5분 30초/km)
  /// - 240 → "4'00\"/km" (4분/km)
  /// - null/NaN/Infinite → "-"
  static String formatPace(double? secondsPerKm) {
    if (secondsPerKm == null ||
        secondsPerKm.isNaN ||
        secondsPerKm.isInfinite ||
        secondsPerKm <= 0) {
      return '-';
    }

    final m = secondsPerKm ~/ 60;
    final s = (secondsPerKm % 60).round().toString().padLeft(2, '0');
    return "$m'$s\"/km";
  }

  /// 속도(m/s)를 "X.XX km/h" 형식으로 변환
  ///
  /// [metersPerSecond]: 초당 미터
  /// [precision]: 소수점 자리수 (기본값: 1)
  ///
  /// 예시:
  /// - 2.78 → "10.0 km/h"
  /// - 0 → "0.0 km/h"
  static String formatSpeed(double metersPerSecond, {int precision = 1}) {
    final kmh = metersPerSecond * 3.6;
    return '${kmh.toStringAsFixed(precision)} km/h';
  }

  /// 날짜를 "yyyy-MM-dd" 형식으로 변환
  ///
  /// [dateTime]: 변환할 날짜
  ///
  /// 예시:
  /// - 2024-12-04 → "2024-12-04"
  static String formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// 날짜와 시간을 "yyyy-MM-dd HH:mm" 형식으로 변환
  ///
  /// [dateTime]: 변환할 날짜시간
  ///
  /// 예시:
  /// - 2024-12-04 14:30:45 → "2024-12-04 14:30"
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 시간을 "HH:mm" 형식으로 변환
  ///
  /// [dateTime]: 변환할 시간
  ///
  /// 예시:
  /// - 14:30:45 → "14:30"
  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 상대 시간 표시 ("방금 전", "3분 전", "어제" 등)
  ///
  /// [dateTime]: 기준 날짜시간
  /// [now]: 현재 시간 (테스트용, 기본값: DateTime.now())
  ///
  /// 예시:
  /// - 30초 전 → "방금 전"
  /// - 5분 전 → "5분 전"
  /// - 어제 → "어제"
  /// - 3일 전 → "3일 전"
  static String formatRelativeTime(DateTime dateTime, {DateTime? now}) {
    now ??= DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks주 전';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months개월 전';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years년 전';
    }
  }
}
