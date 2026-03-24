import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../user_context/user_context_provider.dart';
import 'event_join_provider.dart';
import 'event_join_validator.dart';

/// Unión al evento: nombre + código (invitados); novios pueden omitir nombre.
class EventJoinScreen extends StatefulWidget {
  const EventJoinScreen({super.key});

  @override
  State<EventJoinScreen> createState() => _EventJoinScreenState();
}

class _EventJoinScreenState extends State<EventJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventJoinProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2, vertical: AppSpacing.x2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_border_rounded, color: AppColors.primary, size: 26),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Wedding App',
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Únete al evento de alguien especial',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.x3),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.soft,
              border: Border.all(color: AppColors.border.withOpacity(0.85)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tu nombre',
                    style: AppTextStyles.title.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Ej: María García',
                    ),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Código del evento',
                    style: AppTextStyles.title.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      hintText: 'Ej: CAROYNONI',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: EventJoinValidator.validateCode,
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'El código te lo dieron los novios 💍',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  CustomButton(
                    label: 'Unirme al evento',
                    loading: provider.isLoading,
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final codeRaw = _codeController.text;
                            final isNovios = EventJoinValidator.isNoviosAdminCode(codeRaw);
                            final name = _nameController.text.trim();
                            if (!isNovios) {
                              final nameErr = EventJoinValidator.validateGuestName(name);
                              if (nameErr != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(nameErr)),
                                );
                                return;
                              }
                            }
                            final userContext = context.read<UserContextProvider>();
                            if (name.isNotEmpty) {
                              await userContext.setUserName(name);
                            }
                            final ok = await provider.joinByCode(
                              code: codeRaw,
                              userContext: userContext,
                            );
                            if (!mounted) return;
                            if (ok) {
                              context.go('/entry');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(provider.errorMessage ?? 'Error')),
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            'Demo: CAROYNONI (invitado) · CAROYNONI-NOVIOS (admin)',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
