/// Validador de búsquedas de mesas
class MesasValidator {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un nombre';
    }
    return null;
  }

  static String? validateTableNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa un número de mesa';
    }
    return null;
  }
}
