import 'dart:async';
import 'dart:io' show Platform;

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
  static const _firebaseSessionHintKey = 'super_sol_firebase_session_user_id';

  static const _androidRestoreGracePeriod = Duration(seconds: 5);
  static const _initialAndroidRestoreGracePeriod = Duration(seconds: 2);

  SharedPreferences? _preferences;
  bool _firebaseReady = false;
  User? _firebaseUser;
  StreamSubscription<User?>? _firebaseAuthStateSubscription;

  bool get firebaseReady => _firebaseReady;

  String? get currentEmail {
    if (_firebaseReady) {
      return _firebaseUser?.email;
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
        ? _firebaseUser?.displayName?.trim()
        : null;
    final localName = _preferences?.getString(_displayNameKey)?.trim();
    final name = firebaseName?.isNotEmpty == true ? firebaseName : localName;
    if (name != null && name.isNotEmpty) return name;
    return currentEmail?.split('@').first.trim() ?? 'TÀI KHOẢN';
  }

  String? get firebaseUserId => _firebaseReady ? _firebaseUser?.uid : null;

  String get dataScope {
    if (_firebaseReady) {
      return _firebaseUser?.uid ?? 'guest';
    }
    return currentEmail ?? 'guest';
  }

  Future<void> initialize() async {
    await _firebaseAuthStateSubscription?.cancel();
    _firebaseAuthStateSubscription = null;
    _preferences = await SharedPreferences.getInstance();
    _firebaseReady = false;
    _firebaseUser = null;
    try {
      await Firebase.initializeApp();
      if (Firebase.apps.isEmpty) {
        return;
      }

      final preferences = _preferences!;
      final hasFirebaseSessionHint = preferences.containsKey(
        _firebaseSessionHintKey,
      );
      _firebaseReady = true;
      final firstAuthState = Completer<User?>();
      final restoredUser = Completer<User?>();

      // Android can report one initial signed-out event while the native
      // credential store is still being restored. Keep the listener alive and
      // give a previously authenticated account a brief chance to arrive,
      // instead of permanently starting the app as a guest.
      _firebaseAuthStateSubscription = FirebaseAuth.instance
          .authStateChanges()
          .listen(
            (user) {
              _firebaseUser = user;
              debugPrint(
                'AuthService: Firebase auth state is '
                '${user == null ? 'signed-out' : 'signed-in'}.',
              );
              if (user != null) {
                unawaited(_cacheFirebaseSessionHint(user));
                if (!restoredUser.isCompleted) restoredUser.complete(user);
              }
              if (!firstAuthState.isCompleted) firstAuthState.complete(user);
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('AuthService: Firebase auth stream error: $error');
              if (!firstAuthState.isCompleted) firstAuthState.complete(null);
              if (!restoredUser.isCompleted) restoredUser.complete(null);
            },
          );

      final initialUser = await firstAuthState.future;
      if (initialUser == null && Platform.isAndroid) {
        _firebaseUser = await restoredUser.future.timeout(
          hasFirebaseSessionHint
              ? _androidRestoreGracePeriod
              : _initialAndroidRestoreGracePeriod,
          onTimeout: () => null,
        );
        if (_firebaseUser == null && hasFirebaseSessionHint) {
          // No later authenticated state means Firebase has genuinely signed
          // the account out (for example after a server-side revocation).
          await preferences.remove(_firebaseSessionHintKey);
          debugPrint('AuthService: Firebase session was not restored.');
        }
      }
    } catch (error) {
      debugPrint('AuthService: Firebase initialization failed: $error');
      _firebaseReady = false;
      _firebaseUser = null;
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
        UserCredential credential;
        if (mode == AuthMode.register) {
          credential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: normalizedEmail,
                password: password,
              );
          await credential.user?.updateDisplayName(normalizedDisplayName);
        } else {
          credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
        }
        _firebaseUser = credential.user;
        if (_firebaseUser != null) {
          await _cacheFirebaseSessionHint(_firebaseUser!);
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
      _firebaseUser = null;
    }
    await _preferences?.setBool(_sessionKey, false);
    await _preferences?.remove(_firebaseSessionHintKey);
  }

  Future<void> _cacheFirebaseSessionHint(User user) async {
    await _preferences?.setString(_firebaseSessionHintKey, user.uid);
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

@visibleForTesting
Future<T> waitForInitialFirebaseAuthState<T>(Stream<T> states) => states.first;
