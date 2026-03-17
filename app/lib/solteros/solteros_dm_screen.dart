import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
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
  List<SolterosMessage> _messages = [];
  String? _lastCreatedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(initial: true));
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
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
      setState(() {
        _messages = [..._messages, ...items];
        _lastCreatedAt = _messages.isNotEmpty ? _messages.last.createdAt : _lastCreatedAt;
      });
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
    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    final viewerId = ctx.userId ?? '';
    final name = (ctx.userName ?? 'Invitado').trim();
    if (eventId.isEmpty || viewerId.isEmpty) return;

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewerId = context.watch<UserContextProvider>().userId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
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
                      color: mine ? Colors.pink.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!mine)
                          Text(
                            m.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                    tooltip: 'Enviar',
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

