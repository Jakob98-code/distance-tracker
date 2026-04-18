import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PinScreen({super.key, required this.onUnlocked});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  bool _isSettingPin = false;
  String? _confirmPin;
  String? _error;
  String? _savedHash;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedHash = prefs.getString('appPinHash');
      _isSettingPin = _savedHash == null;
    });
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  void _onKeyPress(String key) {
    if (key == 'delete') {
      if (_pin.isNotEmpty) {
        setState(() {
          _pin = _pin.substring(0, _pin.length - 1);
          _error = null;
        });
      }
      return;
    }

    if (_pin.length >= 4) return;
    setState(() {
      _pin += key;
      _error = null;
    });

    if (_pin.length == 4) {
      _handlePinComplete();
    }
  }

  Future<void> _handlePinComplete() async {
    if (_isSettingPin) {
      if (_confirmPin == null) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
        });
      } else {
        if (_pin == _confirmPin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('appPinHash', _hashPin(_pin));
          widget.onUnlocked();
        } else {
          setState(() {
            _error = 'I PIN non corrispondono. Riprova.';
            _confirmPin = null;
            _pin = '';
          });
        }
      }
    } else {
      if (_hashPin(_pin) == _savedHash) {
        widget.onUnlocked();
      } else {
        setState(() {
          _error = 'PIN errato. Riprova.';
          _pin = '';
        });
      }
    }
  }

  String get _title {
    if (_isSettingPin) {
      return _confirmPin == null ? 'Crea PIN' : 'Conferma PIN';
    }
    return 'Inserisci PIN';
  }

  String get _subtitle {
    if (_isSettingPin) {
      return _confirmPin == null
          ? 'Scegli un PIN a 4 cifre per proteggere l\'app'
          : 'Inserisci di nuovo il PIN per confermare';
    }
    return 'Inserisci il tuo PIN a 4 cifre per sbloccare';
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(_title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(_subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                ),
                const SizedBox(height: 24),
                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? const Color(0xFFff6b9d) : Colors.transparent,
                        border: Border.all(
                          color: filled ? const Color(0xFFff6b9d) : Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: filled
                            ? [BoxShadow(color: const Color(0xFFff6b9d).withValues(alpha: 0.5), blurRadius: 10)]
                            : null,
                      ),
                    );
                  }),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Color(0xFFf87171), fontSize: 14)),
                ],
                const SizedBox(height: 32),
                // Keypad
                SizedBox(
                  width: 260,
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => _keyButton(n.toString())),
                      const SizedBox(),
                      _keyButton('0'),
                      _keyButton('delete', label: '⌫'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyButton(String key, {String? label}) {
    return GestureDetector(
      onTap: () => _onKeyPress(key),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          label ?? key,
          style: TextStyle(
            fontSize: key == 'delete' ? 24 : 28,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
