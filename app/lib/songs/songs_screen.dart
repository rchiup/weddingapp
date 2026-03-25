import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/custom_button.dart';
import '../user_context/user_context_provider.dart';
import 'songs_firestore_service.dart';
import 'songs_model.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final SongsFirestoreService _service = SongsFirestoreService();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _artist = TextEditingController();
  bool _loading = false;
  List<SongModel> _songs = [];

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final eventId = context.read<UserContextProvider>().eventId ?? '';
    if (eventId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final items = await _service.listSongs(eventId: eventId);
      if (!mounted) return;
      setState(() => _songs = items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final title = _title.text.trim();
    final artist = _artist.text.trim();
    if (title.isEmpty) return;

    final ctx = context.read<UserContextProvider>();
    final eventId = ctx.eventId ?? '';
    final userId = ctx.userId ?? '';
    final userName = ctx.userName ?? (ctx.isAdmin ? 'Novios' : 'Invitado');
    if (eventId.isEmpty || userId.isEmpty) return;

    setState(() => _loading = true);
    try {
      await _service.addSong(
        eventId: eventId,
        song: SongModel(
          id: '',
          title: title,
          artist: artist,
          userId: userId,
          userName: userName,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      _title.clear();
      _artist.clear();
      await _load();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_songs.isEmpty && !_loading) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '🎵 Canciones infaltables',
          style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
        ),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sugiere canciones para la fiesta',
              style: AppTextStyles.subtitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.x1_5),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Canción',
                hintText: 'Ej: September',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.x1),
            TextField(
              controller: _artist,
              decoration: const InputDecoration(
                labelText: 'Artista (opcional)',
                hintText: 'Ej: Earth, Wind & Fire',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
            ),
            const SizedBox(height: AppSpacing.x1_5),
            CustomButton(
              label: 'Agregar',
              icon: Icons.add_rounded,
              backgroundColor: AppColors.joinAccent,
              loading: _loading,
              onPressed: _loading ? null : _add,
            ),
            const SizedBox(height: AppSpacing.x2),
            Expanded(
              child: _loading && _songs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _songs.isEmpty
                      ? Center(
                          child: Text(
                            'Aún no hay sugerencias',
                            style: AppTextStyles.subtitle,
                          ),
                        )
                      : ListView.separated(
                          itemCount: _songs.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, i) {
                            final s = _songs[i];
                            final title = s.artist.trim().isEmpty
                                ? s.title
                                : '${s.title} — ${s.artist}';
                            final by = s.userName.trim().isEmpty ? 'Invitado' : s.userName;
                            return ListTile(
                              title: Text(title, style: AppTextStyles.title.copyWith(fontSize: 15)),
                              subtitle: Text('Por: $by', style: AppTextStyles.subtitle),
                              leading: const Icon(Icons.music_note_rounded),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

