import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'fotos_provider.dart';

/// Export básico de fotos (links)
class FotosExportScreen extends StatelessWidget {
  const FotosExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final provider = context.watch<FotosProvider>();
    final eventId = userContext.eventId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar links'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
        ),
      ),
      body: FutureBuilder(
        future: provider.fetchNow(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final photos = snapshot.data ?? [];
          if (photos.isEmpty) {
            return const Center(child: Text('Sin fotos para exportar'));
          }
          final links = photos.map((p) => p.url).toList();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: links.join('\n')),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Links copiados')),
                    );
                  },
                  child: const Text('Copiar todos'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: links.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return SelectableText(links[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
