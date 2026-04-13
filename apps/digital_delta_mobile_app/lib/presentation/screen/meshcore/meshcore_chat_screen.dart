// Module 2/3 — MeshCore Chat Screen
//
// Direct end-to-end encrypted chat with a mesh node.
// Accepts route arguments: { 'contactKeyHex': String, 'contactName': String }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/meshcore/meshcore_models.dart';
import '../../theme/color.dart';
import 'providers.dart';

class MeshCoreChatScreen extends ConsumerStatefulWidget {
  const MeshCoreChatScreen({super.key});

  @override
  ConsumerState<MeshCoreChatScreen> createState() => _MeshCoreChatScreenState();
}

class _MeshCoreChatScreenState extends ConsumerState<MeshCoreChatScreen> {
  late final String _contactKeyHex;
  late final String _contactName;
  late final TextEditingController _inputCtrl;
  late final FocusNode _focusNode;
  late final ScrollController _scrollCtrl;

  List<MeshCoreMessage> _messages = [];
  StreamSubscription<Map<String, List<MeshCoreMessage>>>? _sub;
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    _contactKeyHex = args['contactKeyHex'] ?? '';
    _contactName = args['contactName'] ?? 'Unknown';
  }

  @override
  void initState() {
    super.initState();
    _inputCtrl = TextEditingController();
    _focusNode = FocusNode();
    _scrollCtrl = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMessages();
    });
  }

  void _initMessages() {
    final svc = ref.read(meshCoreBleServiceProvider);
    _messages = svc.messagesFor(_contactKeyHex);
    _scrollToBottom();

    _sub = svc.conversationsStream.listen((convs) {
      if (!mounted) return;
      setState(() {
        _messages = convs[_contactKeyHex] ?? [];
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _inputCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final svc = ref.read(meshCoreBleServiceProvider);
    final contact = svc.contactByKeyHex(_contactKeyHex);
    if (contact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact not found on mesh.')),
      );
      return;
    }

    setState(() => _sending = true);
    _inputCtrl.clear();

    try {
      await svc.sendMessage(contact, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Send failed: $e'),
          backgroundColor: AppColors.dangerSurfaceDefault,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connState =
        ref.watch(meshCoreConnectionStateProvider).valueOrNull ??
        MeshCoreConnectionState.disconnected;

    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      appBar: _ChatAppBar(
        name: _contactName,
        keyHex: _contactKeyHex,
        isConnected: connState == MeshCoreConnectionState.connected,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChat(contactName: _contactName)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final prevMsg = i > 0 ? _messages[i - 1] : null;
                      final showDateSep =
                          prevMsg == null ||
                          !_sameDay(prevMsg.timestamp, msg.timestamp);
                      return Column(
                        children: [
                          if (showDateSep) _DateSeparator(date: msg.timestamp),
                          _MessageBubble(message: msg),
                        ],
                      );
                    },
                  ),
          ),

          // ── Input bar ─────────────────────────────────────────────────
          _InputBar(
            ctrl: _inputCtrl,
            focusNode: _focusNode,
            sending: _sending,
            onSend: _send,
            connState: connState,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String keyHex;
  final bool isConnected;

  const _ChatAppBar({
    required this.name,
    required this.keyHex,
    required this.isConnected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primaryTextDefault,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.primarySurfaceTint,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primarySurfaceDefault,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTextDefault,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? AppColors.statusOnline
                            : AppColors.dangerSurfaceDefault,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isConnected ? 'Connected' : 'Offline',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.secondaryTextDefault,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    String label;
    if (_sameDay(date, today)) {
      label = 'Today';
    } else if (_sameDay(date, today.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      label = DateFormat.yMMMd().format(date);
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.secondaryTextDefault,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MeshCoreMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isOut = message.isOutgoing;

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Align(
        alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 0.75.sw),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isOut ? AppColors.primarySurfaceDefault : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.r),
                topRight: Radius.circular(14.r),
                bottomLeft: Radius.circular(isOut ? 14.r : 4.r),
                bottomRight: Radius.circular(isOut ? 4.r : 14.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
              border: isOut ? null : Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isOut ? Colors.white : AppColors.primaryTextDefault,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat.jm().format(message.timestamp),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: isOut
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.secondaryTextDefault,
                      ),
                    ),
                    if (isOut) ...[
                      SizedBox(width: 4.w),
                      _StatusIcon(status: message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final MeshCoreMessageStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MeshCoreMessageStatus.pending:
        return Icon(Icons.access_time, size: 11.sp, color: Colors.white70);
      case MeshCoreMessageStatus.sent:
        return Icon(Icons.check, size: 11.sp, color: Colors.white70);
      case MeshCoreMessageStatus.delivered:
        return Icon(Icons.done_all, size: 11.sp, color: Colors.white);
      case MeshCoreMessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 11.sp,
          color: AppColors.dangerSurfaceDefault,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final MeshCoreConnectionState connState;

  const _InputBar({
    required this.ctrl,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.connState,
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(() {
      final next = widget.ctrl.text.trim().isNotEmpty;
      if (next != _hasText) setState(() => _hasText = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.connState == MeshCoreConnectionState.connected;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        12.w,
        10.h,
        12.w,
        MediaQuery.of(context).viewInsets.bottom + 10.h,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.ctrl,
              focusNode: widget.focusNode,
              enabled: isConnected,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.primaryTextDefault,
              ),
              decoration: InputDecoration(
                hintText: isConnected
                    ? 'Type a message…'
                    : 'Connect to radio to send',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.secondaryTextDefault,
                ),
                filled: true,
                fillColor: AppColors.colorBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
              ),
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          SizedBox(width: 8.w),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FloatingActionButton.small(
              elevation: 0,
              backgroundColor: isConnected && _hasText
                  ? AppColors.primarySurfaceDefault
                  : AppColors.borderDefault,
              onPressed: isConnected && _hasText && !widget.sending
                  ? widget.onSend
                  : null,
              child: widget.sending
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.send, size: 18.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String contactName;

  const _EmptyChat({required this.contactName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 56.sp,
            color: AppColors.borderDefault,
          ),
          SizedBox(height: 12.h),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTextDefault,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Start a conversation with $contactName',
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
