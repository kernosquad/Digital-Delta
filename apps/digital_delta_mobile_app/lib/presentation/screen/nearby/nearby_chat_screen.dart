import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../theme/color.dart';
import 'nearby_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NearbyChatScreen — 1:1 chat with a specific nearby device
// ─────────────────────────────────────────────────────────────────────────────

class NearbyChatScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String deviceName;

  const NearbyChatScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  ConsumerState<NearbyChatScreen> createState() => _NearbyChatScreenState();
}

class _NearbyChatScreenState extends ConsumerState<NearbyChatScreen> {
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
    ref
        .read(nearbyConnectionsProvider.notifier)
        .sendMessage(widget.deviceId, text);
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

    // Only show messages exchanged with this device.
    final messages = state.messages
        .where((m) => m.deviceId == widget.deviceId)
        .toList();

    final isConnected = state.connectedDevices.any(
      (d) => d.deviceId == widget.deviceId,
    );

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryTextDefault,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16.r,
              backgroundColor: AppColors.primarySurfaceDefault.withValues(
                alpha: 0.12,
              ),
              child: Text(
                widget.deviceName.isNotEmpty
                    ? widget.deviceName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primarySurfaceDefault,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.deviceName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? AppColors.primarySurfaceDefault
                            : AppColors.secondaryTextDefault,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isConnected
                            ? AppColors.primarySurfaceDefault
                            : AppColors.secondaryTextDefault,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (isConnected)
            IconButton(
              icon: Icon(
                Icons.link_off_rounded,
                size: 20.sp,
                color: AppColors.dangerSurfaceDefault,
              ),
              tooltip: 'Disconnect',
              onPressed: () {
                final device = state.connectedDevices.firstWhere(
                  (d) => d.deviceId == widget.deviceId,
                );
                ref.read(nearbyConnectionsProvider.notifier).disconnect(device);
                Navigator.pop(context);
              },
            ),
          SizedBox(width: 4.w),
        ],
      ),
      body: Column(
        children: [
          if (!isConnected) _DisconnectedBanner(deviceName: widget.deviceName),
          Expanded(
            child: messages.isEmpty
                ? _EmptyChat(
                    isConnected: isConnected,
                    deviceName: widget.deviceName,
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _Bubble(message: messages[i]),
                  ),
          ),
          _InputBar(
            controller: _controller,
            enabled: isConnected,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _DisconnectedBanner extends StatelessWidget {
  final String deviceName;
  const _DisconnectedBanner({required this.deviceName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: AppColors.dangerSurfaceDefault.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            Icons.link_off_rounded,
            size: 14.sp,
            color: AppColors.dangerSurfaceDefault,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '$deviceName is no longer connected',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.dangerSurfaceDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final bool isConnected;
  final String deviceName;
  const _EmptyChat({required this.isConnected, required this.deviceName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected
                ? Icons.chat_bubble_outline_rounded
                : Icons.link_off_rounded,
            size: 52.sp,
            color: AppColors.secondaryTextDefault,
          ),
          SizedBox(height: 14.h),
          Text(
            isConnected ? 'No messages yet' : 'Not connected',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTextDefault,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            isConnected
                ? 'Say hello to $deviceName!'
                : 'Go back and connect to start chatting',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.secondaryTextDefault,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final NearbyMessage message;
  const _Bubble({required this.message});

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

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
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
                  hintText: enabled
                      ? 'Type a message…'
                      : 'Device not connected',
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
