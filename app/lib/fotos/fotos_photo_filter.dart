import 'foto_model.dart';

/// Heurística local (sin backend) para ocultar contenido que no parece foto de evento.
bool isLikelyRealEventPhotoUrl(String url) {
  final u = url.trim().toLowerCase();
  if (u.isEmpty) return false;

  const blockedFragments = [
    'quote',
    'quotes',
    'motivational',
    'inspirational',
    'meme',
    'vector',
    'illustration',
    'clipart',
    'clip-art',
    'infographic',
    'wallpaper',
    'stock-vector',
    'drawing',
    'sketch',
    'cartoon',
    'bar-chart',
    'poster-template',
    'text-overlay',
    'typography',
    'just-make-it',
    'make-it-exist',
    'maybe-you-dont',
    'sticker-pack',
    'emoji-pack',
    'giphy.com',
    'tenor.com',
    'pngtree',
    'freepik',
    'shutterstock',
    'dreamstime',
    'istockphoto',
    'adobe-stock',
    'canva.com',
    'template-design',
    'word-art',
    'banner-template',
  ];

  for (final b in blockedFragments) {
    if (u.contains(b)) return false;
  }

  return true;
}

List<FotoModel> filterEventPhotosForDisplay(List<FotoModel> photos) {
  return photos.where((p) => isLikelyRealEventPhotoUrl(p.url)).toList();
}
