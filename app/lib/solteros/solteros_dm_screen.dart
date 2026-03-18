import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import '../ui/app_theme.dart';
import 'solteros_provider.dart';
import 'solteros_service.dart';

class SolterosDmScreen extends StatefulWidget {
  final String otherUserId;

  const SolterosDmScreen({super.key, required this.otherUserId});

  @override
  State<SolterosDmScreen> createState() => _SolterosDmScreenState();
}

class _SolterosDmScreenState extends State<SolterosDmScreen> {
  final SolterosService _service = SolterosService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  Timer? _timer;
  bool _loading = false;
  bool _sending = false;
  DateTime? _lastSendAt;
  String? _lastSentText;
  List<SolterosMessage> _messages = [];
  String? _lastCreatedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _markRead();
      await _refresh(initial: true);
    });
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SolterosProvider>().clearDmUnread();
    });
  }

  Future<void> _markRead() async {
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    final viewerId = ctx.userId ?? '';
    if (eventId.isEmpty || viewerId.isEmpty || widget.otherUserId.isEmpty) return;
    try {
      await _service.markDmRead(
        eventId: eventId,
        viewerId: viewerId,
        otherUserId: widget.otherUserId,
      );
      if (!mounted) return;
      context.read<SolterosProvider>().clearDmUnread();
      await context.read<SolterosProvider>().refreshStatus();
    } catch (_) {
      // Silencioso.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    if (!mounted || _loading) return;
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    final viewerId = ctx.userId ?? '';
    if (eventId.isEmpty || viewerId.isEmpty || widget.otherUserId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final items = await _service.getDmMessages(
        eventId: eventId,
        viewerId: viewerId,
        otherUserId: widget.otherUserId,
        after: initial ? null : _lastCreatedAt,
        limit: 80,
      );
      if (!mounted) return;
      if (items.isEmpty) return;
      final hadMessages = _messages.isNotEmpty;
      final viewer = viewerId;
      final hasForeign = items.any((m) => m.userId != viewer);
      setState(() {
        _messages = [..._messages, ...items];
        _lastCreatedAt = _messages.isNotEmpty ? _messages.last.createdAt : _lastCreatedAt;
      });
      if ((!initial || hadMessages) && hasForeign) {
        await _markRead();
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      // Silencioso para polling.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_sending) return;
    final now = DateTime.now();
    if (_lastSendAt != null &&
        _lastSentText != null &&
        _lastSentText == text &&
        now.difference(_lastSendAt!).inMilliseconds < 900) {
      return;
    }
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    final viewerId = ctx.userId ?? '';
    final name = (ctx.userName ?? 'Invitado').trim();
    if (eventId.isEmpty || viewerId.isEmpty) return;

    _sending = true;
    _lastSendAt = now;
    _lastSentText = text;
    _controller.clear();

    final optimistic = SolterosMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      userId: viewerId,
      name: name.isEmpty ? 'Invitado' : name,
      text: text,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    setState(() {
      _messages = [..._messages, optimistic];
      _lastCreatedAt = _messages.last.createdAt;
    });

    try {
      await _service.sendDmMessage(
        eventId: eventId,
        viewerId: viewerId,
        name: optimistic.name,
        otherUserId: widget.otherUserId,
        text: text,
      );
      await _refresh();
      if (mounted) {
        await context.read<SolterosProvider>().refreshStatus();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar: $e')),
      );
    } finally {
      _sending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewerId = context.watch<UserContextProvider>().userId ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.x2),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final mine = m.userId == viewerId;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      color: mine ? AppColors.primary.withOpacity(0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppShadows.soft,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!mine)
                          Text(
                            m.name,
                            style: AppTextStyles.subtitle.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        Text(m.text),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.x2, AppSpacing.x1, AppSpacing.x2, AppSpacing.x2),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!_sending) _send();
                      },
                    ),
                  ),
                const SizedBox(width: AppSpacing.x1),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    tooltip: 'Enviar',
                  color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

