import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:distanza_app/services/config_service.dart';
import 'package:distanza_app/services/widget_service.dart';
import 'package:distanza_app/widgets/distance_visual.dart';
import 'package:distanza_app/widgets/stat_card.dart';
import 'package:distanza_app/widgets/location_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppConfig? _config;
  final _db = FirebaseDatabase.instance;
  final _mapController = MapController();

  // Location data
  Map<String, dynamic>? _loc1;
  Map<String, dynamic>? _loc2;
  double? _distance;
  String? _nextMeetDate;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();

  // Relationship
  final _relationshipStart = DateTime(2025, 2, 28);

  // Thinking of you
  bool _thinkingSent = false;
  String? _thinkingReceived;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    final config = await ConfigService.loadConfig();
    if (config == null) return;
    setState(() => _config = config);

    _listenLocations();
    _listenNextMeetDate();
    _listenThinkingOfYou();
    _startCountdown();

    // Push config to native widget
    WidgetService.updateWidgetData(
      coupleId: config.coupleId,
      person1Name: config.person1Name,
      person2Name: config.person2Name,
    );

    // Auto-resume tracking
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('autoTracking') == true) {
      _startTracking();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isTracking) {
      _startTracking();
    }
  }

  void _listenLocations() {
    final ref = _db.ref('couples/${_config!.coupleId}/locations');
    ref.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      setState(() {
        if (data['person1'] != null) {
          _loc1 = Map<String, dynamic>.from(data['person1'] as Map);
        }
        if (data['person2'] != null) {
          _loc2 = Map<String, dynamic>.from(data['person2'] as Map);
        }
        if (_loc1 != null && _loc2 != null) {
          _distance = _haversineKm(
            _loc1!['lat'], _loc1!['lon'],
            _loc2!['lat'], _loc2!['lon'],
          );
        }
      });
    });
  }

  void _listenNextMeetDate() {
    final ref = _db.ref('couples/${_config!.coupleId}/nextMeetDate');
    ref.onValue.listen((event) {
      setState(() {
        _nextMeetDate = event.snapshot.value as String?;
      });
    });
  }

  void _listenThinkingOfYou() {
    final ref = _db.ref('couples/${_config!.coupleId}/notifications');
    ref.orderByChild('to').equalTo(_config!.whoAmI).limitToLast(1).onChildAdded.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (data['read'] == true) return;
      if (DateTime.now().millisecondsSinceEpoch - (data['timestamp'] as int) > 30000) return;

      event.snapshot.ref.update({'read': true});
      setState(() => _thinkingReceived = '💕 ${data['senderName']} sta pensando a te!');
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _thinkingReceived = null);
      });
    });
  }

  Future<void> _startTracking() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      if (result == LocationPermission.denied || result == LocationPermission.deniedForever) return;
    }

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((pos) {
      _updateMyLocation(pos.latitude, pos.longitude, pos.accuracy);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoTracking', true);
    setState(() => _isTracking = true);
  }

  void _stopTracking() async {
    _positionStream?.cancel();
    _positionStream = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoTracking', false);
    setState(() => _isTracking = false);
  }

  Future<void> _updateMyLocation(double lat, double lon, double accuracy) async {
    final ref = _db.ref('couples/${_config!.coupleId}/locations/${_config!.whoAmI}');
    await ref.set({
      'lat': lat,
      'lon': lon,
      'accuracy': accuracy,
      'timestamp': ServerValue.timestamp,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updateLocationOnce() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _updateMyLocation(pos.latitude, pos.longitude, pos.accuracy);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Posizione aggiornata!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Errore ottenimento posizione')),
        );
      }
    }
  }

  Future<void> _sendThinkingOfYou() async {
    setState(() => _thinkingSent = true);
    await _db.ref('couples/${_config!.coupleId}/notifications').push().set({
      'type': 'thinking-of-you',
      'from': _config!.whoAmI,
      'to': _config!.partnerKey,
      'senderName': _config!.myName,
      'message': '${_config!.myName} sta pensando a te 💕',
      'timestamp': ServerValue.timestamp,
      'read': false,
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _thinkingSent = false);
    });
  }

  Future<void> _saveNextMeetDate(String? date) async {
    final ref = _db.ref('couples/${_config!.coupleId}/nextMeetDate');
    if (date != null) {
      await ref.set(date);
    } else {
      await ref.remove();
    }
  }

  Future<void> _pickMeetDate() async {
    final initial = _nextMeetDate != null ? DateTime.tryParse(_nextMeetDate!) : null;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFff6b9d),
              surface: Color(0xFF1a1f2e),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _saveNextMeetDate(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  void _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('appPinHash');
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _ReloadApp()),
        (_) => false,
      );
    }
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * asin(sqrt(a));
  }

  double _toRad(double deg) => deg * pi / 180;

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '--';
    final ms = timestamp is int ? timestamp : 0;
    final seconds = (DateTime.now().millisecondsSinceEpoch - ms) ~/ 1000;
    if (seconds < 60) return 'Proprio ora';
    if (seconds < 3600) return '${seconds ~/ 60} min fa';
    if (seconds < 86400) return '${seconds ~/ 3600} ore fa';
    return '${seconds ~/ 86400} giorni fa';
  }

  Widget _buildCountdown() {
    if (_nextMeetDate == null) {
      return const Text('Presto ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFff6b9d)));
    }
    final meetDate = DateTime.tryParse(_nextMeetDate!);
    if (meetDate == null) {
      return const Text('Presto ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFff6b9d)));
    }
    final diff = meetDate.difference(_now);
    if (diff.isNegative) {
      return const Text('Presto ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFff6b9d)));
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    return Text(
      '${days}g ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFff6b9d)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_config == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final daysTogether = _now.difference(_relationshipStart).inDays;
    final distanceRounded = _distance?.round();

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Text('La Distanza Non Conta 🫶',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Tracker in tempo reale per ${_config!.person1Name} & ${_config!.person2Name}',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 16),

                // Map
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 220,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _loc1 != null
                            ? LatLng(_loc1!['lat'], _loc1!['lon'])
                            : const LatLng(50, 10),
                        initialZoom: 4,
                      ),
                      children: [
                        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                        if (_loc1 != null && _loc2 != null)
                          PolylineLayer(polylines: <Polyline<Object>>[
                            Polyline(
                              points: [
                                LatLng(_loc1!['lat'], _loc1!['lon']),
                                LatLng(_loc2!['lat'], _loc2!['lon']),
                              ],
                              color: const Color(0xFFff6b9d),
                              strokeWidth: 2,
                              pattern: const StrokePattern.dotted(),
                            ),
                          ]),
                        MarkerLayer(markers: [
                          if (_loc1 != null)
                            Marker(
                              point: LatLng(_loc1!['lat'], _loc1!['lon']),
                              child: const Text('📍', style: TextStyle(fontSize: 28)),
                            ),
                          if (_loc2 != null)
                            Marker(
                              point: LatLng(_loc2!['lat'], _loc2!['lon']),
                              child: const Text('💕', style: TextStyle(fontSize: 28)),
                            ),
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Distance visual
                _buildCard(
                  child: Column(
                    children: [
                      Text(
                        distanceRounded != null ? 'La nostra distanza: $distanceRounded km' : 'La nostra distanza: -- km',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(height: 12),
                      DistanceVisual(
                        initial1: _config!.person1Name[0].toUpperCase(),
                        initial2: _config!.person2Name[0].toUpperCase(),
                      ),
                      if (distanceRounded == 0) ...[
                        const SizedBox(height: 12),
                        const Text('Siamo insieme! 🫶💕',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4ade80))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Giorni Insieme',
                        child: Text('$daysTogether',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickMeetDate,
                        child: StatCard(
                          label: 'Prossimo Incontro',
                          child: Column(
                            children: [
                              _buildCountdown(),
                              if (_nextMeetDate != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('d MMMM yyyy', 'it').format(DateTime.parse(_nextMeetDate!)),
                                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _nextMeetDate != null ? 'Tocca per modificare' : 'Tocca per impostare',
                                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic,
                                    color: Colors.white.withValues(alpha: 0.4)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location cards
                Row(
                  children: [
                    Expanded(child: LocationCard(
                      name: _config!.person1Name, data: _loc1, timeAgo: _timeAgo)),
                    const SizedBox(width: 12),
                    Expanded(child: LocationCard(
                      name: _config!.person2Name, data: _loc2, timeAgo: _timeAgo)),
                  ],
                ),
                const SizedBox(height: 12),

                // Thinking of you
                _buildCard(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _thinkingSent ? null : _sendThinkingOfYou,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFff6b9d),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _thinkingSent ? '💕 Inviato!' : '💕 Sto Pensando a Te',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      if (_thinkingReceived != null) ...[
                        const SizedBox(height: 12),
                        Text(_thinkingReceived!,
                            style: const TextStyle(fontSize: 16, color: Color(0xFFff6b9d))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Controls
                _buildCard(
                  child: Column(
                    children: [
                      _controlButton('📍 Aggiorna la Mia Posizione', _updateLocationOnce),
                      const SizedBox(height: 8),
                      _controlButton(
                        _isTracking ? '⏹️ Ferma Tracciamento Auto' : '🔄 Avvia Tracciamento Auto',
                        _isTracking ? _stopTracking : _startTracking,
                      ),
                      const SizedBox(height: 8),
                      _controlButton('⚙️ Impostazioni', () {
                        // TODO: open settings
                      }, ghost: true),
                      const SizedBox(height: 8),
                      _controlButton('🚪 Esci', _signOut, ghost: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Love note
                _buildCard(
                  child: Column(
                    children: [
                      const Text('I chilometri ci separano.\nMa non cambiano quello che sento per te.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Ogni giorno più vicini, anche quando siamo lontani. Ti mando un bacio lungo quanto la distanza tra noi. ❤️',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _controlButton(String label, VoidCallback onPressed, {bool ghost = false}) {
    if (ghost) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onPressed,
          child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _countdownTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

// Helper to restart the app after sign out
class _ReloadApp extends StatelessWidget {
  const _ReloadApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
  }
}
