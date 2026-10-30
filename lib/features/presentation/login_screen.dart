import 'package:flutter/material.dart';
import '/features/authentication/data/auth_repository.dart';
import '../../errors/login_auth_error_messages.dart';
import '../../errors/login_instant_feedback.dart';

// Placeholder login screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authRepository, // injected, so tests can pass a fake
    this.onSuccess,
  });

  final AuthRepository authRepository;
  final VoidCallback? onSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // lets us call validate()
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false; // true while waiting for Firebase
  String? _error; // red message shown above the buttons

  @override
  void dispose() {
    // Free the controllers when the screen is closed
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // LOGIN
  Future<void> _submit() async {
    // Run the validators
    if (!_formKey.currentState!.validate()) return;

    // Show the spinner and clear old messages
    setState(() {
      _loading = true;
      _error = null;
    });

    String? error;
    try {
      await widget.authRepository.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } catch (e) {
      // Catches any error, not only Firebase ones, so the app never crashes
      error = friendlyAuthError(e);
    }

    // The user may have left the screen while we waited
    if (!mounted) return;

    setState(() {
      _loading = false;
      _error = error;
    });

    if (error == null) widget.onSuccess?.call();
  }

  // TODO: implement forgot password / first-time password setup

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            // Keeps the form a sensible width on wide screens (Chrome)
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Email field
                  TextFormField(
                    key: const Key('email_field'), // keys let tests find it
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    key: const Key('password_field'),
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        key: const Key('error_message'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),

                  // Login button: disabled with a spinner while loading
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('login_button'),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Log in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
