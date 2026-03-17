import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import '../ui/app_theme.dart';
import '../ui/custom_card.dart';
import 'solteros_service.dart';

class SolterosScreen extends StatelessWidget {
  const SolterosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final eventId = userContext.eventId ?? '';
    final viewerId = userContext.userId ?? '';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: _SolterosList(
        eventId: eventId,
        viewerId: viewerId,
      ),
    );
  }
}

class _SolterosList extends StatefulWidget {
  final String eventId;
  final String viewerId;

  const _SolterosList({required this.eventId, required this.viewerId});

  @override
  State<_SolterosList> createState() => _SolterosListState();
}

class _SolterosListState extends State<_SolterosList> {
  final SolterosService _service = SolterosService();
  Future<List<SolteroProfile>>? _future;
  String _q = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<SolteroProfile>> _load() async {
    if (widget.eventId.isEmpty || widget.viewerId.isEmpty) return [];
    return _service.listSingles(eventId: widget.eventId, viewerId: widget.viewerId, q: _q);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar solteros...',
          ),
          onChanged: (v) {
            _q = v;
            setState(() => _future = _load());
          },
        ),
        const SizedBox(height: AppSpacing.x1_5),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<List<SolteroProfile>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text('Error: ${snap.error}')),
                    ],
                  );
                }
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'Aún no hay solteros activados.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final isMe = p.userId == widget.viewerId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x1),
                      child: CustomCard(
                        onTap: isMe ? null : () => context.go('/solteros/dm/${p.userId}'),
                        padding: const EdgeInsets.all(AppSpacing.x1_5),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                isMe ? Icons.person : Icons.favorite_border,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x1_5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMe ? '${p.name} (tú)' : p.name,
                                    style: AppTextStyles.title.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Toca para abrir chat', style: AppTextStyles.subtitle),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.textPrimary.withOpacity(0.35)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
