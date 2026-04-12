import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/service/sync_mesh_service.dart';
import '../../../di/cache_module.dart';
import '../../../domain/model/ble/ble_device_model.dart';
import '../../../domain/model/operations/operations_snapshot_model.dart';
import '../../theme/color.dart';
import '../ble/notifier/provider.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final _chatProvider =
    StateNotifierProvider.family<_ChatNotifier, _ChatState, String>(
      (ref, peerUuid) => _ChatNotifier(peerUuid),
    );

class _ChatState {
  final List<ChatMessageEntry> messages;
  final String peerName;
  final bool isConnected;
  final bool isSending;

  const _ChatState({
    this.messages = const [],
    this.peerName = '',
    this.isConnected = false,
    this.isSending = false,
  });

  _ChatState copyWith({
    List<ChatMessageEntry>? messages,
    String? peerName,
    bool? isConnected,
    bool? isSending,
  }) => _ChatState(
    messages: messages ?? this.messages,
    peerName: peerName ?? this.peerName,
    isConnected: isConnected ?? this.isConnected,
    isSending: isSending ?? this.isSending,
  );
}

class _ChatNotifier extends StateNotifier<_ChatState> {
  _ChatNotifier(this._peerUuid) : super(const _ChatState()) {
    _init();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  final String _peerUuid;
  Timer? _timer;

  void _init() {
    final svc = getIt<SyncMeshService>();
    final peers = svc.getKnownPeers();
    final peer = peers.where((p) => p.nodeUuid == _peerUuid).toList();
    final peerName = peer.isNotEmpty
        ? peer.first.displayName
        : 'Nearby peer';
    svc.markMessagesRead(_peerUuid);
    state = state.copyWith(
      peerName: peerName,
      messages: svc.getChatMessages(_peerUuid),
    );
  }

  void _refresh() {
    if (!mounted) return;
    final svc = getIt<SyncMeshService>();
    final messages = svc.getChatMessages(_peerUuid);
    svc.markMessagesRead(_peerUuid);
    state = state.copyWith(messages: messages);
  }

  Future<void> send(String content) async {
    if (content.trim().isEmpty) return;
    state = state.copyWith(isSending: true);
    try {
      await getIt<SyncMeshService>().sendChatMessage(_peerUuid, content.trim());
    } finally {
      _refresh();
      state = state.copyWith(isSending: false);
    }
  }

  void updateConnection(bool connected) {
    state = state.copyWith(isConnected: connected);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MeshChatScreen extends ConsumerStatefulWidget {
  final String peerNodeUuid;
  final String? initialPeerName;

  const MeshChatScreen({
    super.key,
    required this.peerNodeUuid,
    this.initialPeerName,
  });

  @override
  ConsumerState<MeshChatScreen> createState() => _MeshChatScreenState();
}

class _MeshChatScreenState extends ConsumerState<MeshChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(_chatProvider(widget.peerNodeUuid));
    final bleState = ref.watch(bleNotifierProvider);

    // Determine if this peer is currently connected via BLE
    final connectedDevices = bleState.maybeWhen(
      scanning: (d) => d,
      idle: (d) => d,
      orElse: () => <dynamic>[],
    );
    final isConnected = connectedDevices.any(
      (d) => d.id == widget.peerNodeUuid && d.connectionState.isConnected,
    );

    ref.listen(bleNotifierProvider, (_, __) {
      final latest = ref.read(bleNotifierProvider);
      final devices = latest.maybeWhen(
        scanning: (d) => d,
        idle: (d) => d,
        orElse: () => <BleDeviceModel>[],
      );
      final connected = devices.any(
        (d) => d.id == widget.peerNodeUuid && d.connectionState.isConnected,
      );
      ref
          .read(_chatProvider(widget.peerNodeUuid).notifier)
          .updateConnection(connected);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            // Peer avatar
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isConnected ? Colors.green : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.cell_tower,
                  size: 18.sp,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatState.peerName.isNotEmpty
                        ? chatState.peerName
                        : (widget.initialPeerName ?? 'Mesh Node'),
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: isConnected ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isConnected ? 'BLE Connected' : 'Not Connected',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isConnected ? Colors.green : Colors.grey,
                        ),
                      ),
                      if (!isConnected) ...[
                        SizedBox(width: 6.w),
                        Text(
                          '· messages queued',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Encryption indicator (M3.3)
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: Tooltip(
              message: 'E2E encrypted — relay nodes cannot read contents',
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 12.sp, color: Colors.green),
                    SizedBox(width: 4.w),
                    Text(
                      'E2E',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection warning banner
          if (!isConnected)
            Container(
              width: double.infinity,
              color: Colors.orange.withValues(alpha: 0.1),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14.sp, color: Colors.orange),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Not BLE connected — messages stored for delivery when peer reconnects (store-and-forward M3.1)',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48.sp,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Messages are E2E encrypted and relayed\nvia BLE mesh (Module 3)',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
                    itemCount: chatState.messages.length,
                    itemBuilder: (_, i) =>
                        _MessageBubble(message: chatState.messages[i]),
                  ),
          ),

          // Input bar
          _ChatInputBar(
            controller: _input,
            isSending: chatState.isSending,
            onSend: (text) async {
              _input.clear();
              await ref
                  .read(_chatProvider(widget.peerNodeUuid).notifier)
                  .send(text);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessageEntry message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSent = message.isSent;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSent ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isSent ? 16.r : 4.r),
            bottomRight: Radius.circular(isSent ? 4.r : 16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 13.sp,
                color: isSent ? Colors.white : AppColors.primaryTextDefault,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isEncrypted) ...[
                  Icon(
                    Icons.lock,
                    size: 9.sp,
                    color: isSent ? Colors.white54 : Colors.grey.shade400,
                  ),
                  SizedBox(width: 3.w),
                ],
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: isSent ? Colors.white54 : Colors.grey.shade400,
                  ),
                ),
                if (isSent) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    message.isDelivered ? Icons.done_all : Icons.schedule,
                    size: 12.sp,
                    color: message.isDelivered
                        ? Colors.lightBlueAccent
                        : Colors.white38,
                  ),
                ],
              ],
            ),
            // Hop count indicator for relayed messages
            if (message.hopCount > 0) ...[
              SizedBox(height: 2.h),
              Text(
                '${message.hopCount} hop${message.hopCount > 1 ? 's' : ''} relayed',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: isSent ? Colors.white38 : Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final Future<void> Function(String) onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Message (E2E encrypted)…',
                  hintStyle: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                style: TextStyle(fontSize: 13.sp),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: isSending
                ? null
                : () {
                    final text = controller.text;
                    if (text.trim().isNotEmpty) onSend(text);
                  },
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: isSending ? Colors.grey.shade300 : Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}
