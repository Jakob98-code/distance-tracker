import 'package:flutter/material.dart';
import 'package:distanza_app/services/config_service.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;
  const SetupScreen({super.key, required this.onSetupComplete});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _person1Controller = TextEditingController(text: 'Jakob');
  final _person2Controller = TextEditingController(text: 'Desy');
  final _coupleIdController = TextEditingController(text: 'jakob-desy-2025');
  String _whoAmI = 'person1';

  Future<void> _save() async {
    final config = AppConfig(
      person1Name: _person1Controller.text.isEmpty ? 'Persona 1' : _person1Controller.text,
      person2Name: _person2Controller.text.isEmpty ? 'Persona 2' : _person2Controller.text,
      coupleId: _coupleIdController.text.isEmpty ? 'default-couple' : _coupleIdController.text,
      whoAmI: _whoAmI,
    );
    await ConfigService.saveConfig(config);
    widget.onSetupComplete();
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Text('🔧 Configurazione',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('Inserisci i tuoi dati per iniziare',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                ),
                const SizedBox(height: 32),
                _buildField('Il Tuo Nome', _person1Controller),
                const SizedBox(height: 16),
                _buildField('Nome del Partner', _person2Controller),
                const SizedBox(height: 16),
                _buildField('ID Coppia Unico', _coupleIdController),
                const SizedBox(height: 4),
                Text('Condividi questo ID con il tuo partner',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                const SizedBox(height: 20),
                Text('Chi sei tu?',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 8),
                _buildRadio('Persona 1 (primo nome)', 'person1'),
                _buildRadio('Persona 2 (partner)', 'person2'),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFff6b9d),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Salva e Inizia', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
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

  Widget _buildRadio(String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      groupValue: _whoAmI,
      activeColor: const Color(0xFFff6b9d),
      onChanged: (v) => setState(() => _whoAmI = v!),
    );
  }

  @override
  void dispose() {
    _person1Controller.dispose();
    _person2Controller.dispose();
    _coupleIdController.dispose();
    super.dispose();
  }
}
