import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../user_context/user_context_provider.dart';
import '../utils/nav_safe.dart';
import 'rsvp_provider.dart';

/// Pantalla rápida para elegir menú normal / vegetariano / vegano.
///
/// No reemplaza el RSVP completo: conserva asistencia, acompañante y alergias.
class DietaryChoiceScreen extends StatelessWidget {
  const DietaryChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userContext = context.read<UserContextProvider>();
    final eventId = userContext.eventId ?? '';
    final userId = userContext.userId ?? '';

    return ChangeNotifierProvider(
      create: (_) => RsvpProvider()..loadRsvp(eventId: eventId, userId: userId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            '🥗 Menú',
            style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
          ),
          backgroundColor: AppColors.background,
          leading: IconButton(
            onPressed: () => popOrEntry(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
          ),
        ),
        body: const _DietaryChoiceBody(),
      ),
    );
  }
}

class _DietaryChoiceBody extends StatefulWidget {
  const _DietaryChoiceBody();

  @override
  State<_DietaryChoiceBody> createState() => _DietaryChoiceBodyState();
}

class _DietaryChoiceBodyState extends State<_DietaryChoiceBody> {
  String? _userChoice;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RsvpProvider>();
    final userContext = context.watch<UserContextProvider>();
    final isActive = userContext.eventActive;

    if (provider.isFetching && provider.rsvp == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final value = _userChoice ?? provider.rsvp?.dietaryPreference ?? 'none';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Elegí tu preferencia de menú para el catering.',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Preferencia de menú',
            style: AppTextStyles.title.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'none',
                label: Text('Normal'),
                icon: Icon(Icons.restaurant),
              ),
              ButtonSegment<String>(
                value: 'vegetarian',
                label: Text('Vegetariano'),
                icon: Icon(Icons.eco_outlined),
              ),
              ButtonSegment<String>(
                value: 'vegan',
                label: Text('Vegano'),
                icon: Icon(Icons.spa_outlined),
              ),
            ],
            selected: {value},
            onSelectionChanged: (Set<String> next) {
              setState(() => _userChoice = next.first);
            },
          ),
          const SizedBox(height: AppSpacing.x2),
          FilledButton(
            onPressed: provider.isSaving || !isActive
                ? null
                : () async {
                    final eventId = userContext.eventId ?? '';
                    final userId = userContext.userId ?? '';
                    try {
                      await provider.saveDietaryPreferenceOnly(
                        eventId: eventId,
                        userId: userId,
                        dietaryPreference: value,
                      );
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se pudo guardar. Revisá tu conexión.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preferencia guardada')),
                      );
                    }
                  },
            child: provider.isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
