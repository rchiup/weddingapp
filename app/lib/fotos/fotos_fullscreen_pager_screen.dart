import 'package:flutter/material.dart';

import 'foto_model.dart';
import 'fotos_fullscreen_screen.dart';

/// Fullscreen tipo Instagram: al abrir una foto puedes deslizar verticalmente
/// para ver la siguiente/anterior sin volver a la grilla.
class FotosFullscreenPagerScreen extends StatelessWidget {
  final List<FotoModel> photos;
  final int initialIndex;
  final String eventId;

  const FotosFullscreenPagerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    final safeIndex = initialIndex < 0
        ? 0
        : (initialIndex >= photos.length ? photos.length - 1 : initialIndex);

    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: PageController(initialPage: safeIndex),
      itemCount: photos.length,
      itemBuilder: (context, i) {
        return FotosFullscreenScreen(
          key: ValueKey('photo_${photos[i].id}_$i'),
          photo: photos[i],
          eventId: eventId,
        );
      },
    );
  }
}

