import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'solteros_provider.dart';
import '../ui/app_theme.dart';
import 'solteros_service.dart';

class SolterosChatScreen extends StatefulWidget {
  const SolterosChatScreen({super.key});

  @override
  State<SolterosChatScreen> createState() => _SolterosChatScreenState();
}

class _SolterosChatScreenState extends State<SolterosChatScreen> {
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
    // Al abrir el chat global, limpiamos el indicador de pendientes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SolterosProvider>().clearGlobalUnread();
    });
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
    if (eventId.isEmpty || viewerId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final items = await _service.getGlobalMessages(
        eventId: eventId,
        viewerId: viewerId,
        after: initial ? null : _lastCreatedAt,
        limit: 80,
      );
      if (!mounted) return;
      if (items.isEmpty) return;
      final hadMessages = _messages.isNotEmpty;
      setState(() {
        _messages = [..._messages, ...items];
        _lastCreatedAt = _messages.isNotEmpty ? _messages.last.createdAt : _lastCreatedAt;
      });
      // Si llegaron mensajes nuevos y alguno no es mío, marcamos como no leído
      // (cuando no estamos ya dentro del chat se verá en el menú).
      if (!initial || hadMessages) {
        final viewer = viewerId;
        final hasForeign = items.any((m) => m.userId != viewer);
        if (hasForeign) {
          context.read<SolterosProvider>().markGlobalUnread();
        }
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
      // Silencioso para polling; errores se ven al enviar.
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

    // Optimistic
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
      await _service.sendGlobalMessage(
        eventId: eventId,
        viewerId: viewerId,
        name: optimistic.name,
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

    return Column(
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
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje...'),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  tooltip: 'Enviar',
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

