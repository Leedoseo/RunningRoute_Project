import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routelog_project/core/services/auth_service.dart';

/// 인증 상태를 관리하는 컨트롤러
class AuthController with ChangeNotifier {
  static final AuthController instance = AuthController._();
  AuthController._();

  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  /// 인증 상태 초기화
  Future<void> initialize() async {
    // 인증 상태 변경 리스너
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });

    // 현재 사용자 확인
    _user = _authService.currentUser;
    _isLoading = false;
    notifyListeners();
  }

  /// 이메일/비밀번호로 로그인
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _authService.signInWithEmail(email, password);
    } catch (e) {
      rethrow;
    }
  }

  /// 이메일/비밀번호로 회원가입
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _authService.signUpWithEmail(email, password);
    } catch (e) {
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _authService.signOut();
  }
}
