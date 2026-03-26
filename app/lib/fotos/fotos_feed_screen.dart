import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/appear_animation.dart';
import '../ui/custom_button.dart';
import '../user_context/user_context_provider.dart';
import 'fotos_image_tile.dart';
import 'fotos_provider.dart';

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

    Widget uploadPill() {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: CustomButton(
          label: '+ Subir recuerdo',
          icon: Icons.photo_camera_outlined,
          backgroundColor: AppColors.galleryUpload,
          usePillShape: true,
          onPressed: widget.onUploadTap,
        ),
      );
    }

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
                  const SizedBox(height: 4),
                  Text(
                    'Revive el momento',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displaySmall.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mira y comparte los recuerdos del dia',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Center(child: uploadPill()),
                ],
              ),
            ),
          ),
          if (provider.isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.photos.isEmpty)
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
                          'Aun no hay recuerdos',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Se el primero en subir uno.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Center(child: uploadPill()),
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
                  final crossAxisCount = w >= 560 ? 3 : 2;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= provider.photos.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final photo = provider.photos[index];
                        return StaggerAppear(
                          index: index,
                          child: FotosImageTile(
                            photo: photo,
                            eventId: eventId,
                            index: index,
                            photos: provider.photos,
                          ),
                        );
                      },
                      childCount: provider.photos.length + (provider.hasMore ? 1 : 0),
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
                    if (index >= provider.photos.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.x3),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final photo = provider.photos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                      child: StaggerAppear(
                        index: index,
                        child: FotosImageTile(
                          photo: photo,
                          eventId: eventId,
                          layout: FotosGalleryTileLayout.feed,
                          index: index,
                          photos: provider.photos,
                        ),
                      ),
                    );
                  },
                  childCount: provider.photos.length + (provider.hasMore ? 1 : 0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
