import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/appear_animation.dart';
import '../user_context/user_context_provider.dart';
import 'fotos_image_tile.dart';
import 'fotos_photo_filter.dart';
import 'fotos_provider.dart';
import 'fotos_upload_pill.dart';

/// Feed de fotos persistentes con paginación
class FotosFeedScreen extends StatefulWidget {
  final VoidCallback onUploadTap;

  const FotosFeedScreen({super.key, required this.onUploadTap});

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

  static int _crossAxisCountForWidth(double width) {
    if (width > 980) return 3;
    if (width > 620) return 2;
    return 1;
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

    final raw = provider.photos;
    final displayPhotos = filterEventPhotosForDisplay(raw);
    final useGrid = provider.galleryGridMode;

    return RefreshIndicator(
      onRefresh: () =>
          provider.refresh(eventId, viewerId: viewerId, includePrivate: includePrivate),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x2,
              AppSpacing.x2,
              AppSpacing.x2,
              AppSpacing.x1,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Text(
                    'Revive el momento',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displaySmall.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mira y comparte los recuerdos del día',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Center(child: FotosUploadPill(onPressed: widget.onUploadTap)),
                ],
              ),
            ),
          ),
          if (provider.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (raw.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x2),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Aún no hay recuerdos',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sé el primero en subir uno.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Center(child: FotosUploadPill(onPressed: widget.onUploadTap)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (displayPhotos.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x2),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No hay fotos para mostrar aquí',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ocultamos enlaces que no parecen fotos del evento.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Center(child: FotosUploadPill(onPressed: widget.onUploadTap)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            if (useGrid)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  0,
                  AppSpacing.x2,
                  AppSpacing.x3,
                ),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.crossAxisExtent;
                    final crossAxisCount = _crossAxisCountForWidth(w);
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= displayPhotos.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final photo = displayPhotos[index];
                          return StaggerAppear(
                            index: index,
                            child: FotosImageTile(
                              photo: photo,
                              eventId: eventId,
                              index: index,
                              photos: displayPhotos,
                            ),
                          );
                        },
                        childCount: displayPhotos.length + (provider.hasMore ? 1 : 0),
                      ),
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  AppSpacing.x1,
                  AppSpacing.x2,
                  AppSpacing.x3,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= displayPhotos.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.x3),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final photo = displayPhotos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                        child: StaggerAppear(
                          index: index,
                          child: FotosImageTile(
                            photo: photo,
                            eventId: eventId,
                            layout: FotosGalleryTileLayout.feed,
                            index: index,
                            photos: displayPhotos,
                          ),
                        ),
                      );
                    },
                    childCount: displayPhotos.length + (provider.hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
