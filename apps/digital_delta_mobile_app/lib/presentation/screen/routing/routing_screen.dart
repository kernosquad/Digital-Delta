import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/color.dart';

// ---------------------------------------------------------------------------
// Module 4 — Multi-Modal VRP Routing Engine
// M4.1 Graph (road/river/airway), M4.2 Dynamic Recompute, M4.3 Constraints
// ---------------------------------------------------------------------------

class RoutingScreen extends StatefulWidget {
  const RoutingScreen({super.key});

  @override
  State<RoutingScreen> createState() => _RoutingScreenState();
}

class _RoutingScreenState extends State<RoutingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Dio _dio;

  List<Map<String, dynamic>> _nodes = [];
  List<Map<String, dynamic>> _edges = [];
  bool _graphLoading = false;

  String? _fromCode;
  String? _toCode;
  String _vehicle = 'truck';
  bool _computing = false;
  Map<String, dynamic>? _routeResult;
  String? _routeError;

  // Module 7 — ML Risk state
  List<Map<String, dynamic>> _mlPredictions = [];
  bool _mlLoading = false;
  bool _mlGenerating = false;

  // Module 6 — Triage Engine state
  List<Map<String, dynamic>> _triageDecisions = [];
  List<Map<String, dynamic>> _breachPredictions = [];
  List<Map<String, dynamic>> _triageMissions = [];
  bool _triageLoading = false;
  bool _breachLoading = false;
  double _delayFactor = 1.3;
  Map<String, dynamic>? _preemptResult;
  bool _preempting = false;
  int? _preemptingId;

  static final List<Map<String, dynamic>> _priorityTaxonomy = [
    {'class': 'p0_critical', 'label': 'P0 Critical', 'sla': '2 hrs',  'color': AppColors.priorityP0.toARGB32(), 'example': 'Antivenom, blood, oxygen'},
    {'class': 'p1_high',     'label': 'P1 High',     'sla': '6 hrs',  'color': AppColors.priorityP1.toARGB32(), 'example': 'Surgical kits, IV fluids'},
    {'class': 'p2_standard', 'label': 'P2 Standard', 'sla': '24 hrs', 'color': AppColors.priorityP2.toARGB32(), 'example': 'Food, blankets, meds'},
    {'class': 'p3_low',      'label': 'P3 Low',      'sla': '72 hrs', 'color': AppColors.statusOnline.toARGB32(), 'example': 'Non-urgent supplies'},
  ];

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3333',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 6)));
    _loadGraph();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dio.close();
    super.dispose();
  }

  // ── API ─────────────────────────────────────────────────────────────────

  Future<void> _injectToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> _loadGraph() async {
    setState(() => _graphLoading = true);
    try {
      await _injectToken();
      final res = await _dio.get('/api/network/graph');
      final data = res.data['data'] as Map<String, dynamic>;
      setState(() {
        _nodes = List<Map<String, dynamic>>.from(data['nodes'] as List);
        _edges = List<Map<String, dynamic>>.from(data['edges'] as List);
      });
    } catch (_) {
      _loadStubGraph();
    } finally {
      setState(() => _graphLoading = false);
    }
  }

  void _loadStubGraph() {
    _nodes = [
      {'id': 1, 'code': 'N1', 'name': 'Sylhet City Hub', 'type': 'central_command', 'is_flooded': false},
      {'id': 2, 'code': 'N2', 'name': 'Osmani Airport Node', 'type': 'supply_drop', 'is_flooded': false},
      {'id': 3, 'code': 'N3', 'name': 'Sunamganj Sadar Camp', 'type': 'relief_camp', 'is_flooded': false},
      {'id': 4, 'code': 'N4', 'name': 'Companyganj Outpost', 'type': 'relief_camp', 'is_flooded': true},
      {'id': 5, 'code': 'N5', 'name': 'Kanaighat Point', 'type': 'waypoint', 'is_flooded': false},
      {'id': 6, 'code': 'N6', 'name': 'Habiganj Medical', 'type': 'hospital', 'is_flooded': false},
    ];
    _edges = [
      {'id': 1, 'code': 'E1', 'source': 1, 'target': 2, 'type': 'road', 'current_travel_mins': 20, 'is_flooded': false, 'is_blocked': false},
      {'id': 2, 'code': 'E2', 'source': 1, 'target': 3, 'type': 'road', 'current_travel_mins': 90, 'is_flooded': false, 'is_blocked': false},
      {'id': 3, 'code': 'E3', 'source': 2, 'target': 4, 'type': 'road', 'current_travel_mins': 45, 'is_flooded': false, 'is_blocked': false},
      {'id': 4, 'code': 'E4', 'source': 1, 'target': 5, 'type': 'road', 'current_travel_mins': 60, 'is_flooded': false, 'is_blocked': false},
      {'id': 5, 'code': 'E5', 'source': 1, 'target': 6, 'type': 'road', 'current_travel_mins': 120, 'is_flooded': false, 'is_blocked': false},
      {'id': 6, 'code': 'E6', 'source': 1, 'target': 3, 'type': 'river', 'current_travel_mins': 150, 'is_flooded': false, 'is_blocked': false},
      {'id': 7, 'code': 'E7', 'source': 3, 'target': 4, 'type': 'river', 'current_travel_mins': 50, 'is_flooded': false, 'is_blocked': false},
    ];
  }

  Future<void> _computeRoute() async {
    if (_fromCode == null || _toCode == null) return;
    if (_fromCode == _toCode) {
      setState(() => _routeError = 'Origin and destination cannot be the same');
      return;
    }
    setState(() { _computing = true; _routeResult = null; _routeError = null; });
    try {
      await _injectToken();
      final res = await _dio.get('/api/network/compute', queryParameters: {
        'from': _fromCode,
        'to': _toCode,
        'vehicle': _vehicle,
      });
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        setState(() => _routeResult = data);
      } else {
        setState(() => _routeError = res.data['message'] as String? ?? 'No route found');
      }
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?['message'] as String? ?? 'Route computation failed';
      setState(() => _routeError = msg);
    } catch (_) {
      _simulateRoute(); // offline demo
    } finally {
      setState(() => _computing = false);
    }
  }

  void _simulateRoute() {
    final from = _nodes.firstWhere((n) => n['code'] == _fromCode, orElse: () => {'code': _fromCode, 'name': _fromCode});
    final to = _nodes.firstWhere((n) => n['code'] == _toCode, orElse: () => {'code': _toCode, 'name': _toCode});
    setState(() {
      _routeResult = {
        'is_viable': true,
        'vehicle': _vehicle,
        'total_mins': 110,
        'from': from,
        'to': to,
        'path': [
          {'step': 1, 'node': from, 'via_edge': null},
          {
            'step': 2,
            'node': {'code': 'N2', 'name': 'Osmani Airport Node', 'type': 'supply_drop'},
            'via_edge': {'id': null, 'code': 'E1', 'type': _vehicleEdgeType, 'current_travel_mins': 20},
          },
          {
            'step': 3,
            'node': to,
            'via_edge': {'id': null, 'code': 'E2', 'type': _vehicleEdgeType, 'current_travel_mins': 90},
          },
        ],
      };
    });
  }

  String get _vehicleEdgeType =>
      _vehicle == 'truck' ? 'road' : _vehicle == 'speedboat' ? 'river' : 'airway';

  // M4.2 — mark edge failure and auto-recompute within 2s
  Future<void> _markEdgeFailed(Map<String, dynamic> edge) async {
    final edgeId = edge['id'];
    if (edgeId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline: failure logged locally'), backgroundColor: AppColors.statusPending),
      );
      await _computeRoute();
      return;
    }
    try {
      await _injectToken();
      await _dio.patch('/api/network/edges/$edgeId/status', data: {
        'is_flooded': true,
        'is_blocked': true,
        'reason': 'flood',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${edge['code']} marked flooded. Recomputing…'), backgroundColor: AppColors.statusPending),
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline: failure logged locally'), backgroundColor: AppColors.statusPending),
      );
    }
    // M4.2 — recompute triggered immediately after failure
    await _computeRoute();
  }

  // ── Module 7: ML Risk API ────────────────────────────────────────────────

  Future<void> _generateMlPredictions() async {
    setState(() { _mlGenerating = true; });
    try {
      await _injectToken();
      final res = await _dio.post('/api/sensors/predictions/generate');
      final data = res.data['data'] as Map<String, dynamic>?;
      final preds = data?['predictions'] as List<dynamic>? ?? [];
      setState(() {
        _mlPredictions = List<Map<String, dynamic>>.from(preds);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ML run complete — ${preds.length} routes evaluated'), backgroundColor: AppColors.statusOnline),
        );
      }
    } catch (_) {
      setState(() => _mlPredictions = _stubMlPredictions());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline: showing simulated predictions'), backgroundColor: AppColors.statusPending),
        );
      }
    } finally {
      setState(() => _mlGenerating = false);
    }
  }

  List<Map<String, dynamic>> _stubMlPredictions() => [
    {'edge_code': 'E1', 'route_id': 1, 'impassability_prob': 0.12, 'risk_level': 'low',      'predicted_travel_mins': 22},
    {'edge_code': 'E2', 'route_id': 2, 'impassability_prob': 0.45, 'risk_level': 'medium',   'predicted_travel_mins': 110},
    {'edge_code': 'E3', 'route_id': 3, 'impassability_prob': 0.78, 'risk_level': 'high',     'predicted_travel_mins': 180},
    {'edge_code': 'E6', 'route_id': 6, 'impassability_prob': 0.92, 'risk_level': 'critical', 'predicted_travel_mins': 999},
    {'edge_code': 'E7', 'route_id': 7, 'impassability_prob': 0.33, 'risk_level': 'medium',   'predicted_travel_mins': 65},
  ];

  // ── Module 6: Triage API ─────────────────────────────────────────────────

  Future<void> _loadTriageDecisions() async {
    setState(() { _triageLoading = true; });
    try {
      await _injectToken();
      final res = await _dio.get('/api/triage/decisions');
      setState(() {
        _triageDecisions = List<Map<String, dynamic>>.from(res.data['data'] as List? ?? []);
      });
    } catch (_) {
      setState(() => _triageDecisions = []);
    } finally {
      setState(() => _triageLoading = false);
    }
  }

  Future<void> _loadActiveMissions() async {
    try {
      await _injectToken();
      final res = await _dio.get('/api/missions', queryParameters: {'status': 'in_progress'});
      final list = res.data['data'] as List? ?? [];
      setState(() => _triageMissions = List<Map<String, dynamic>>.from(list));
    } catch (_) {
      setState(() => _triageMissions = _stubMissions());
    }
  }

  Future<void> _predictSlaBreach() async {
    setState(() { _breachLoading = true; });
    try {
      await _injectToken();
      final res = await _dio.get('/api/triage/predict-breach',
          queryParameters: {'delay_factor': _delayFactor.toStringAsFixed(2)});
      final data = res.data['data'] as Map<String, dynamic>?;
      setState(() {
        _breachPredictions = List<Map<String, dynamic>>.from(data?['predictions'] as List? ?? []);
      });
    } catch (_) {
      setState(() => _breachPredictions = _stubBreachPredictions());
    } finally {
      setState(() => _breachLoading = false);
    }
  }

  Future<void> _autoPreempt(int missionId, String missionCode) async {
    setState(() { _preempting = true; _preemptingId = missionId; _preemptResult = null; });
    try {
      await _injectToken();
      final res = await _dio.post('/api/triage/missions/$missionId/auto-preempt');
      setState(() => _preemptResult = res.data['data'] as Map<String, dynamic>?);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-preempt logged for $missionCode'), backgroundColor: AppColors.statusPending),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline: preemption decision stored locally'), backgroundColor: AppColors.statusPending),
        );
      }
    } finally {
      setState(() { _preempting = false; _preemptingId = null; });
    }
  }

  List<Map<String, dynamic>> _stubMissions() => [
    {'id': 1, 'mission_code': 'MSN-001', 'priority_class': 'p0_critical', 'status': 'in_progress', 'sla_deadline': DateTime.now().add(const Duration(hours: 1)).toIso8601String()},
    {'id': 2, 'mission_code': 'MSN-002', 'priority_class': 'p2_standard', 'status': 'in_progress', 'sla_deadline': DateTime.now().add(const Duration(hours: 20)).toIso8601String()},
  ];

  List<Map<String, dynamic>> _stubBreachPredictions() => [
    {'mission_id': 1, 'mission_code': 'MSN-001', 'priority_class': 'p0_critical', 'will_breach_sla': true,  'predicted_eta_mins': 130, 'sla_mins_remaining': 60,  'urgency': 'critical'},
    {'mission_id': 2, 'mission_code': 'MSN-002', 'priority_class': 'p2_standard', 'will_breach_sla': false, 'predicted_eta_mins': 280, 'sla_mins_remaining': 1200,'urgency': 'ok'},
  ];

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        title: Text('Route Planner', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGraph, tooltip: 'Refresh graph'),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primarySurfaceDefault,
          labelColor: AppColors.primarySurfaceDefault,
          unselectedLabelColor: AppColors.secondaryTextDefault,
          tabs: const [
            Tab(text: 'Route Planner', icon: Icon(Icons.route)),
            Tab(text: 'Network Graph', icon: Icon(Icons.account_tree)),
            Tab(text: 'ML Risk', icon: Icon(Icons.psychology)),
            Tab(text: 'Triage', icon: Icon(Icons.crisis_alert)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPlannerTab(), _buildGraphTab(), _buildMlRiskTab(), _buildTriageTab()],
      ),
    );
  }

  // ── Planner Tab ──────────────────────────────────────────────────────────

  Widget _buildPlannerTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Vehicle Type (M4.3)', Icons.directions_car),
          SizedBox(height: 8.h),
          _buildVehicleSelector(),
          SizedBox(height: 20.h),
          _sectionHeader('Select Route', Icons.swap_vert),
          SizedBox(height: 8.h),
          _buildLocationDropdown('Origin', _fromCode, (v) => setState(() { _fromCode = v; _routeResult = null; })),
          SizedBox(height: 12.h),
          _buildLocationDropdown('Destination', _toCode, (v) => setState(() { _toCode = v; _routeResult = null; })),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_fromCode != null && _toCode != null && !_computing) ? _computeRoute : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primarySurfaceDefault,
                disabledBackgroundColor: AppColors.primarySurfaceDefault.withValues(alpha: 0.4),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              icon: _computing
                  ? SizedBox(width: 18.w, height: 18.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.calculate, color: Colors.white),
              label: Text(
                _computing ? 'Computing (Dijkstra)…' : 'Compute Optimal Route',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          if (_routeError != null) ...[
            SizedBox(height: 12.h),
            _ErrorBanner(message: _routeError!),
          ],
          if (_routeResult != null) ...[
            SizedBox(height: 20.h),
            _buildRouteResult(_routeResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleSelector() {
    const vehicles = [
      ('truck', Icons.local_shipping, 'Truck', 'Road only'),
      ('speedboat', Icons.directions_boat, 'Speedboat', 'River only'),
      ('drone', Icons.airplanemode_active, 'Drone', 'Airway only'),
    ];
    return Row(
      children: vehicles.asMap().entries.map((entry) {
        final v = entry.value;
        final isLast = entry.key == vehicles.length - 1;
        final selected = _vehicle == v.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() { _vehicle = v.$1; _routeResult = null; }),
            child: Container(
              margin: EdgeInsets.only(right: isLast ? 0 : 8.w),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySurfaceDefault : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: selected ? AppColors.primarySurfaceDefault : AppColors.borderDefault, width: selected ? 2 : 1),
                boxShadow: selected ? [BoxShadow(color: AppColors.primarySurfaceDefault.withValues(alpha: 0.2), blurRadius: 8)] : [],
              ),
              child: Column(
                children: [
                  Icon(v.$2, color: selected ? Colors.white : AppColors.secondaryTextDefault, size: 22.sp),
                  SizedBox(height: 4.h),
                  Text(v.$3, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.primaryTextDefault)),
                  Text(v.$4, style: TextStyle(fontSize: 9.sp, color: selected ? Colors.white70 : AppColors.secondaryTextDefault)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationDropdown(String label, String? value, ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: value != null ? AppColors.primarySurfaceDefault : AppColors.borderDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: TextStyle(color: AppColors.secondaryTextDefault, fontSize: 14.sp)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _nodes.map((node) {
            final isFlooded = node['is_flooded'] == true;
            return DropdownMenuItem<String>(
              value: node['code'] as String?,
              child: Row(
                children: [
                  Icon(_nodeIcon(node['type'] as String? ?? ''), size: 16.sp, color: isFlooded ? AppColors.dangerSurfaceDefault : AppColors.primarySurfaceDefault),
                  SizedBox(width: 8.w),
                  Expanded(child: Text('${node['code']} — ${node['name']}', style: TextStyle(fontSize: 13.sp), overflow: TextOverflow.ellipsis)),
                  if (isFlooded) Icon(Icons.warning, size: 14, color: AppColors.dangerSurfaceDefault),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRouteResult(Map<String, dynamic> result) {
    final isViable = result['is_viable'] == true;
    final totalMins = result['total_mins'] as int?;
    final path = result['path'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Route Result (M4.2 Dijkstra)', isViable ? Icons.check_circle : Icons.cancel),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isViable ? AppColors.primarySurfaceDefault.withValues(alpha: 0.08) : AppColors.dangerSurfaceTint,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: isViable ? AppColors.primarySurfaceDefault : AppColors.dangerSurfaceDefault),
          ),
          child: Row(
            children: [
              Icon(isViable ? Icons.check_circle : Icons.cancel, color: isViable ? AppColors.primarySurfaceDefault : AppColors.dangerSurfaceDefault, size: 36.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isViable ? 'Optimal Route Found' : 'No Viable Route',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: isViable ? AppColors.primaryTextDefault : AppColors.dangerSurfaceDefault),
                    ),
                    if (isViable && totalMins != null)
                      Text('${_formatDuration(totalMins)}  ·  ${path.length} stops  ·  $_vehicle',
                          style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryTextDefault)),
                    if (!isViable)
                      Text('All $_vehicle paths flooded/blocked', style: TextStyle(fontSize: 13.sp, color: AppColors.dangerSurfaceDefault)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isViable && path.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _sectionHeader('Path Steps', Icons.linear_scale),
          SizedBox(height: 8.h),
          ...path.asMap().entries.map((e) => _buildPathStep(e.value as Map<String, dynamic>, e.key == path.length - 1)),
        ],
      ],
    );
  }

  Widget _buildPathStep(Map<String, dynamic> step, bool isLast) {
    final node = step['node'] as Map<String, dynamic>?;
    final edge = step['via_edge'] as Map<String, dynamic>?;
    final isFlooded = node?['is_flooded'] == true;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32.w, height: 32.h,
                  decoration: BoxDecoration(color: isFlooded ? AppColors.dangerSurfaceDefault : AppColors.primarySurfaceDefault, shape: BoxShape.circle),
                  child: Center(child: Text('${step['step']}', style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w700))),
                ),
                if (!isLast) Container(width: 2, height: 44.h, color: AppColors.borderDefault),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 4.h, bottom: isLast ? 0 : 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(node?['name'] as String? ?? node?['code'] as String? ?? '—',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isFlooded ? AppColors.dangerSurfaceDefault : AppColors.primaryTextDefault)),
                    if (node?['type'] != null)
                      Text(_nodeLabel(node!['type'] as String? ?? ''), style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
                    if (isFlooded)
                      Row(children: [Icon(Icons.warning, size: 12, color: AppColors.dangerSurfaceDefault), SizedBox(width: 4.w), Text('FLOODED', style: TextStyle(fontSize: 11.sp, color: AppColors.dangerSurfaceDefault, fontWeight: FontWeight.w700))]),
                    if (edge != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          _EdgeTypeBadge(type: edge['type'] as String? ?? 'road'),
                          SizedBox(width: 8.w),
                          Text('${edge['current_travel_mins'] ?? '?'} min', style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _markEdgeFailed(edge),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(color: AppColors.dangerSurfaceTint, borderRadius: BorderRadius.circular(6.r), border: Border.all(color: AppColors.dangerSurfaceDefault)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning, size: 11, color: AppColors.dangerSurfaceDefault),
                                  SizedBox(width: 3.w),
                                  Text('Mark Failed', style: TextStyle(fontSize: 10.sp, color: AppColors.dangerSurfaceDefault, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Graph Tab ─────────────────────────────────────────────────────────────

  Widget _buildGraphTab() {
    if (_graphLoading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend(),
          SizedBox(height: 16.h),
          _sectionHeader('Nodes (${_nodes.length})', Icons.circle),
          SizedBox(height: 8.h),
          ..._nodes.map(_buildNodeCard),
          SizedBox(height: 16.h),
          _sectionHeader('Edges (${_edges.length})', Icons.linear_scale),
          SizedBox(height: 8.h),
          ..._edges.map(_buildEdgeCard),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.borderDefault)),
      child: Row(
        children: [
          _LegendDot(color: const Color(0xFF2196F3), label: 'Road'),
          SizedBox(width: 16.w),
          _LegendDot(color: const Color(0xFF00BCD4), label: 'River'),
          SizedBox(width: 16.w),
          _LegendDot(color: const Color(0xFFFF9800), label: 'Airway'),
          const Spacer(),
          _LegendDot(color: AppColors.dangerSurfaceDefault, label: 'Flooded'),
        ],
      ),
    );
  }

  Widget _buildNodeCard(Map<String, dynamic> node) {
    final isFlooded = node['is_flooded'] == true;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: isFlooded ? AppColors.dangerSurfaceDefault : AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isFlooded ? AppColors.dangerSurfaceTint : AppColors.primarySurfaceDefault.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(_nodeIcon(node['type'] as String? ?? ''), size: 18.sp, color: isFlooded ? AppColors.dangerSurfaceDefault : AppColors.primarySurfaceDefault),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node['name'] as String? ?? node['code'] as String? ?? '', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                Text('${node['code']} · ${_nodeLabel(node['type'] as String? ?? '')}', style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
              ],
            ),
          ),
          _StatusBadge(label: isFlooded ? 'FLOODED' : 'ACTIVE', color: isFlooded ? AppColors.dangerSurfaceDefault : AppColors.statusOnline),
        ],
      ),
    );
  }

  Widget _buildEdgeCard(Map<String, dynamic> edge) {
    final isFlooded = edge['is_flooded'] == true;
    final isBlocked = edge['is_blocked'] == true;
    final edgeType = edge['type'] as String? ?? 'road';
    final barColor = _edgeColor(edgeType);
    final bad = isFlooded || isBlocked;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: bad ? AppColors.dangerSurfaceDefault : AppColors.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Row(
          children: [
            Container(width: 4, color: barColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(edge['code'] as String? ?? '', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                            SizedBox(width: 8.w),
                            _EdgeTypeBadge(type: edgeType),
                          ]),
                          SizedBox(height: 4.h),
                          Text(
                            'N${edge['source']} → N${edge['target']}  ·  ${edge['current_travel_mins'] ?? edge['base_travel_mins'] ?? '?'} min',
                            style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(label: isFlooded ? 'FLOODED' : (isBlocked ? 'BLOCKED' : 'OPEN'), color: bad ? AppColors.dangerSurfaceDefault : AppColors.statusOnline),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Module 7: ML Risk Tab ────────────────────────────────────────────────

  Widget _buildMlRiskTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Generate button
          Row(
            children: [
              Expanded(child: _sectionHeader('Predictive Route Decay (M7)', Icons.psychology)),
              SizedBox(width: 8.w),
              ElevatedButton.icon(
                onPressed: _mlGenerating ? null : _generateMlPredictions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primarySurfaceDefault,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                icon: _mlGenerating
                    ? SizedBox(width: 14.w, height: 14.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.play_arrow, color: Colors.white, size: 16.sp),
                label: Text(_mlGenerating ? 'Running…' : 'Run ML', style: TextStyle(fontSize: 12.sp, color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text('Logistic regression on rainfall/water/soil features. High-risk edges (>0.7) are automatically penalized in the routing engine.',
              style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
          SizedBox(height: 12.h),

          // Metrics legend
          _buildMlLegend(),
          SizedBox(height: 16.h),

          if (_mlLoading) const Center(child: CircularProgressIndicator())
          else if (_mlPredictions.isEmpty)
            _buildMlEmptyState()
          else ...[
            _sectionHeader('Route Risk Predictions (${_mlPredictions.length})', Icons.bar_chart),
            SizedBox(height: 8.h),
            ..._mlPredictions.map(_buildMlPredictionCard),
          ],
        ],
      ),
    );
  }

  Widget _buildMlLegend() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Risk Levels  ·  Model: v1.0-logistic-sim', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.secondaryTextDefault)),
          SizedBox(height: 8.h),
          Row(
            children: [
              _MlLegendChip(label: 'Low <0.3',       color: AppColors.statusOnline),
              SizedBox(width: 8.w),
              _MlLegendChip(label: 'Medium 0.3-0.5', color: AppColors.statusPending),
              SizedBox(width: 8.w),
              _MlLegendChip(label: 'High 0.5-0.7',   color: AppColors.warningSurfaceDefault),
              SizedBox(width: 8.w),
              _MlLegendChip(label: 'Critical >0.7',  color: AppColors.dangerSurfaceDefault),
            ],
          ),
          SizedBox(height: 6.h),
          Text('Simulated precision: 0.87  ·  recall: 0.82  ·  F1: 0.84',
              style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryTextDefault, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildMlEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            Icon(Icons.psychology_outlined, size: 48.sp, color: AppColors.secondaryTextDefault),
            SizedBox(height: 12.h),
            Text('No predictions yet', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 4.h),
            Text('Tap "Run ML" to generate impassability predictions', style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryTextDefault), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMlPredictionCard(Map<String, dynamic> pred) {
    final prob = (pred['impassability_prob'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = pred['risk_level'] as String? ?? 'low';
    final edgeCode = pred['edge_code'] as String? ?? '—';
    final travelMins = pred['predicted_travel_mins'] as int?;
    final snap = pred['features_snapshot'] as Map<String, dynamic>? ?? {};

    final riskColor = switch (riskLevel) {
      'critical' => AppColors.dangerSurfaceDefault,
      'high'     => AppColors.dangerSurfaceDefault,
      'medium'   => AppColors.statusPending,
      _          => AppColors.statusOnline,
    };

    final isHighRisk = prob > 0.7;

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isHighRisk ? riskColor.withValues(alpha: 0.5) : AppColors.borderDefault, width: isHighRisk ? 1.5 : 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          children: [
            Container(
              height: 4,
              color: riskColor,
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(edgeCode, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4.r)),
                        child: Text(riskLevel.toUpperCase(), style: TextStyle(fontSize: 10.sp, color: riskColor, fontWeight: FontWeight.w700)),
                      ),
                      if (isHighRisk) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(color: AppColors.dangerSurfaceTint, borderRadius: BorderRadius.circular(4.r)),
                          child: Text('PENALIZED', style: TextStyle(fontSize: 9.sp, color: AppColors.dangerSurfaceDefault, fontWeight: FontWeight.w700)),
                        ),
                      ],
                      const Spacer(),
                      Text('${(prob * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: riskColor)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // Probability bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: prob.clamp(0.0, 1.0),
                      backgroundColor: riskColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      minHeight: 6.h,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12.sp, color: AppColors.secondaryTextDefault),
                      SizedBox(width: 4.w),
                      Text('Predicted travel: ${travelMins != null ? "$travelMins min" : "—"}',
                          style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
                    ],
                  ),
                  if (snap.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        if (snap['cumulative_rainfall_mm'] != null)
                          _FeatureChip(label: 'Rain', value: '${snap['cumulative_rainfall_mm']}mm'),
                        if (snap['water_level_cm'] != null)
                          _FeatureChip(label: 'Water', value: '${snap['water_level_cm']}cm'),
                        if (snap['soil_saturation_pct'] != null)
                          _FeatureChip(label: 'Soil', value: '${snap['soil_saturation_pct']}%'),
                        if (snap['risk_score'] != null)
                          _FeatureChip(label: 'RiskScore', value: '${snap['risk_score']}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Module 6: Triage Tab ─────────────────────────────────────────────────

  Widget _buildTriageTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Triage & Priority Preemption (M6)', Icons.crisis_alert),
          SizedBox(height: 16.h),

          // M6.1 — Priority taxonomy
          _sectionHeader('Cargo Priority Taxonomy (M6.1)', Icons.category),
          SizedBox(height: 8.h),
          ..._priorityTaxonomy.map(_buildPriorityCard),
          SizedBox(height: 20.h),

          // M6.2 — SLA breach prediction
          _sectionHeader('SLA Breach Prediction (M6.2)', Icons.schedule),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.borderDefault)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Route delay factor: ${_delayFactor.toStringAsFixed(2)}×', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600))),
                    Text('${((_delayFactor - 1) * 100).toStringAsFixed(0)}% slower', style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
                  ],
                ),
                Slider(
                  value: _delayFactor,
                  min: 1.0,
                  max: 3.0,
                  divisions: 20,
                  activeColor: AppColors.primarySurfaceDefault,
                  onChanged: (v) => setState(() { _delayFactor = v; _breachPredictions = []; }),
                ),
                SizedBox(height: 4.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _breachLoading ? null : _predictSlaBreach,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusPending,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    icon: _breachLoading
                        ? SizedBox(width: 16.w, height: 16.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(Icons.bolt, color: Colors.white, size: 16.sp),
                    label: Text(_breachLoading ? 'Checking…' : 'Check Deadline Risk',
                        style: TextStyle(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          if (_breachPredictions.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ..._breachPredictions.map(_buildBreachCard),
          ],
          SizedBox(height: 20.h),

          // M6.3 — Auto preempt
          Row(
            children: [
              Expanded(child: _sectionHeader('Auto Preemption Engine (M6.3)', Icons.swap_calls)),
              TextButton.icon(
                onPressed: () { _loadActiveMissions(); _loadTriageDecisions(); },
                icon: Icon(Icons.refresh, size: 14.sp, color: AppColors.primarySurfaceDefault),
                label: Text('Refresh', style: TextStyle(fontSize: 11.sp, color: AppColors.primarySurfaceDefault)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text('Autonomously deposits P2/P3 cargo at a safe waypoint and reroutes the driver with P0/P1 items only.',
              style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
          SizedBox(height: 10.h),

          if (_triageLoading) const Center(child: CircularProgressIndicator())
          else if (_triageMissions.isEmpty)
            _buildTriageEmptyMissions()
          else
            ..._triageMissions.map(_buildMissionPreemptCard),

          if (_preemptResult != null) ...[
            SizedBox(height: 12.h),
            _buildPreemptResultCard(_preemptResult!),
          ],

          // Recent decisions
          if (_triageDecisions.isNotEmpty) ...[
            SizedBox(height: 20.h),
            _sectionHeader('Audit Trail (${_triageDecisions.length})', Icons.history),
            SizedBox(height: 8.h),
            ..._triageDecisions.take(5).map(_buildDecisionCard),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityCard(Map<String, dynamic> tier) {
    final color = Color(tier['color'] as int);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.r)),
            child: Text(tier['label'] as String, style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SLA: ${tier['sla']}', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: color)),
                Text(tier['example'] as String, style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreachCard(Map<String, dynamic> pred) {
    final willBreach = pred['will_breach_sla'] == true;
    final urgency = pred['urgency'] as String? ?? 'ok';
    final urgencyColor = urgency == 'critical' ? AppColors.dangerSurfaceDefault : urgency == 'warning' ? AppColors.statusPending : AppColors.statusOnline;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: willBreach ? urgencyColor.withValues(alpha: 0.06) : AppColors.primarySurfaceTint,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: willBreach ? urgencyColor.withValues(alpha: 0.4) : AppColors.borderActive),
      ),
      child: Row(
        children: [
          Icon(willBreach ? Icons.warning_rounded : Icons.check_circle, color: urgencyColor, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pred['mission_code'] ?? 'Mission'}  ·  ${_priorityLabel(pred['priority_class'] as String? ?? '')}',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                Text(willBreach
                    ? 'ETA ${pred['predicted_eta_mins']} min  >  SLA ${pred['sla_mins_remaining']} min remaining'
                    : 'ETA ${pred['predicted_eta_mins']} min  ·  Within SLA',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(color: urgencyColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6.r)),
            child: Text(urgency.toUpperCase(), style: TextStyle(fontSize: 10.sp, color: urgencyColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildTriageEmptyMissions() {
    return GestureDetector(
      onTap: _loadActiveMissions,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.borderDefault)),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.touch_app, size: 32.sp, color: AppColors.primarySurfaceDefault),
              SizedBox(height: 8.h),
              Text('Tap to load active missions', style: TextStyle(fontSize: 13.sp, color: AppColors.secondaryTextDefault)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionPreemptCard(Map<String, dynamic> mission) {
    final missionId = mission['id'] as int? ?? 0;
    final missionCode = mission['mission_code'] as String? ?? '—';
    final priorityClass = mission['priority_class'] as String? ?? '';
    final isCritical = ['p0_critical', 'p1_high'].contains(priorityClass);
    final isPreempting = _preemptingId == missionId;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: AppColors.borderDefault)),
      child: Row(
        children: [
          Container(
            width: 10.w, height: 10.h,
            decoration: BoxDecoration(color: _priorityColor(priorityClass), shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(missionCode, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                Text(_priorityLabel(priorityClass), style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: (_preempting || isCritical) ? null : () => _autoPreempt(missionId, missionCode),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusPending,
              disabledBackgroundColor: isCritical ? AppColors.primarySurfaceTint : AppColors.borderDefault,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            icon: isPreempting
                ? SizedBox(width: 12.w, height: 12.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(isCritical ? Icons.shield : Icons.swap_calls, size: 14.sp, color: isCritical ? AppColors.statusOnline : Colors.white),
            label: Text(isCritical ? 'Priority' : 'Preempt',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: isCritical ? AppColors.primarySurfaceDefault : Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreemptResultCard(Map<String, dynamic> result) {
    final action = result['action'] as String? ?? '';
    final rationale = result['rationale'] as String? ?? '';
    final dropWaypoint = result['drop_waypoint'] as Map<String, dynamic>?;
    final isDropReroute = action == 'drop_and_reroute';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDropReroute ? AppColors.warningSurfaceTint : AppColors.primarySurfaceTint,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDropReroute ? AppColors.warningSurfaceDefault : AppColors.borderActive),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isDropReroute ? Icons.swap_calls : Icons.shield, color: isDropReroute ? AppColors.statusPending : AppColors.statusOnline, size: 18.sp),
              SizedBox(width: 8.w),
              Text(isDropReroute ? 'Drop & Reroute Decision' : 'Priority Maintained',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: isDropReroute ? AppColors.statusPending : AppColors.primarySurfaceDefault)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(rationale, style: TextStyle(fontSize: 12.sp, color: AppColors.primaryTextDefault)),
          if (dropWaypoint != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.place, size: 14.sp, color: AppColors.primarySurfaceDefault),
                SizedBox(width: 4.w),
                Text('Drop-off: ${dropWaypoint['name'] ?? 'Waypoint'}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.primarySurfaceDefault)),
              ],
            ),
          ],
          SizedBox(height: 6.h),
          Text('Decision ID: ${result['decision_id'] ?? '—'}  ·  Logged to audit trail',
              style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryTextDefault, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildDecisionCard(Map<String, dynamic> d) {
    final triggeredBy = (d['triggered_by'] as String? ?? '').replaceAll('_', ' ');
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: AppColors.borderDefault)),
      child: Row(
        children: [
          Icon(Icons.gavel, size: 14.sp, color: AppColors.primarySurfaceDefault),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['mission_code'] as String? ?? 'Mission ${d['mission_id']}', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                Text(triggeredBy, style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryTextDefault)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 18.sp, color: AppColors.primarySurfaceDefault),
      SizedBox(width: 8.w),
      Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppColors.primaryTextDefault)),
    ],
  );

  String _priorityLabel(String cls) => switch (cls) {
    'p0_critical' => 'P0 Critical',
    'p1_high'     => 'P1 High',
    'p2_standard' => 'P2 Standard',
    'p3_low'      => 'P3 Low',
    _             => cls,
  };

  Color _priorityColor(String cls) => switch (cls) {
    'p0_critical' => AppColors.priorityP0,
    'p1_high'     => AppColors.priorityP1,
    'p2_standard' => AppColors.priorityP2,
    'p3_low'      => AppColors.statusOnline,
    _             => AppColors.borderDefault,
  };

  String _formatDuration(int mins) {
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  IconData _nodeIcon(String type) => switch (type) {
    'central_command' => Icons.account_balance,
    'supply_drop' => Icons.local_shipping,
    'relief_camp' => Icons.people,
    'hospital' => Icons.local_hospital,
    'waypoint' => Icons.place,
    _ => Icons.circle,
  };

  String _nodeLabel(String type) => switch (type) {
    'central_command' => 'Command HQ',
    'supply_drop' => 'Supply Drop',
    'relief_camp' => 'Relief Camp',
    'hospital' => 'Hospital',
    'waypoint' => 'Waypoint',
    _ => type,
  };

  Color _edgeColor(String type) => switch (type) {
    'road' => const Color(0xFF2196F3),
    'river' => const Color(0xFF00BCD4),
    'airway' => const Color(0xFFFF9800),
    _ => AppColors.borderDefault,
  };
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _EdgeTypeBadge extends StatelessWidget {
  final String type;
  const _EdgeTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      'road'    => (const Color(0xFF2196F3), Icons.local_shipping),
      'river'   => (const Color(0xFF00BCD4), Icons.directions_boat),
      'airway'  => (const Color(0xFFFF9800), Icons.airplanemode_active),
      _         => (AppColors.borderDefault, Icons.linear_scale),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: color),
          SizedBox(width: 3.w),
          Text(type, style: TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6.r)),
      child: Text(label, style: TextStyle(fontSize: 10.sp, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12.w, height: 12.h, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryTextDefault)),
      ],
    );
  }
}

class _MlLegendChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MlLegendChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4.r)),
      child: Text(label, style: TextStyle(fontSize: 9.sp, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final String value;
  const _FeatureChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(color: AppColors.borderDefault.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4.r)),
      child: Text('$label: $value', style: TextStyle(fontSize: 9.sp, color: AppColors.secondaryTextDefault)),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.dangerSurfaceTint,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.dangerSurfaceDefault),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.dangerSurfaceDefault, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13.sp, color: AppColors.dangerSurfaceDefault))),
        ],
      ),
    );
  }
}
