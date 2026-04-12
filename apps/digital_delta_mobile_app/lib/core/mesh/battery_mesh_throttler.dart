import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Module 8.4 — Battery-Aware Mesh Throttling
//
// Dynamically adjusts the BLE mesh broadcast/scan interval based on:
//   • Battery level  < 30 %  → reduce frequency by 60 %
//   • Stationary state       → reduce frequency by 80 %  (cumulative)
//   • Near known node        → reduce frequency by 50 %  (additional)
//
// Base scan interval: 4 s   |   Maximum idle interval: 30 s
// ---------------------------------------------------------------------------

class ThrottleEvent {
  final DateTime ts;
  final int batteryPct;
  final double throttleFactor; // 1.0 = full speed, 0.0 = off
  final int intervalSecs;
  final List<String> activeRules;
  final double estimatedMaSaved; // milliamp-seconds saved vs unthrottled

  const ThrottleEvent({
    required this.ts,
    required this.batteryPct,
    required this.throttleFactor,
    required this.intervalSecs,
    required this.activeRules,
    required this.estimatedMaSaved,
  });
}

class ThrottleStats {
  final int totalEvents;
  final int totalScansSaved;
  final double totalEnergySavedMaS;
  final double avgThrottleFactor;
  final Duration simDuration;

  const ThrottleStats({
    required this.totalEvents,
    required this.totalScansSaved,
    required this.totalEnergySavedMaS,
    required this.avgThrottleFactor,
    required this.simDuration,
  });

  /// kJ saved (rough estimate: BLE scan ≈ 15 mA peak, 100 ms window)
  double get energySavedMj => totalEnergySavedMaS * 3.6;
}

class BatteryMeshThrottler extends ChangeNotifier {
  // ── Config ─────────────────────────────────────────────────────────────────
  static const int _baseSecs = 4;
  static const int _maxSecs = 30;
  static const double _mAPerScan = 15.0; // mA peak during a 100 ms BLE scan
  static const double _scanWindowSecs = 0.1;

  // ── State ──────────────────────────────────────────────────────────────────
  int _batteryLevel = 100;
  bool _isCharging = false;
  bool _isStationary = false; // set externally (accelerometer / timer)
  bool _nearKnownNode = false; // set externally (peer detected recently)
  final List<ThrottleEvent> _log = [];
  Timer? _stationaryTimer;
  Timer? _monitorTimer;
  DateTime? _simStart;
  bool _isSimulating = false;

  final Battery _battery = Battery();

  // ── Public API ─────────────────────────────────────────────────────────────

  int get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;
  bool get isStationary => _isStationary;
  bool get nearKnownNode => _nearKnownNode;
  List<ThrottleEvent> get log => List.unmodifiable(_log);
  bool get isSimulating => _isSimulating;

  /// Current recommended scan interval in seconds.
  int get currentIntervalSecs => _computeInterval().intervalSecs;

  /// Current throttle factor (1.0 = no throttle, 0.1 = 90% reduction).
  double get throttleFactor => _computeInterval().throttleFactor;

  // ── Throttle computation ──────────────────────────────────────────────────

  ({double throttleFactor, int intervalSecs, List<String> activeRules}) _computeInterval() {
    double factor = 1.0;
    final rules = <String>[];

    if (_batteryLevel < 30 && !_isCharging) {
      factor *= 0.40; // 60 % reduction
      rules.add('battery<30% → ×0.4');
    }

    if (_isStationary) {
      factor *= 0.20; // 80 % additional reduction
      rules.add('stationary → ×0.2');
    }

    if (_nearKnownNode) {
      factor *= 0.50; // 50 % reduction when already near a peer
      rules.add('near_node → ×0.5');
    }

    // Clamp to a sane minimum (don't turn off entirely)
    factor = factor.clamp(0.04, 1.0);

    final intervalSecs = (_baseSecs / factor).round().clamp(_baseSecs, _maxSecs);
    return (throttleFactor: factor, intervalSecs: intervalSecs, activeRules: rules);
  }

  /// Milliamp-seconds saved per throttle event vs base interval.
  double _energySavedMaS(int intervalSecs) {
    // Unthrottled: 1 scan per _baseSecs → scansPerSec = 1/_baseSecs
    // Throttled:   1 scan per intervalSecs
    final baseScansPerMin = 60.0 / _baseSecs;
    final throttledScansPerMin = 60.0 / intervalSecs;
    final scansSavedPerMin = baseScansPerMin - throttledScansPerMin;
    return scansSavedPerMin * _mAPerScan * _scanWindowSecs * 60; // over 1 min
  }

  // ── Battery monitoring ────────────────────────────────────────────────────

  Future<void> startMonitoring() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      _isCharging = state == BatteryState.charging || state == BatteryState.full;
    } catch (_) {
      // emulator or permission denied — use defaults
    }

    _battery.onBatteryStateChanged.listen((state) {
      _isCharging = state == BatteryState.charging || state == BatteryState.full;
      _updateAndNotify();
    });

    // Poll battery level every 30 s (battery_plus doesn't stream level)
    _monitorTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        _batteryLevel = await _battery.batteryLevel;
        _updateAndNotify();
      } catch (_) {}
    });
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _stationaryTimer?.cancel();
  }

  void setStationary(bool value) {
    _isStationary = value;
    _updateAndNotify();
  }

  void setNearKnownNode(bool value) {
    _nearKnownNode = value;
    _updateAndNotify();
  }

  void _updateAndNotify() {
    final res = _computeInterval();
    _log.add(ThrottleEvent(
      ts: DateTime.now(),
      batteryPct: _batteryLevel,
      throttleFactor: res.throttleFactor,
      intervalSecs: res.intervalSecs,
      activeRules: res.activeRules,
      estimatedMaSaved: _energySavedMaS(res.intervalSecs),
    ));
    notifyListeners();
  }

  // ── 10-minute simulation (M8.4 demo) ─────────────────────────────────────

  /// Run a simulated 10-minute battery drain + throttling scenario.
  /// Returns summarized stats once complete.
  Future<ThrottleStats> runSimulation() async {
    if (_isSimulating) throw StateError('Simulation already running');
    _isSimulating = true;
    _simStart = DateTime.now();
    _log.clear();
    notifyListeners();

    // Simulate 10 min in compressed time (20 ticks × 30 s each = 600 s)
    // Each tick = 1.5 s real time for demo responsiveness
    const ticks = 20;
    final scenario = _buildSimulationScenario();

    for (int i = 0; i < ticks; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_isSimulating) break;

      final s = scenario[i];
      _batteryLevel = s.battery;
      _isStationary = s.stationary;
      _nearKnownNode = s.nearNode;

      _updateAndNotify();
    }

    _isSimulating = false;
    final stats = _computeStats();
    notifyListeners();
    return stats;
  }

  void stopSimulation() {
    _isSimulating = false;
    notifyListeners();
  }

  ThrottleStats _computeStats() {
    if (_log.isEmpty) {
      return const ThrottleStats(totalEvents: 0, totalScansSaved: 0, totalEnergySavedMaS: 0, avgThrottleFactor: 1.0, simDuration: Duration.zero);
    }
    final totalSaved = _log.fold(0.0, (s, e) => s + e.estimatedMaSaved);
    final avgFactor = _log.fold(0.0, (s, e) => s + e.throttleFactor) / _log.length;
    final baseScansIn10Min = (600 / _baseSecs).round();
    final actualScans = _log.fold(0, (s, e) => s + (600 ~/ e.intervalSecs));
    final simDuration = _simStart != null ? DateTime.now().difference(_simStart!) : Duration.zero;

    return ThrottleStats(
      totalEvents: _log.length,
      totalScansSaved: (baseScansIn10Min - actualScans).clamp(0, baseScansIn10Min),
      totalEnergySavedMaS: totalSaved,
      avgThrottleFactor: avgFactor,
      simDuration: simDuration,
    );
  }

  // Simulation scenario: 20 steps representing 10 minutes
  List<({int battery, bool stationary, bool nearNode})> _buildSimulationScenario() => [
    (battery: 100, stationary: false, nearNode: false), // 0:00 — active, full battery
    (battery: 97,  stationary: false, nearNode: true),  // 0:30 — near hub
    (battery: 94,  stationary: true,  nearNode: true),  // 1:00 — stopped at hub
    (battery: 90,  stationary: true,  nearNode: false), // 1:30 — stationary, no peers
    (battery: 85,  stationary: false, nearNode: false), // 2:00 — moving again
    (battery: 80,  stationary: false, nearNode: false), // 2:30
    (battery: 75,  stationary: false, nearNode: true),  // 3:00 — near camp
    (battery: 68,  stationary: true,  nearNode: true),  // 3:30 — stopped at camp
    (battery: 60,  stationary: true,  nearNode: false), // 4:00 — stationary
    (battery: 52,  stationary: false, nearNode: false), // 4:30 — moving
    (battery: 44,  stationary: false, nearNode: false), // 5:00
    (battery: 38,  stationary: false, nearNode: false), // 5:30
    (battery: 32,  stationary: true,  nearNode: false), // 6:00 — stationary
    (battery: 28,  stationary: false, nearNode: false), // 6:30 — LOW BATTERY (<30%)
    (battery: 24,  stationary: true,  nearNode: false), // 7:00 — critical + stationary
    (battery: 20,  stationary: true,  nearNode: true),  // 7:30 — critical + node nearby
    (battery: 16,  stationary: false, nearNode: false), // 8:00 — critical, moving
    (battery: 12,  stationary: true,  nearNode: false), // 8:30 — very low
    (battery: 8,   stationary: true,  nearNode: true),  // 9:00 — nearly empty
    (battery: 5,   stationary: true,  nearNode: true),  // 9:30 — emergency throttle
  ];

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
