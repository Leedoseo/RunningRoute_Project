import 'package:flutter/foundation.dart';
import 'package:routelog_project/core/data/models/route_log.dart';
import 'package:routelog_project/core/data/repository/i_route_repository.dart';

enum StatsPeriod { weekly, monthly }

class StatsController extends ChangeNotifier {
  final IRouteRepository repo;
  StatsController({required this.repo});

  // 상태
  StatsPeriod _period = StatsPeriod.weekly;
  int _offset = 0; // 0=이번 주/달, -1=이전, -2=그 이전…

  // 데이터
  bool _loading = false;
  String? _error;
  List<RouteLog> _all = [];          // 전체(메모리)
  List<RouteLog> _inRange = [];      // 현재 기간 데이터
  List<double> _series = [];         // 일별 거리(km)
  double _totalKm = 0;
  Duration _totalTime = Duration.zero;
  double? _avgPaceSecPerKm;

  // 공개 게터
  StatsPeriod get period => _period;
  int get offset => _offset;
  bool get loading => _loading;
  String? get error => _error;

  List<double> get series => _series;
  String get totalDistanceText => _fmtKm(_totalKm);
  String get totalTimeText => _fmtDur(_totalTime);
  String get avgPaceText =>
      (_avgPaceSecPerKm == null) ? '-' : _fmtPace(_avgPaceSecPerKm!);
  List<RouteLog> get sessions => _inRange;

  // 퍼블릭 API
  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await repo.list(sort: 'date_desc'); // 전부 가져와서 메모리에 유지
      _recompute();
    } catch (e, stackTrace) {
      _error = e.toString();
      debugPrint('Failed to load stats: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setPeriod(StatsPeriod p) {
    if (_period == p) return;
    _period = p;
    _offset = 0;
    _recompute();
    notifyListeners();
  }

  void previous() {
    _offset -= 1;
    _recompute();
    notifyListeners();
  }

  void next() {
    if (_offset < 0) {
      _offset += 1;
      _recompute();
      notifyListeners();
    }
  }

  String get periodLabel {
    if (_period == StatsPeriod.weekly) {
      if (_offset == 0) return '이번 주';
      if (_offset == -1) return '지난 주';
      return '${-_offset}주 전';
    } else {
      if (_offset == 0) return '이번 달';
      if (_offset == -1) return '지난 달';
      return '${-_offset}개월 전';
    }
  }

  // 내부 로직
  void _recompute() {
    if (_period == StatsPeriod.weekly) {
      final range = _weekRange(_offset);
      _inRange = _filterByRange(range.$1, range.$2);
      _series = _buildDailyKmSeries(range.$1, 7);
    } else {
      final range = _monthRange(_offset);
      final days = DateTime(range.$2.year, range.$2.month, 0).day; // 말일
      _inRange = _filterByRange(range.$1, range.$2);
      _series = _buildDailyKmSeries(range.$1, days);
    }

    _totalKm = _inRange.fold(0.0, (sum, r) => sum + r.distanceMeters / 1000.0);
    _totalTime = _inRange.fold(Duration.zero, (sum, r) => sum + r.movingTime);
    _avgPaceSecPerKm = _calcAvgPace(_inRange);
  }

  List<RouteLog> _filterByRange(DateTime startIncl, DateTime endExcl) {
    return _all.where((r) {
      final t = r.startedAt;
      return !t.isBefore(startIncl) && t.isBefore(endExcl);
    }).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  List<double> _buildDailyKmSeries(DateTime start, int days) {
    final arr = List<double>.filled(days, 0.0);
    for (final r in _inRange) {
      final idx = r.startedAt.difference(DateTime(start.year, start.month, start.day)).inDays;
      if (idx >= 0 && idx < days) {
        arr[idx] += r.distanceMeters / 1000.0;
      }
    }
    return arr;
  }

  // 주간: 월요일~월요일
  (DateTime, DateTime) _weekRange(int offset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday; // 1=Mon..7=Sun
    final monday = today.subtract(Duration(days: weekday - 1)).add(Duration(days: 7 * offset));
    final nextMonday = monday.add(const Duration(days: 7));
    return (monday, nextMonday);
  }

  // 월간: 1일~다음달 1일
  (DateTime, DateTime) _monthRange(int offset) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final start = DateTime(thisMonth.year, thisMonth.month + offset, 1);
    final end = DateTime(start.year, start.month + 1, 1);
    return (start, end);
  }

  double? _calcAvgPace(List<RouteLog> items) {
    double kmSum = 0;
    int secSum = 0;
    for (final r in items) {
      final km = r.distanceMeters / 1000.0;
      kmSum += km;
      secSum += r.movingTime.inSeconds;
    }
    if (kmSum <= 0) return null;
    return secSum / kmSum; // sec/km
  }

  static String _fmtKm(double km) =>
      km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(2)} km';

  static String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String _fmtPace(double secPerKm) {
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).round();
    return "$m'${s.toString().padLeft(2, '0')}\"/km";
  }
}
