/// Validador de código de evento
///
/// Aplica reglas simples de formato.
class EventJoinValidator {
  static String? validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un código';
    }
    if (value.trim().length < 4) {
      return 'Código muy corto';
    }
    return null;
  }

  /// Nombre para invitados (no novios). Mínimo nombre y apellido en un solo campo.
  static String? validateGuestName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu nombre';
    }
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return 'Nombre y apellido, por favor';
    }
    if (value.trim().length < 4) {
      return 'Nombre muy corto';
    }
    return null;
  }

  static String normalizeCode(String value) {
    return value.trim().toUpperCase();
  }

  static bool isNoviosAdminCode(String code) {
    return normalizeCode(code).endsWith('-NOVIOS');
  }
}
