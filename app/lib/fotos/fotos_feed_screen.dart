import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../user_context/user_context_provider.dart';
import 'fotos_image_tile.dart';
import 'fotos_provider.dart';

/// Feed de fotos persistentes con paginación
class FotosFeedScreen extends StatefulWidget {
  const FotosFeedScreen({super.key});

  @override
  State<FotosFeedScreen> createState() => _FotosFeedScreenState();
}

class _FotosFeedScreenState extends State<FotosFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<FotosProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userContext = context.watch<UserContextProvider>();
    final eventId = userContext.eventId ?? '';
    final viewerId = userContext.userId ?? '';
    final includePrivate = userContext.isAdmin;
    final provider = context.watch<FotosProvider>();

    if (!_didLoad) {
      _didLoad = true;
      provider.loadInitial(eventId, viewerId: viewerId, includePrivate: includePrivate);
    }

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.photos.isEmpty) {
      return const Center(child: Text('Aún no hay fotos'));
    }

    return RefreshIndicator(
      onRefresh: () =>
          provider.refresh(eventId, viewerId: viewerId, includePrivate: includePrivate),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: provider.photos.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= provider.photos.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final photo = provider.photos[index];
            return FotosImageTile(photo: photo, eventId: eventId);
          },
        ),
      ),
    );
  }
}
