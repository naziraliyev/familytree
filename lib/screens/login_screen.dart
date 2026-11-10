import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isRegister) {
        await AuthService.register(_name.text, _email.text, _password.text);
      } else {
        await AuthService.signIn(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) showSnack(context, AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showSnack(context, 'Avval email manzilingizni kiriting.');
      return;
    }
    try {
      await AuthService.resetPassword(email);
      if (mounted) {
        showSnack(context, 'Parolni tiklash havolasi $email ga yuborildi.');
      }
    } catch (e) {
      if (mounted) showSnack(context, AuthService.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.account_tree_rounded,
                        size: 80, color: scheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Oila Daraxti',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRegister
                          ? 'Yangi hisob yaratish'
                          : 'Hisobingizga kiring',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    if (_isRegister) ...[
                      TextFormField(
                        key: const ValueKey('name'),
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Ismingiz',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ismingizni kiriting'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      key: const ValueKey('email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'To\'g\'ri email kiriting'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('password'),
                      controller: _password,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Parol',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Parol kamida 6 belgidan iborat bo\'lsin'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (!_isRegister)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Parolni unutdingizmi?'),
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isRegister
                              ? 'Ro\'yxatdan o\'tish'
                              : 'Kirish'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              // Xato matnlarini tozalaymiz, kiritilgan email/parol qoladi
                              final email = _email.text;
                              final password = _password.text;
                              _formKey.currentState?.reset();
                              _email.text = email;
                              _password.text = password;
                              setState(() => _isRegister = !_isRegister);
                            },
                      child: Text(_isRegister
                          ? 'Hisobingiz bormi? Kirish'
                          : 'Hisobingiz yo\'qmi? Ro\'yxatdan o\'ting'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
