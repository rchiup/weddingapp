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

  static String normalizeCode(String value) {
    return value.trim().toUpperCase();
  }
}
