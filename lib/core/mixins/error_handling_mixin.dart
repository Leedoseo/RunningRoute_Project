import 'package:flutter/foundation.dart';

/// Controller의 에러 핸들링을 위한 믹스인
///
/// 이 믹스인을 사용하면 Controller에서 일관된 에러 처리를 할 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// class MyController extends ChangeNotifier with ErrorHandlingMixin {
///   Future<void> loadData() async {
///     await handleError(() async {
///       // 데이터 로딩 로직
///     }, errorMessage: 'Failed to load data');
///   }
/// }
/// ```
mixin ErrorHandlingMixin on ChangeNotifier {
  String? _error;
  bool _loading = false;

  /// 현재 에러 메시지
  String? get error => _error;

  /// 로딩 중인지 여부
  bool get loading => _loading;

  /// 에러가 있는지 여부
  bool get hasError => _error != null;

  /// 에러 메시지 설정
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 에러 초기화
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 로딩 상태 설정
  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  /// 에러 핸들링과 함께 비동기 작업 실행
  ///
  /// [action]: 실행할 비동기 작업
  /// [errorMessage]: 에러 발생 시 표시할 메시지 (선택사항)
  /// [showLoading]: 로딩 상태 표시 여부 (기본값: true)
  /// [logError]: 에러를 디버그 콘솔에 출력할지 여부 (기본값: true)
  /// [onError]: 에러 발생 시 추가 콜백 (선택사항)
  ///
  /// 반환값: 작업 성공 시 true, 실패 시 false
  Future<bool> handleError(
    Future<void> Function() action, {
    String? errorMessage,
    bool showLoading = true,
    bool logError = true,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    if (showLoading) {
      _loading = true;
      _error = null;
      notifyListeners();
    } else {
      _error = null;
      notifyListeners();
    }

    try {
      await action();
      return true;
    } catch (e, stackTrace) {
      _error = errorMessage ?? e.toString();

      if (logError) {
        debugPrint('Error: $_error');
        debugPrint('Stack trace: $stackTrace');
      }

      onError?.call(e, stackTrace);
      return false;
    } finally {
      if (showLoading) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// 에러 핸들링과 함께 비동기 작업 실행 (반환값 있음)
  ///
  /// [action]: 실행할 비동기 작업
  /// [errorMessage]: 에러 발생 시 표시할 메시지 (선택사항)
  /// [showLoading]: 로딩 상태 표시 여부 (기본값: true)
  /// [logError]: 에러를 디버그 콘솔에 출력할지 여부 (기본값: true)
  /// [defaultValue]: 에러 발생 시 반환할 기본값 (선택사항)
  /// [onError]: 에러 발생 시 추가 콜백 (선택사항)
  ///
  /// 반환값: 작업 결과 또는 에러 시 defaultValue
  Future<T?> handleErrorWithResult<T>(
    Future<T> Function() action, {
    String? errorMessage,
    bool showLoading = true,
    bool logError = true,
    T? defaultValue,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    if (showLoading) {
      _loading = true;
      _error = null;
      notifyListeners();
    } else {
      _error = null;
      notifyListeners();
    }

    try {
      final result = await action();
      return result;
    } catch (e, stackTrace) {
      _error = errorMessage ?? e.toString();

      if (logError) {
        debugPrint('Error: $_error');
        debugPrint('Stack trace: $stackTrace');
      }

      onError?.call(e, stackTrace);
      return defaultValue;
    } finally {
      if (showLoading) {
        _loading = false;
        notifyListeners();
      }
    }
  }
}
