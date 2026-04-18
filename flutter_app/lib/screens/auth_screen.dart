import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Inserisci email e password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.onAuthenticated();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _errorMessage(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Inserisci email e password');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'La password deve avere almeno 6 caratteri');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      widget.onAuthenticated();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _errorMessage(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Questa email è già registrata.';
      case 'invalid-email': return 'Inserisci un indirizzo email valido.';
      case 'user-not-found': return 'Nessun account trovato con questa email.';
      case 'wrong-password': return 'Password errata. Riprova.';
      case 'weak-password': return 'La password deve avere almeno 6 caratteri.';
      case 'too-many-requests': return 'Troppi tentativi. Riprova più tardi.';
      case 'invalid-credential': return 'Email o password non validi.';
      default: return 'Si è verificato un errore. Riprova.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0b0f17), Color(0xFF1a1f2e)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🫶', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  const Text(
                    'La Distanza Non Conta',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accedi per usare il tuo tracker',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 32),
                  _buildInput('Email', _emailController, TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _buildInput('Password', _passwordController, TextInputType.text, obscure: true),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Color(0xFFf87171), fontSize: 14)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFff6b9d),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_loading ? 'Attendere...' : 'Accedi',
                          style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _signUp,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFff6b9d)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_loading ? 'Attendere...' : 'Crea Account',
                          style: const TextStyle(fontSize: 16, color: Color(0xFFff6b9d))),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'I tuoi dati sono protetti con crittografia end-to-end 🔒',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, TextInputType type, {bool obscure = false}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFff6b9d)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
