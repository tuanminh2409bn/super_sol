import 'package:flutter/material.dart';

import '../core/auth_service.dart';

Future<bool> showAuthSheet(
  BuildContext context, {
  required AuthService auth,
  AuthMode initialMode = AuthMode.signIn,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AuthSheet(
      auth: auth,
      initialMode: initialMode,
      reauthenticateOnly: false,
    ),
  );
  return result ?? false;
}

Future<bool> showFirebaseReauthenticationSheet(
  BuildContext context, {
  required AuthService auth,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AuthSheet(
      auth: auth,
      initialMode: AuthMode.signIn,
      reauthenticateOnly: true,
    ),
  );
  return result ?? false;
}

class _AuthSheet extends StatefulWidget {
  const _AuthSheet({
    required this.auth,
    required this.initialMode,
    required this.reauthenticateOnly,
  });

  final AuthService auth;
  final AuthMode initialMode;
  final bool reauthenticateOnly;

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AuthMode _mode = widget.initialMode;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.reauthenticateOnly) {
      _emailController.text = widget.auth.currentEmail ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = widget.reauthenticateOnly
        ? await widget.auth.reauthenticate(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await widget.auth.authenticate(
            mode: _mode,
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _mode == AuthMode.register
                ? _displayNameController.text
                : null,
          );
    if (!mounted) return;
    if (result.ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _message = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 18, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9DDE5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.reauthenticateOnly
                  ? 'Xác thực tài khoản Firebase'
                  : _mode == AuthMode.signIn
                  ? 'Đăng nhập'
                  : 'Tạo tài khoản',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF11141B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.reauthenticateOnly
                  ? 'Nhập lại mật khẩu của đúng tài khoản đang đăng nhập để đặt lại PIN.'
                  : widget.auth.firebaseReady
                  ? 'Tài khoản được bảo vệ bởi Firebase Authentication.'
                  : 'Chế độ phát triển cục bộ — thêm cấu hình Firebase để dùng production.',
              style: const TextStyle(
                color: Color(0xFF697080),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            if (_mode == AuthMode.register) ...[
              TextField(
                key: const Key('register-display-name'),
                controller: _displayNameController,
                textCapitalization: TextCapitalization.words,
                autocorrect: false,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Tên tài khoản hiển thị',
                  hintText: 'Ví dụ: TRINH TRUN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              key: const Key('auth-email'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              readOnly: widget.reauthenticateOnly,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('auth-password'),
              controller: _passwordController,
              obscureText: true,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                style: const TextStyle(color: Color(0xFFD83B45), fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              key: widget.reauthenticateOnly
                  ? const Key('reauthenticate-submit')
                  : const Key('authenticate-submit'),
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF075FF7),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.reauthenticateOnly
                          ? 'Xác nhận'
                          : _mode == AuthMode.signIn
                          ? 'Đăng nhập'
                          : 'Đăng ký',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            if (!widget.reauthenticateOnly)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _mode = _mode == AuthMode.signIn
                            ? AuthMode.register
                            : AuthMode.signIn;
                        _message = null;
                      }),
                child: Text(
                  _mode == AuthMode.signIn
                      ? 'Chưa có tài khoản? Đăng ký'
                      : 'Đã có tài khoản? Đăng nhập',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
