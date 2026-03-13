/// Modelo de lista de novios
class ListaNoviosModel {
  final String provider;
  final String code;
  final String? overrideUrl;

  const ListaNoviosModel({
    required this.provider,
    required this.code,
    this.overrideUrl,
  });
}
