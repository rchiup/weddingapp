import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../ui/custom_card.dart';
import '../user_context/user_context_provider.dart';
import 'guest_model.dart';
import 'mesas_detail_screen.dart';
import 'mesas_provider.dart';
import 'mesas_validator.dart';

/// Búsqueda / listado de invitados; si el evento publica invitados, lista agrupada por mesa.
class MesasSearchScreen extends StatefulWidget {
  const MesasSearchScreen({super.key});

  @override
  State<MesasSearchScreen> createState() => _MesasSearchScreenState();
}

class _MesasSearchScreenState extends State<MesasSearchScreen> {
  final _nameController = TextEditingController();
  final _tableController = TextEditingController();
  final _searchController = TextEditingController();
  final _quickNameController = TextEditingController();
  final _nameFormKey = GlobalKey<FormState>();
  final _tableFormKey = GlobalKey<FormState>();
  String _listQuery = '';
  String? _quickResult;
  List<GuestModel>? _quickChoices;

  @override
  void dispose() {
    _nameController.dispose();
    _tableController.dispose();
    _searchController.dispose();
    _quickNameController.dispose();
    super.dispose();
  }

  String _mesaPhrase(String tableNumber) {
    final t = tableNumber.trim();
    if (t.isEmpty) return '👉 Aún sin mesa asignada';
    return '👉 Estás en la mesa $t';
  }

  Future<void> _runQuickSearch(BuildContext context, String eventId, MesasProvider provider) async {
    final q = _quickNameController.text.trim();
    if (q.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribí al menos 2 letras')),
      );
      return;
    }
    setState(() {
      _quickResult = null;
      _quickChoices = null;
    });
    await provider.searchGuests(eventId, q);
    if (!mounted) return;
    final r = provider.guestResults;
    if (r.isEmpty) {
      setState(() => _quickResult = 'No encontramos ese nombre. Probá con otra parte del nombre.');
      return;
    }
    if (r.length == 1) {
      setState(() => _quickResult = _mesaPhrase(r.first.tableNumber));
      return;
    }
    setState(() => _quickChoices = r);
  }

  Widget _buildQuickFindCard(
    BuildContext context,
    UserContextProvider userContext,
    MesasProvider provider,
  ) {
    final eventId = userContext.eventId ?? '';
    if (eventId.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
      child: CustomCard(
        padding: const EdgeInsets.all(AppSpacing.x2),
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Busca tu nombre', style: AppTextStyles.title.copyWith(fontSize: 17)),
            const SizedBox(height: AppSpacing.x1),
            TextField(
              controller: _quickNameController,
              decoration: const InputDecoration(
                hintText: 'Ej: María García',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _runQuickSearch(context, eventId, provider),
            ),
            const SizedBox(height: AppSpacing.x1),
            CustomButton(
              label: 'Ver en qué mesa estoy',
              onPressed: provider.isLoading ? null : () => _runQuickSearch(context, eventId, provider),
            ),
            if (_quickResult != null) ...[
              const SizedBox(height: AppSpacing.x1),
              Text(
                _quickResult!,
                style: AppTextStyles.title.copyWith(fontSize: 16, color: AppColors.primaryDark),
              ),
            ],
            if (_quickChoices != null && _quickChoices!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x1),
              Text('Varios resultados — elegí uno:', style: AppTextStyles.subtitle),
              ..._quickChoices!.map(
                (g) => ListTile(
                  dense: true,
                  title: Text(g.name),
                  subtitle: Text(
                    g.tableNumber.trim().isEmpty ? 'Sin mesa' : 'Mesa ${g.tableNumber}',
                  ),
                  onTap: () {
                    setState(() {
                      _quickResult = _mesaPhrase(g.tableNumber);
                      _quickChoices = null;
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userContext = context.read<UserContextProvider>();
      final eventId = userContext.eventId ?? '';
      if (!userContext.settings.guestsVisible || eventId.isEmpty) return;
      await context.read<MesasProvider>().loadAllGuests(eventId);
    });
  }

  List<GuestModel> _filteredAll(MesasProvider provider) {
    final q = _listQuery.trim().toLowerCase();
    if (q.isEmpty) return provider.allGuests;
    return provider.allGuests.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.tableNumber.toLowerCase().contains(q);
    }).toList();
  }

  List<String> _sortedTableKeys(Map<String, List<GuestModel>> byTable) {
    final keys = byTable.keys.toList();
    keys.sort((a, b) {
      final ia = int.tryParse(a) ?? 9999;
      final ib = int.tryParse(b) ?? 9999;
      if (ia != ib) return ia.compareTo(ib);
      return a.compareTo(b);
    });
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final provider = context.watch<MesasProvider>();
    final eventId = userContext.eventId ?? '';
    final guestsVisible = userContext.settings.guestsVisible;

    if (!guestsVisible) {
      return _legacySearch(context, userContext, provider, eventId);
    }

    final filtered = _filteredAll(provider);
    final byTable = <String, List<GuestModel>>{};
    for (final g in filtered) {
      final key = g.tableNumber.trim().isEmpty ? '—' : g.tableNumber.trim();
      byTable.putIfAbsent(key, () => []).add(g);
    }
    final tableKeys = _sortedTableKeys(byTable);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.x2, AppSpacing.x2, AppSpacing.x2, 0),
          child: _buildQuickFindCard(context, userContext, provider),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.x2, 0, AppSpacing.x2, AppSpacing.x1),
          child: Text(
            '${provider.allGuests.length} invitados',
            style: AppTextStyles.subtitle,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Buscar invitado o mesa...',
            ),
            onChanged: (v) => setState(() => _listQuery = v),
          ),
        ),
        const SizedBox(height: AppSpacing.x2),
        Expanded(
          child: provider.isLoading && provider.allGuests.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        provider.allGuests.isEmpty
                            ? 'Aún no hay invitados cargados.'
                            : 'Sin resultados.',
                        style: AppTextStyles.subtitle,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x2,
                        0,
                        AppSpacing.x2,
                        AppSpacing.x3,
                      ),
                      itemCount: tableKeys.length,
                      itemBuilder: (context, ti) {
                        final tableNum = tableKeys[ti];
                        final guests = byTable[tableNum] ?? [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.x1, top: AppSpacing.x1),
                              child: Text(
                                'Mesa $tableNum',
                                style: AppTextStyles.title.copyWith(
                                  fontSize: 15,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            ...guests.map((g) {
                              final initial = g.name.trim().isNotEmpty ? g.name.trim()[0].toUpperCase() : '?';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.x1),
                                child: CustomCard(
                                  padding: const EdgeInsets.all(AppSpacing.x1_5),
                                  elevated: true,
                                  onTap: () async {
                                    final table = await provider.findTableByNumber(eventId, g.tableNumber);
                                    if (!context.mounted || table == null) return;
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MesasDetailScreen(table: table),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primary.withOpacity(0.12),
                                        foregroundColor: AppColors.primaryDark,
                                        child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                      const SizedBox(width: AppSpacing.x1_5),
                                      Expanded(
                                        child: Text(
                                          g.name,
                                          style: AppTextStyles.title.copyWith(fontSize: 15),
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: AppColors.textPrimary.withOpacity(0.25)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _legacySearch(
    BuildContext context,
    UserContextProvider userContext,
    MesasProvider provider,
    String eventId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuickFindCard(context, userContext, provider),
          Text('Buscar mi mesa', style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
          const SizedBox(height: AppSpacing.x2),
          Form(
            key: _tableFormKey,
            child: TextFormField(
              controller: _tableController,
              decoration: const InputDecoration(
                labelText: 'Número de mesa',
              ),
              validator: MesasValidator.validateTableNumber,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          CustomButton(
            label: 'Buscar por número',
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (!_tableFormKey.currentState!.validate()) return;
                    final table = await provider.findTableByNumber(
                      eventId,
                      _tableController.text.trim(),
                    );
                    if (!context.mounted) return;
                    if (table == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mesa no encontrada')),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MesasDetailScreen(table: table),
                      ),
                    );
                  },
          ),
          const SizedBox(height: AppSpacing.x2),
          Form(
            key: _nameFormKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre y apellido',
              ),
              validator: MesasValidator.validateName,
            ),
          ),
          const SizedBox(height: AppSpacing.x1),
          CustomButton(
            label: 'Buscar mi mesa',
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (!_nameFormKey.currentState!.validate()) return;
                    final table = await provider.findTableByGuestNameExact(
                      eventId,
                      _nameController.text.trim(),
                    );
                    if (!context.mounted) return;
                    if (table == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitado no encontrado')),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MesasDetailScreen(table: table),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
