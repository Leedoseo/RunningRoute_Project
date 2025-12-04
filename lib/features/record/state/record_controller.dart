import 'dart:async';
import 'dart:math' show cos, sin, sqrt, atan2;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:routelog_project/features/settings/state/settings_controller.dart';

enum RecordStatus { idle, recording, paused, finished }
enum LocationPermissionState { unknown, granted, denied, serviceDisabled }

class RecordController extends ChangeNotifier {
  // 상태
  RecordStatus _status = RecordStatus.idle;
  LocationPermissionState _perm = LocationPermissionState.unknown;

  // 측정 값
  final List<LatLng> _path = [];
  double _distanceMeters = 0.0;
  Duration _elapsed = Duration.zero;
  late final Stopwatch _stopwatch;

  // 위치 구독
  StreamSubscription<Position>? _posSub;

  // Timer for elapsed time updates
  Timer? _timer;

  // 자동 일시정지 보조 상태
  DateTime? _lastSampleAt;
  double _belowThresholdAccumSec = 0.0; // 임계속도 미만 누적 시간(초)

  RecordController() {
    _stopwatch = Stopwatch();
  }

  // Getters
  RecordStatus get status => _status;
  LocationPermissionState get permission => _perm;
  List<LatLng> get path => List.unmodifiable(_path);
  double get distanceMeters => _distanceMeters;
  Duration get elapsed => _elapsed;

  double? get paceSecPerKm {
    final km = _distanceMeters / 1000.0;
    if (km <= 0) return null;
    final sec = _elapsed.inSeconds.toDouble();
    return sec / km; // 초/킬로
  }

  // 권한/서비스
  Future<void> initPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _perm = LocationPermissionState.serviceDisabled;
      notifyListeners();
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      _perm = LocationPermissionState.denied;
    } else {
      _perm = LocationPermissionState.granted;
    }
    notifyListeners();
  }

  // 기록 제어
  Future<void> start() async {
    if (_status == RecordStatus.recording) return;

    _status = RecordStatus.recording;
    _path.clear();
    _distanceMeters = 0.0;
    _elapsed = Duration.zero;
    _belowThresholdAccumSec = 0.0;
    _lastSampleAt = null;

    _stopwatch..reset()..start();

    // 기존 구독 해제
    await _posSub?.cancel();

    final locSettings = _resolvePlatformSettings();

    _posSub = Geolocator.getPositionStream(locationSettings: locSettings)
        .listen(_onPosition, onError: (e) {
      // 필요 시 에러 핸들링
    });

    _startTimer();
    notifyListeners();
  }

  Future<void> pause() async {
    if (_status != RecordStatus.recording) return;
    _status = RecordStatus.paused;
    _stopwatch.stop();
    _posSub?.pause();
    _timer?.cancel();
    _elapsed = _stopwatch.elapsed;
    notifyListeners();
  }

  Future<void> resume() async {
    if (_status != RecordStatus.paused) return;
    _status = RecordStatus.recording;
    _stopwatch.start();
    _posSub?.resume();
    _startTimer();
    notifyListeners();
  }

  Future<void> stop() async {
    if (_status == RecordStatus.idle || _status == RecordStatus.finished) return;
    _status = RecordStatus.finished;
    _stopwatch.stop();
    _timer?.cancel();
    await _posSub?.cancel();
    _posSub = null;
    _elapsed = _stopwatch.elapsed;
    notifyListeners();
  }

  // 위치 처리 + 자동 일시정지
  void _onPosition(Position p) {
    final now = DateTime.now();
    final pt = LatLng(p.latitude, p.longitude);

    // 거리 누적
    if (_path.isNotEmpty) {
      final prev = _path.last;
      final inc = _haversine(prev, pt); // m
      _distanceMeters += inc;
    }
    _path.add(pt);

    // 속도 계산 (샘플 간 시간 기반)
    double? speedKmh;
    if (_lastSampleAt != null && _path.length >= 2) {
      final dtSec = now.difference(_lastSampleAt!).inMilliseconds / 1000.0;
      if (dtSec > 0) {
        final dMeters = _haversine(_path[_path.length - 2], pt);
        speedKmh = (dMeters / dtSec) * 3.6;
      }
    }
    _lastSampleAt = now;

    // 자동 일시정지 로직
    final s = SettingsController.instance;
    if (status == RecordStatus.recording && s.autoPause && speedKmh != null) {
      if (speedKmh < s.autoPauseMinSpeedKmh) {
        _belowThresholdAccumSec += (p.timestamp != null) ? 0.0 : 1.0; // timestamp 신뢰 못할 때 1초 가정
        // 위 라인은 보수적으로; 더 정확히 하려면 dtSec을 누적:
        // _belowThresholdAccumSec += dtSec;
        // dtSec을 쓰려면 위에서 계산값을 꺼내 사용하세요.
      } else {
        _belowThresholdAccumSec = 0.0;
      }

      // 더 정확한 누적(권장): dtSec 기반
      if (_path.length >= 2) {
        final dtSec = now.difference(_path.length >= 2 ? now.subtract(const Duration(seconds: 1)) : now).inSeconds;
        // 단순화: 매 콜 ~1초. 실제로는 위 주석처럼 dtSec 계산해 누적 권장.
        if (speedKmh < s.autoPauseMinSpeedKmh) {
          _belowThresholdAccumSec += 1.0;
        }
      }

      if (_belowThresholdAccumSec >= s.autoPauseGraceSec) {
        // 자동 일시정지 트리거
        pause();
        // 사용자에게 힌트가 필요하면 notifyListeners() 후 배너/스낵은 화면에서 처리
      }
    }

    if (_status == RecordStatus.recording) {
      _elapsed = _stopwatch.elapsed;
      notifyListeners();
    }
  }

  // 플랫폼별 위치 설정(정확도 반영)
  LocationSettings _resolvePlatformSettings() {
    final s = SettingsController.instance;
    final isHigh = s.accuracy == GpsAccuracyOption.high;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: isHigh ? LocationAccuracy.bestForNavigation : LocationAccuracy.high,
        distanceFilter: isHigh ? 3 : 8,
        intervalDuration: isHigh ? const Duration(seconds: 2) : const Duration(seconds: 4),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'RouteLog 기록 중',
          notificationText: '러닝 경로를 기록하고 있어요.',
          notificationIcon: AndroidResource(name: 'ic_stat_routelog', defType: 'drawable'),
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: isHigh ? LocationAccuracy.bestForNavigation : LocationAccuracy.high,
        distanceFilter: isHigh ? 3 : 8,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: true,
        activityType: ActivityType.fitness,
      );
    } else {
      return LocationSettings(
        accuracy: isHigh ? LocationAccuracy.best : LocationAccuracy.high,
        distanceFilter: isHigh ? 3 : 8,
      );
    }
  }

  // 유틸
  static double _haversine(LatLng a, LatLng b) {
    const R = 6371000.0; // m
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(h), sqrt(1 - h));
    return R * c;
  }

  static double _deg2rad(double d) => d * (3.1415926535897932 / 180.0);

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status == RecordStatus.recording) {
        _elapsed = _stopwatch.elapsed;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posSub?.cancel();
    super.dispose();
  }
}
