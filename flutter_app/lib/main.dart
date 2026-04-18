import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:distanza_app/screens/auth_screen.dart';
import 'package:distanza_app/screens/pin_screen.dart';
import 'package:distanza_app/screens/home_screen.dart';
import 'package:distanza_app/screens/setup_screen.dart';
import 'package:distanza_app/services/config_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DistanzaApp());
}

class DistanzaApp extends StatelessWidget {
  const DistanzaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Distanza Non Conta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0b0f17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFff6b9d),
          secondary: Color(0xFFc44569),
          surface: Color(0xFF1a1f2e),
        ),
        fontFamily: 'sans-serif',
      ),
      home: const AppGate(),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  bool _loading = true;
  bool _authenticated = false;
  bool _pinUnlocked = false;
  bool _hasConfig = false;

  @override
  void initState() {
    super.initState();
    _checkState();
  }

  Future<void> _checkState() async {
    final config = await ConfigService.loadConfig();
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _hasConfig = config != null;
      _authenticated = user != null;
      _loading = false;
    });
  }

  void _onAuthenticated() {
    setState(() => _authenticated = true);
  }

  void _onPinUnlocked() {
    setState(() => _pinUnlocked = true);
  }

  void _onSetupComplete() {
    setState(() => _hasConfig = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authenticated) {
      return AuthScreen(onAuthenticated: _onAuthenticated);
    }

    if (!_pinUnlocked) {
      return PinScreen(onUnlocked: _onPinUnlocked);
    }

    if (!_hasConfig) {
      return SetupScreen(onSetupComplete: _onSetupComplete);
    }

    return const HomeScreen();
  }
}
