import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const String _createEventUrl = 'https://weddingapp-c6ix.onrender.com';

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _openCreateEvent() async {
    final uri = Uri.tryParse(_createEventUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _pasteCodeFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = (data?.text ?? '').trim();
    if (text.isEmpty) return;
    _codeController.text = text.toUpperCase();
    _codeController.selection = TextSelection.fromPosition(
      TextPosition(offset: _codeController.text.length),
    );
  }

  Future<void> _tryJoin() async {
    final provider = context.read<EventJoinProvider>();
    if (provider.isLoading) return;
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
      if (!context.mounted) return;
      context.go('/entry');
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Error')),
      );
    }
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5E8E8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5D4D4), width: 1),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                color: AppColors.joinAccent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Wedding App',
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Únete al evento de alguien especial',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textMuted.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.soft,
              border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
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
                    decoration: InputDecoration(
                      hintText: 'Ej: CAROYNONI',
                      suffixIcon: IconButton(
                        tooltip: 'Pegar',
                        icon: const Icon(Icons.content_paste_rounded),
                        onPressed: _pasteCodeFromClipboard,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: EventJoinValidator.validateCode,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _tryJoin(),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    'El código te lo dieron los novios 💍',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  CustomButton(
                    label: 'Unirme al evento',
                    backgroundColor: AppColors.joinAccent,
                    loading: provider.isLoading,
                    onPressed: provider.isLoading ? null : _tryJoin,
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
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _openCreateEvent,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.joinAccent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Crea tu propio evento'),
            ),
          ),
        ],
      ),
    );
  }
}
