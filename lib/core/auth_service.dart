import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthMode { signIn, register }

class AuthResult {
  const AuthResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}

/// Uses Firebase Auth when native Firebase configuration is present.
///
/// Until `google-services.json` / `GoogleService-Info.plist` are added, the
/// app remains fully testable with a deliberately small local-development
/// fallback. The fallback never stores the clear-text password.
class AuthService {
  static const _emailKey = 'super_sol_local_email';
  static const _passwordKey = 'super_sol_local_password_digest';
  static const _displayNameKey = 'super_sol_local_display_name';
  static const _sessionKey = 'super_sol_local_session';

  SharedPreferences? _preferences;
  bool _firebaseReady = false;

  bool get firebaseReady => _firebaseReady;

  String? get currentEmail {
    if (_firebaseReady) {
      return FirebaseAuth.instance.currentUser?.email;
    }
    if (_preferences?.getBool(_sessionKey) ?? false) {
      return _preferences?.getString(_emailKey);
    }
    return null;
  }

  bool get isSignedIn => currentEmail != null;

  /// The name supplied when the account was registered. It is intentionally
  /// separate from the email address because this is the name shown in the UI.
  String get displayName {
    final firebaseName = _firebaseReady
        ? FirebaseAuth.instance.currentUser?.displayName?.trim()
        : null;
    final localName = _preferences?.getString(_displayNameKey)?.trim();
    final name = firebaseName?.isNotEmpty == true ? firebaseName : localName;
    if (name != null && name.isNotEmpty) return name;
    return currentEmail?.split('@').first.trim() ?? 'TÀI KHOẢN';
  }

  String? get firebaseUserId =>
      _firebaseReady ? FirebaseAuth.instance.currentUser?.uid : null;

  String get dataScope {
    if (_firebaseReady) {
      return FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    }
    return currentEmail ?? 'guest';
  }

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    try {
      await Firebase.initializeApp();
      _firebaseReady = Firebase.apps.isNotEmpty;
    } catch (_) {
      _firebaseReady = false;
    }
    if (_firebaseReady) {
      try {
        // Firebase initialization and native credential restoration are two
        // separate steps. Waiting for the first auth event prevents startup
        // from briefly selecting the guest data scope for a returning user.
        await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 3),
        );
      } on TimeoutException {
        // Keep Firebase enabled if native restoration is unusually slow. The
        // auth plugin can still finish restoring its cached user afterward.
      }
    }
  }

  Future<AuthResult> authenticate({
    required AuthMode mode,
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedDisplayName = displayName?.trim() ?? '';
    if (!normalizedEmail.contains('@')) {
      return const AuthResult(
        ok: false,
        message: 'Vui lòng nhập địa chỉ email hợp lệ.',
      );
    }
    if (password.length < 6) {
      return const AuthResult(
        ok: false,
        message: 'Mật khẩu cần có ít nhất 6 ký tự.',
      );
    }
    if (mode == AuthMode.register && normalizedDisplayName.isEmpty) {
      return const AuthResult(
        ok: false,
        message: 'Vui lòng nhập tên tài khoản hiển thị.',
      );
    }

    if (_firebaseReady) {
      try {
        if (mode == AuthMode.register) {
          final credential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: normalizedEmail,
                password: password,
              );
          await credential.user?.updateDisplayName(normalizedDisplayName);
        } else {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
        }
        return AuthResult(
          ok: true,
          message: mode == AuthMode.register
              ? 'Đăng ký thành công.'
              : 'Đăng nhập thành công.',
        );
      } on FirebaseAuthException catch (error) {
        return AuthResult(ok: false, message: _firebaseMessage(error.code));
      } catch (_) {
        return const AuthResult(
          ok: false,
          message: 'Không thể kết nối Firebase. Vui lòng thử lại.',
        );
      }
    }

    if (!kDebugMode) {
      return const AuthResult(
        ok: false,
        message: 'Firebase chưa khởi tạo. Vui lòng kiểm tra kết nối mạng.',
      );
    }

    final preferences = _preferences!;
    if (mode == AuthMode.register) {
      await preferences.setString(_emailKey, normalizedEmail);
      await preferences.setString(_passwordKey, _digest(password));
      await preferences.setString(_displayNameKey, normalizedDisplayName);
      await preferences.setBool(_sessionKey, true);
      return const AuthResult(
        ok: true,
        message: 'Đăng ký thành công ở chế độ phát triển.',
      );
    }

    final savedEmail = preferences.getString(_emailKey);
    final savedDigest = preferences.getString(_passwordKey);
    if (savedEmail != normalizedEmail || savedDigest != _digest(password)) {
      return const AuthResult(
        ok: false,
        message: 'Email hoặc mật khẩu không đúng.',
      );
    }
    await preferences.setBool(_sessionKey, true);
    return const AuthResult(
      ok: true,
      message: 'Đăng nhập thành công ở chế độ phát triển.',
    );
  }

  Future<void> signOut() async {
    if (_firebaseReady) {
      await FirebaseAuth.instance.signOut();
    }
    await _preferences?.setBool(_sessionKey, false);
  }

  String _digest(String value) {
    // Deterministic FNV-1a digest for the local UI-development fallback only.
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _firebaseMessage(String code) {
    return switch (code) {
      'email-already-in-use' => 'Email này đã được đăng ký.',
      'invalid-email' => 'Địa chỉ email không hợp lệ.',
      'weak-password' => 'Mật khẩu chưa đủ mạnh.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email hoặc mật khẩu không đúng.',
      'network-request-failed' => 'Không có kết nối mạng.',
      'operation-not-allowed' =>
        'Email/Password chưa được bật trong Firebase Authentication.',
      _ => 'Xác thực thất bại ($code).',
    };
  }
}
