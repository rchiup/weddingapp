import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../user_context/user_context_provider.dart';
import 'guest_list_template.dart';
import 'guest_list_template_export.dart';
import 'mesas_guest_upload_service.dart';

/// Subida de invitados (.xlsx) para novios. Mismo flujo en panel de novios y en Invitados → Organizar.
class GuestListUploadCard extends StatefulWidget {
  const GuestListUploadCard({
    super.key,
    this.afterUpload,
    this.compactDescription = false,
    this.showTitle = true,
  });

  /// Tras importar bien (p. ej. recargar lista en la pestaña Organizar).
  final Future<void> Function(String eventId)? afterUpload;

  /// Menos texto de formato (cuando ya está explicado arriba).
  final bool compactDescription;

  /// En Invitados → Organizar el título sobra; en panel de novios conviene.
  final bool showTitle;

  @override
  State<GuestListUploadCard> createState() => _GuestListUploadCardState();
}

class _GuestListUploadCardState extends State<GuestListUploadCard> {
  final MesasGuestUploadService _uploadService = MesasGuestUploadService();
  bool _uploading = false;

  String _adminCode(UserContextProvider ctx) {
    final id = ctx.eventId ?? '';
    return '${id.toUpperCase()}-NOVIOS';
  }

  Future<void> _pickAndUpload(BuildContext context, String eventId) async {
    final userContext = context.read<UserContextProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reemplazar invitados'),
        content: const Text(
          'Se borrará la lista actual de invitados de este evento y se cargará el Excel. ¿Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, subir')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    if (!context.mounted) return;
    if (pick == null || pick.files.isEmpty) return;
    final bytes = pick.files.first.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el archivo')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final res = await _uploadService.uploadExcel(
        eventId: eventId,
        adminCode: _adminCode(userContext),
        bytes: bytes,
        filename: pick.files.first.name,
      );
      if (!context.mounted) return;
      await widget.afterUpload?.call(eventId);
      if (!context.mounted) return;
      var msg = 'Importados ${res.imported} invitados';
      if (res.warnings.isNotEmpty) {
        msg += '\n\nAvisos:\n${res.warnings.take(5).join('\n')}';
        if (res.warnings.length > 5) msg += '\n…';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    try {
      await downloadOrShareGuestListTemplate(buildGuestListTemplateExcel);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar la plantilla: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<UserContextProvider>();
    final eventId = ctx.eventId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Row(
            children: [
              const Text('👥 ', style: TextStyle(fontSize: 18)),
              Text('Invitados y mesas', style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: AppSpacing.x1),
        ],
        if (!widget.compactDescription) ...[
          Text(
            'Solo archivo Excel .xlsx (no CSV ni otras apps). '
            'Columnas obligatorias: name y last_name (también acepta nombre y apellido). '
            'Opcionales: email, phone, table/mesa. Si no hay columna de mesa, se crean mesas de 8 personas.',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.x2),
        ] else
          Text(
            'Solo .xlsx — columnas name, last_name (o nombre, apellido).',
            style: AppTextStyles.subtitle,
          ),
        if (widget.compactDescription) const SizedBox(height: AppSpacing.x1_5),
        OutlinedButton.icon(
          onPressed: () => _downloadTemplate(context),
          icon: const Icon(Icons.download_outlined, size: 20),
          label: const Text('Descargar plantilla Excel'),
        ),
        const SizedBox(height: AppSpacing.x1_5),
        CustomButton(
          label: _uploading ? 'Subiendo…' : 'Subir lista de invitados (.xlsx)',
          onPressed: _uploading || eventId.isEmpty ? null : () => _pickAndUpload(context, eventId),
        ),
      ],
    );
  }
}
