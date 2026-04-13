// Module 3 — MeshCore Node Graph Screen
//
// Renders a live topology view of the connected mesh network.
// The connected radio sits at the center; all known contacts are
// arranged radially around it.  Edges are drawn to show hop paths,
// nodes are colour-coded by their advertised type.

import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/meshcore/meshcore_models.dart';
import '../../../core/meshcore/meshcore_protocol.dart';
import '../../util/routes.dart';
import 'providers.dart';

class MeshCoreNodeGraphScreen extends ConsumerStatefulWidget {
  const MeshCoreNodeGraphScreen({super.key});

  @override
  ConsumerState<MeshCoreNodeGraphScreen> createState() =>
      _MeshCoreNodeGraphScreenState();
}

class _MeshCoreNodeGraphScreenState
    extends ConsumerState<MeshCoreNodeGraphScreen>
    with SingleTickerProviderStateMixin {
  List<MeshCoreContact> _contacts = [];
  MeshCoreDeviceInfo? _deviceInfo;
  StreamSubscription<List<MeshCoreContact>>? _contactSub;
  StreamSubscription<MeshCoreDeviceInfo?>? _deviceSub;

  // Pan / zoom
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset _focalPoint = Offset.zero;
  double _baseScale = 1.0;

  // Selected node
  MeshCoreContact? _selectedContact;

  // Subtle pulsing animation for the local node
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribe());
  }

  void _subscribe() {
    final svc = ref.read(meshCoreBleServiceProvider);
    _contacts = svc.contacts;
    _deviceInfo = svc.currentDeviceInfo;

    _contactSub = svc.contactsStream.listen((c) {
      if (mounted) setState(() => _contacts = c);
    });
    _deviceSub = svc.deviceInfoStream.listen((d) {
      if (mounted) setState(() => _deviceInfo = d);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _contactSub?.cancel();
    _deviceSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Node Topology',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '${_contacts.length} node${_contacts.length == 1 ? '' : 's'} discovered',
              style: TextStyle(fontSize: 11.sp, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white70),
            tooltip: 'Fit view',
            onPressed: _resetView,
          ),
          IconButton(
            icon: const Icon(Icons.contacts_outlined, color: Colors.white70),
            tooltip: 'Node list',
            onPressed: () =>
                Navigator.pushNamed(context, Routes.meshcoreContacts),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Canvas ────────────────────────────────────────────────────
          GestureDetector(
            onScaleStart: (d) {
              _focalPoint = d.focalPoint;
              _baseScale = _scale;
            },
            onScaleUpdate: (d) {
              setState(() {
                _scale = (_baseScale * d.scale).clamp(0.4, 4.0);
                final delta = d.focalPoint - _focalPoint;
                _offset += delta;
                _focalPoint = d.focalPoint;
              });
            },
            onTapUp: (d) => _handleTap(d.localPosition, context),
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => CustomPaint(
                painter: _TopologyPainter(
                  contacts: _contacts,
                  localName: _deviceInfo?.selfName.isNotEmpty == true
                      ? _deviceInfo!.selfName
                      : (_deviceInfo?.deviceName ?? 'Node'),
                  offset: _offset,
                  scale: _scale,
                  pulse: _pulseAnim.value,
                  selected: _selectedContact,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // ── Legend ────────────────────────────────────────────────────
          Positioned(left: 12.w, bottom: 24.h, child: const _LegendPanel()),

          // ── Selected node panel ───────────────────────────────────────
          if (_selectedContact != null)
            Positioned(
              left: 12.w,
              right: 12.w,
              top: 12.h,
              child: _NodeDetailCard(
                contact: _selectedContact!,
                onClose: () => setState(() => _selectedContact = null),
                onChat: _selectedContact!.isChatNode
                    ? () {
                        Navigator.pushNamed(
                          context,
                          Routes.meshcoreChat,
                          arguments: {
                            'contactKeyHex': _selectedContact!.publicKeyHex,
                            'contactName': _selectedContact!.name,
                          },
                        );
                      }
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  void _handleTap(Offset local, BuildContext context) {
    final size = context.size ?? Size.zero;
    final center = Offset(size.width / 2, size.height / 2) + _offset;
    final total = _contacts.length;
    if (total == 0) return;

    const baseRadius = 130.0;
    const nodeRadius = 20.0;

    for (int i = 0; i < total; i++) {
      final angle = (2 * math.pi / total) * i - math.pi / 2;
      final radius = baseRadius * _scale;
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if ((local - pos).distance <= nodeRadius * _scale * 1.5) {
        setState(() {
          _selectedContact = _selectedContact == _contacts[i]
              ? null
              : _contacts[i];
        });
        return;
      }
    }
    setState(() => _selectedContact = null);
  }

  void _resetView() => setState(() {
    _offset = Offset.zero;
    _scale = 1.0;
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomPainter — draws the topology graph
// ─────────────────────────────────────────────────────────────────────────────

class _TopologyPainter extends CustomPainter {
  final List<MeshCoreContact> contacts;
  final String localName;
  final Offset offset;
  final double scale;
  final double pulse;
  final MeshCoreContact? selected;

  _TopologyPainter({
    required this.contacts,
    required this.localName,
    required this.offset,
    required this.scale,
    required this.pulse,
    required this.selected,
  });

  static const double _baseRadius = 130.0;
  static const double _localNodeR = 28.0;
  static const double _contactNodeR = 18.0;

  Color _nodeColor(int type) {
    switch (type) {
      case advTypeRepeater:
        return const Color(0xFF00E5FF);
      case advTypeRoom:
        return const Color(0xFF69F0AE);
      case advTypeSensor:
        return const Color(0xFFFFD740);
      default:
        return const Color(0xFF7C4DFF);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + offset;
    final r = _baseRadius * scale;
    final localR = _localNodeR * scale;
    final contactR = _contactNodeR * scale;

    // ── Background grid ───────────────────────────────────────────────
    _drawGrid(canvas, size);

    // ── Pulse ring around local node ──────────────────────────────────
    final pulseR = localR + 16 * pulse * scale;
    canvas.drawCircle(
      center,
      pulseR,
      Paint()
        ..color = const Color(0xFF7C4DFF).withOpacity(0.15 * (1 - pulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Orbit circle
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final total = contacts.length;

    // ── Edges first (drawn below nodes) ───────────────────────────────
    for (int i = 0; i < total; i++) {
      final contact = contacts[i];
      final angle = (2 * math.pi / math.max(total, 1)) * i - math.pi / 2;
      final pos = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      final edgePaint = Paint()
        ..color = _nodeColor(contact.type).withOpacity(0.35)
        ..strokeWidth = 1.5 * scale
        ..style = PaintingStyle.stroke;

      // Dashed edge for multi-hop, solid for direct
      if (contact.pathLength <= 1) {
        canvas.drawLine(center, pos, edgePaint);
      } else {
        _drawDashedLine(canvas, center, pos, edgePaint, dashLen: 6 * scale);
      }

      // Hop count label at midpoint
      if (contact.pathLength > 0) {
        final mid = (center + pos) / 2;
        _drawText(
          canvas,
          '${contact.pathLength}',
          mid,
          const Color(0xFFFFFFFF),
          9 * scale,
        );
      }
    }

    // ── Contact nodes ──────────────────────────────────────────────────
    for (int i = 0; i < total; i++) {
      final contact = contacts[i];
      final isSelected = contact.publicKeyHex == selected?.publicKeyHex;
      final angle = (2 * math.pi / math.max(total, 1)) * i - math.pi / 2;
      final pos = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      final color = _nodeColor(contact.type);

      // Glow
      canvas.drawCircle(
        pos,
        contactR * 1.6,
        Paint()
          ..color = color.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Fill
      canvas.drawCircle(pos, contactR, Paint()..color = color.withOpacity(0.2));

      // Border
      canvas.drawCircle(
        pos,
        contactR,
        Paint()
          ..color = isSelected ? Colors.white : color.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.5 * scale : 1.5 * scale,
      );

      // Icon
      _drawNodeIcon(canvas, pos, contact.type, color, contactR);

      // Name label
      _drawText(
        canvas,
        contact.name.length > 10
            ? '${contact.name.substring(0, 9)}…'
            : contact.name,
        pos + Offset(0, contactR + 10 * scale),
        Colors.white70,
        8.5 * scale,
      );
    }

    // ── Local node (center) ────────────────────────────────────────────
    // Glow
    canvas.drawCircle(
      center,
      localR * 1.8,
      Paint()
        ..color = const Color(0xFF7C4DFF).withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Fill
    canvas.drawCircle(
      center,
      localR,
      Paint()..color = const Color(0xFF7C4DFF).withOpacity(0.35),
    );

    // Border
    canvas.drawCircle(
      center,
      localR,
      Paint()
        ..color = const Color(0xFF7C4DFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale,
    );

    final leftH = localName.length > 10
        ? '${localName.substring(0, 9)}…'
        : localName;
    _drawText(
      canvas,
      leftH,
      center + Offset(0, localR + 10 * scale),
      Colors.white,
      9 * scale,
      bold: true,
    );

    // "YOU" label
    _drawText(canvas, 'YOU', center, Colors.white70, 8 * scale);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double dashLen,
  }) {
    final dist = (end - start).distance;
    final dir = (end - start) / dist;
    double drawn = 0;
    bool drawing = true;
    while (drawn < dist) {
      final segLen = math.min(dashLen, dist - drawn);
      final s = start + dir * drawn;
      final e = start + dir * (drawn + segLen);
      if (drawing) canvas.drawLine(s, e, paint);
      drawn += dashLen;
      drawing = !drawing;
    }
  }

  void _drawNodeIcon(
    Canvas canvas,
    Offset center,
    int type,
    Color color,
    double r,
  ) {
    // Simple geometric icon proxy: circle with inner symbol
    final paint = Paint()..color = color;
    switch (type) {
      case advTypeRepeater:
        // Triangle (signal tower proxy)
        final path = Path()
          ..moveTo(center.dx, center.dy - r * 0.5)
          ..lineTo(center.dx - r * 0.35, center.dy + r * 0.35)
          ..lineTo(center.dx + r * 0.35, center.dy + r * 0.35)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case advTypeSensor:
        // Diamond
        final path = Path()
          ..moveTo(center.dx, center.dy - r * 0.45)
          ..lineTo(center.dx + r * 0.35, center.dy)
          ..lineTo(center.dx, center.dy + r * 0.45)
          ..lineTo(center.dx - r * 0.35, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case advTypeRoom:
        // Square
        canvas.drawRect(
          Rect.fromCenter(center: center, width: r * 0.7, height: r * 0.7),
          paint,
        );
        break;
      default:
        // Circle (person)
        canvas.drawCircle(center, r * 0.28, paint);
        break;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double fontSize, {
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize.clamp(7, 18),
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_TopologyPainter old) =>
      old.contacts != contacts ||
      old.localName != localName ||
      old.offset != offset ||
      old.scale != scale ||
      old.pulse != pulse ||
      old.selected != selected;
}

// ─────────────────────────────────────────────────────────────────────────────
// Legend
// ─────────────────────────────────────────────────────────────────────────────

class _LegendPanel extends StatelessWidget {
  const _LegendPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          _LegendItem(color: Color(0xFF7C4DFF), label: 'Chat node'),
          _LegendItem(color: Color(0xFF00E5FF), label: 'Repeater'),
          _LegendItem(color: Color(0xFF69F0AE), label: 'Room'),
          _LegendItem(color: Color(0xFFFFD740), label: 'Sensor'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected node detail card
// ─────────────────────────────────────────────────────────────────────────────

class _NodeDetailCard extends StatelessWidget {
  final MeshCoreContact contact;
  final VoidCallback onClose;
  final VoidCallback? onChat;

  const _NodeDetailCard({
    required this.contact,
    required this.onClose,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contact.name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${contact.typeLabel}  •  ${contact.hopLabel}  •  '
                  '${contact.publicKeyHex.substring(0, 8)}...',
                  style: TextStyle(fontSize: 10.sp, color: Colors.white60),
                ),
              ],
            ),
          ),
          if (onChat != null) ...[
            SizedBox(width: 8.w),
            TextButton.icon(
              onPressed: onChat,
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: Color(0xFF7C4DFF),
              ),
              label: Text(
                'Chat',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF7C4DFF),
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
              ),
            ),
          ],
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 18.sp, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
