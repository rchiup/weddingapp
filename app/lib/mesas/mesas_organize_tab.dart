import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../user_context/user_context_provider.dart';
import 'guest_list_upload_card.dart';
import 'guest_model.dart';
import 'mesas_provider.dart';
import 'mesas_service.dart';

/// Panel novios: subida Excel y edición de mesas.
class MesasOrganizeTab extends StatefulWidget {
  const MesasOrganizeTab({super.key});

  @override
  State<MesasOrganizeTab> createState() => _MesasOrganizeTabState();
}

class _MesasOrganizeTabState extends State<MesasOrganizeTab> {
  final MesasService _mesasService = MesasService();
  final Set<String> _extraTables = {};

  int _maxTableNumeric(List<GuestModel> guests) {
    var m = 0;
    for (final g in guests) {
      final n = int.tryParse(g.tableNumber.trim());
      if (n != null && n > m) m = n;
    }
    for (final t in _extraTables) {
      final n = int.tryParse(t);
      if (n != null && n > m) m = n;
    }
    return m;
  }

  List<String> _tableOptions(List<GuestModel> guests) {
    final s = <String>{};
    for (final g in guests) {
      final t = g.tableNumber.trim();
      if (t.isNotEmpty) s.add(t);
    }
    s.addAll(_extraTables);
    final list = s.toList();
    list.sort((a, b) {
      final ia = int.tryParse(a) ?? 9999;
      final ib = int.tryParse(b) ?? 9999;
      if (ia != ib) return ia.compareTo(ib);
      return a.compareTo(b);
    });
    return list;
  }

  List<String> _sortedTableKeys(Map<String, List<GuestModel>> byTable) {
    final keys = byTable.keys.toList();
    keys.sort((a, b) {
      if (a == '—') return 1;
      if (b == '—') return -1;
      final ia = int.tryParse(a) ?? 9999;
      final ib = int.tryParse(b) ?? 9999;
      if (ia != ib) return ia.compareTo(ib);
      return a.compareTo(b);
    });
    return keys;
  }

  Future<void> _moveGuest(String eventId, GuestModel guest, String newTable, MesasProvider provider) async {
    try {
      await _mesasService.updateGuestTable(eventId, guest.id, newTable);
      await provider.loadAllGuests(eventId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeTable(String eventId, String tableNum, MesasProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Quitar mesa $tableNum'),
        content: const Text('Los invitados de esta mesa quedarán sin mesa asignada.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitar mesa')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _mesasService.clearTable(eventId, tableNum);
      setState(() => _extraTables.remove(tableNum));
      await provider.loadAllGuests(eventId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<UserContextProvider>().eventId ?? '';
      if (id.isNotEmpty) {
        context.read<MesasProvider>().loadAllGuests(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final provider = context.watch<MesasProvider>();
    final eventId = userContext.eventId ?? '';

    if (eventId.isEmpty) {
      return const Center(child: Text('Sin evento'));
    }

    final guests = provider.allGuests;
    final options = _tableOptions(guests);
    final byTable = <String, List<GuestModel>>{};
    for (final g in guests) {
      final key = g.tableNumber.trim().isEmpty ? '—' : g.tableNumber.trim();
      byTable.putIfAbsent(key, () => []).add(g);
    }
    final keys = _sortedTableKeys(byTable);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.x2, AppSpacing.x2, AppSpacing.x2, AppSpacing.x1),
          child: GuestListUploadCard(
            showTitle: false,
            compactDescription: true,
            afterUpload: (id) async {
              await provider.loadAllGuests(id);
              if (mounted) setState(() => _extraTables.clear());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
          child: Wrap(
            spacing: AppSpacing.x1,
            runSpacing: AppSpacing.x1,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final next = _maxTableNumeric(guests) + 1;
                  setState(() => _extraTables.add(next.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mesa $next disponible en el menú de cada invitado')),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva mesa'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x1),
        Expanded(
          child: provider.isLoading && guests.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : guests.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.x2),
                        child: Text(
                          'Sube tu lista para comenzar.\n\nColumnas: name, last_name (obligatorias). Opcionales: email, phone, table.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x2,
                        0,
                        AppSpacing.x2,
                        AppSpacing.x3,
                      ),
                      itemCount: keys.length,
                      itemBuilder: (context, i) {
                        final tableKey = keys[i];
                        final list = byTable[tableKey] ?? [];
                        final tableNum = tableKey == '—' ? '' : tableKey;
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.x1),
                          child: ExpansionTile(
                            title: Text(
                              tableKey == '—' ? 'Sin mesa' : 'Mesa $tableKey',
                              style: AppTextStyles.title.copyWith(fontSize: 16),
                            ),
                            children: [
                              if (tableKey != '—')
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _removeTable(eventId, tableNum, provider),
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    label: const Text('Quitar mesa'),
                                  ),
                                ),
                              ...list.map((g) {
                              final cur = g.tableNumber.trim();
                              return ListTile(
                                title: Text(g.name, style: AppTextStyles.title.copyWith(fontSize: 15)),
                                subtitle: (g.email.isNotEmpty || g.phone.isNotEmpty)
                                    ? Text(
                                        [g.email, g.phone].where((s) => s.isNotEmpty).join(' · '),
                                        style: AppTextStyles.subtitle,
                                      )
                                    : null,
                                trailing: SizedBox(
                                  width: 140,
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: cur.isEmpty ? '' : cur,
                                    items: [
                                      const DropdownMenuItem(value: '', child: Text('Sin mesa')),
                                      ...options.map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text('Mesa $t'),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v == null) return;
                                      _moveGuest(eventId, g, v, provider);
                                    },
                                  ),
                                ),
                              );
                            }),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
