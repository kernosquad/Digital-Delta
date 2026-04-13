import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections_plus/flutter_nearby_connections_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../theme/color.dart';
import '../../util/routes.dart';
import 'nearby_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NearbyDevicesScreen — 3-tab screen: Discover · Connected · Group Chat
// ─────────────────────────────────────────────────────────────────────────────

class NearbyDevicesScreen extends ConsumerStatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  ConsumerState<NearbyDevicesScreen> createState() =>
      _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends ConsumerState<NearbyDevicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(nearbyConnectionsProvider.notifier).init(),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    ref.read(nearbyConnectionsProvider.notifier).stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyConnectionsProvider);

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryTextDefault,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Text(
              'Nearby Devices',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(width: 8.w),
            if (state.isInitializing)
              SizedBox(
                width: 14.w,
                height: 14.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primarySurfaceDefault,
                ),
              )
            else if (state.isRunning)
              _StatusPill(
                label: 'Active',
                color: AppColors.primarySurfaceDefault,
              ),
          ],
        ),
        actions: [
          if (!state.isRunning && !state.isInitializing)
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 20.sp),
              tooltip: 'Start scanning',
              onPressed: () =>
                  ref.read(nearbyConnectionsProvider.notifier).init(),
            ),
          SizedBox(width: 4.w),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primarySurfaceDefault,
          labelColor: AppColors.primaryTextDefault,
          unselectedLabelColor: AppColors.secondaryTextDefault,
          labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radar_rounded, size: 15.sp),
                  SizedBox(width: 5.w),
                  const Text('Discover'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_tethering_rounded, size: 15.sp),
                  SizedBox(width: 5.w),
                  const Text('Connected'),
                  if (state.connectedDevices.isNotEmpty) ...[
                    SizedBox(width: 5.w),
                    _Badge(
                      state.connectedDevices.length,
                      AppColors.primarySurfaceDefault,
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 15.sp),
                  SizedBox(width: 5.w),
                  const Text('Chat'),
                  if (state.messages.isNotEmpty) ...[
                    SizedBox(width: 5.w),
                    _Badge(
                      state.messages.length,
                      AppColors.warningSurfaceDefault,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: state.error != null
          ? _ErrorView(
              error: state.error!,
              onRetry: () =>
                  ref.read(nearbyConnectionsProvider.notifier).init(),
            )
          : TabBarView(
              controller: _tabs,
              children: const [
                _DiscoverTab(),
                _ConnectedTab(),
                _GroupChatTab(),
              ],
            ),
    );
  }
}

// ─── Tab 1: Discover ─────────────────────────────────────────────────────────

class _DiscoverTab extends ConsumerStatefulWidget {
  const _DiscoverTab();

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  bool _showTip = false;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    // If still no devices after 15 s, show the "both devices need the app" tip.
    _tipTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _showTip = true);
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyConnectionsProvider);
    final notifier = ref.read(nearbyConnectionsProvider.notifier);

    // Reset tip timer when devices appear
    if (state.devices.isNotEmpty && _showTip) {
      _showTip = false;
    }

    if (!state.isRunning && !state.isInitializing) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Scanning not active',
        subtitle: 'Tap to start discovering nearby devices',
        action: FilledButton.icon(
          onPressed: notifier.init,
          icon: const Icon(Icons.search),
          label: const Text('Start scanning'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primarySurfaceDefault,
          ),
        ),
      );
    }

    if (state.isInitializing) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primarySurfaceDefault,
        ),
      );
    }

    if (state.devices.isEmpty) {
      return Column(
        children: [
          _HowItWorksBanner(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primarySurfaceDefault,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Scanning for nearby devices…',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Keep both phones close with Bluetooth & Wi-Fi on',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                ),
                if (_showTip) ...[SizedBox(height: 24.h), _TipCard()],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _HowItWorksBanner(),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: state.devices.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, i) {
              final device = state.devices[i];
              return _DeviceCard(
                device: device,
                onConnect: () => notifier.connect(device),
                onDisconnect: () => notifier.disconnect(device),
                onChat: () => Navigator.pushNamed(
                  context,
                  Routes.nearbyChat,
                  arguments: {
                    'deviceId': device.deviceId,
                    'deviceName': device.deviceName,
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HowItWorksBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: const Color(0xFF1565C0).withValues(alpha: 0.07),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 15.sp,
            color: const Color(0xFF1565C0),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Both devices must have this screen open and the app running for discovery to work.',
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.warningSurfaceDefault.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.warningSurfaceDefault.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 14.sp,
                  color: AppColors.warningSurfaceDefault,
                ),
                SizedBox(width: 6.w),
                Text(
                  'No devices found yet — tips',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warningSurfaceDefault,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ...[
              '1. Open Digital Delta on the other phone',
              '2. Navigate to Nearby Devices screen',
              '3. Keep both phones within 5 metres',
              '4. Ensure Bluetooth & Wi-Fi are on',
            ].map(
              (t) => Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Connected ────────────────────────────────────────────────────────

class _ConnectedTab extends ConsumerWidget {
  const _ConnectedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nearbyConnectionsProvider);
    final notifier = ref.read(nearbyConnectionsProvider.notifier);

    if (state.connectedDevices.isEmpty) {
      return const _EmptyState(
        icon: Icons.link_off_rounded,
        title: 'No connected devices',
        subtitle: 'Discover and connect from the Discover tab',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: state.connectedDevices.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, i) {
        final device = state.connectedDevices[i];
        final msgCount = state.messages
            .where((m) => m.deviceId == device.deviceId)
            .length;

        return _ConnectedDeviceCard(
          device: device,
          messageCount: msgCount,
          onChat: () => Navigator.pushNamed(
            context,
            Routes.nearbyChat,
            arguments: {
              'deviceId': device.deviceId,
              'deviceName': device.deviceName,
            },
          ),
          onDisconnect: () => notifier.disconnect(device),
        );
      },
    );
  }
}

// ─── Tab 3: Group Chat ───────────────────────────────────────────────────────

class _GroupChatTab extends ConsumerStatefulWidget {
  const _GroupChatTab();

  @override
  ConsumerState<_GroupChatTab> createState() => _GroupChatTabState();
}

class _GroupChatTabState extends ConsumerState<_GroupChatTab> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(nearbyConnectionsProvider.notifier).sendBroadcast(text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nearbyConnectionsProvider);
    final hasConnected = state.connectedDevices.isNotEmpty;

    return Column(
      children: [
        if (!hasConnected)
          _WarningBar('No connected devices — messages will not be sent'),
        Expanded(
          child: state.messages.isEmpty
              ? const _EmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No messages yet',
                  subtitle: 'Connect to a device and start chatting',
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  itemCount: state.messages.length,
                  itemBuilder: (context, i) =>
                      _MessageBubble(message: state.messages[i]),
                ),
        ),
        _ChatInput(
          controller: _controller,
          enabled: hasConnected,
          hint: hasConnected
              ? 'Broadcast to all connected devices…'
              : 'Connect to a device first',
          onSend: _send,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge(this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 9.sp,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52.sp, color: AppColors.secondaryTextDefault),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTextDefault,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4.h),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.secondaryTextDefault,
                ),
              ),
            ],
            if (action != null) ...[SizedBox(height: 20.h), action!],
          ],
        ),
      ),
    );
  }
}

class _WarningBar extends StatelessWidget {
  final String text;
  const _WarningBar(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: AppColors.warningSurfaceDefault.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 15.sp,
            color: AppColors.warningSurfaceDefault,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.warningSurfaceDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48.sp,
              color: AppColors.dangerSurfaceDefault,
            ),
            SizedBox(height: 12.h),
            Text(
              'Failed to start nearby service',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.secondaryTextDefault,
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primarySurfaceDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Device cards ─────────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onChat;

  const _DeviceCard({
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final connected = device.state == SessionState.connected;
    final connecting = device.state == SessionState.connecting;
    final stateColor = _stateColor(device.state);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: connected
              ? AppColors.primarySurfaceDefault.withValues(alpha: 0.4)
              : AppColors.borderDefault,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // avatar
          Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              connected
                  ? Icons.phone_android_rounded
                  : Icons.smartphone_rounded,
              size: 22.sp,
              color: stateColor,
            ),
          ),
          SizedBox(width: 12.w),
          // name + state
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stateColor,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      _stateName(device.state),
                      style: TextStyle(fontSize: 11.sp, color: stateColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // chat button (connected only)
          if (connected)
            IconButton(
              icon: Icon(
                Icons.chat_bubble_rounded,
                size: 18.sp,
                color: AppColors.primarySurfaceDefault,
              ),
              tooltip: 'Open chat',
              onPressed: onChat,
            ),
          SizedBox(width: 2.w),
          // connect / disconnect pill
          GestureDetector(
            onTap: connecting ? null : (connected ? onDisconnect : onConnect),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color:
                    (connecting
                            ? AppColors.secondaryTextDefault
                            : connected
                            ? AppColors.dangerSurfaceDefault
                            : AppColors.primarySurfaceDefault)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                connecting
                    ? 'Waiting…'
                    : connected
                    ? 'Disconnect'
                    : 'Connect',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: connecting
                      ? AppColors.secondaryTextDefault
                      : connected
                      ? AppColors.dangerSurfaceDefault
                      : AppColors.primarySurfaceDefault,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stateName(SessionState s) => switch (s) {
    SessionState.notConnected => 'Not connected',
    SessionState.connecting => 'Connecting…',
    _ => 'Connected',
  };

  Color _stateColor(SessionState s) => switch (s) {
    SessionState.notConnected => AppColors.secondaryTextDefault,
    SessionState.connecting => AppColors.warningSurfaceDefault,
    _ => AppColors.primarySurfaceDefault,
  };
}

class _ConnectedDeviceCard extends StatelessWidget {
  final Device device;
  final int messageCount;
  final VoidCallback onChat;
  final VoidCallback onDisconnect;

  const _ConnectedDeviceCard({
    required this.device,
    required this.messageCount,
    required this.onChat,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChat,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.primarySurfaceDefault.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: AppColors.primarySurfaceDefault.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android_rounded,
                size: 22.sp,
                color: AppColors.primarySurfaceDefault,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryTextDefault,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    messageCount == 0
                        ? 'Tap to open chat'
                        : '$messageCount message${messageCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.secondaryTextDefault,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.link_off_rounded,
                size: 18.sp,
                color: AppColors.dangerSurfaceDefault,
              ),
              tooltip: 'Disconnect',
              onPressed: onDisconnect,
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: AppColors.secondaryTextDefault,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final NearbyMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14.r,
              backgroundColor: AppColors.secondaryTextDefault.withValues(
                alpha: 0.15,
              ),
              child: Text(
                message.deviceName.isNotEmpty
                    ? message.deviceName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.secondaryTextDefault,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 3.h),
                    child: Text(
                      message.deviceName,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.secondaryTextDefault,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primarySurfaceDefault
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14.r),
                      topRight: Radius.circular(14.r),
                      bottomLeft: Radius.circular(isMe ? 14.r : 2.r),
                      bottomRight: Radius.circular(isMe ? 2.r : 14.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isMe ? Colors.white : AppColors.primaryTextDefault,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    DateFormat('HH:mm').format(message.time),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.disabledTextDefault,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) SizedBox(width: 8.w),
        ],
      ),
    );
  }
}

// ─── Chat input ───────────────────────────────────────────────────────────────

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primaryTextDefault,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.secondaryTextDefault,
                  ),
                  filled: true,
                  fillColor: AppColors.colorBackground,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Material(
              color: enabled
                  ? AppColors.primarySurfaceDefault
                  : AppColors.borderDefault,
              borderRadius: BorderRadius.circular(20.r),
              child: InkWell(
                onTap: enabled ? onSend : null,
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: Icon(
                    Icons.send_rounded,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
