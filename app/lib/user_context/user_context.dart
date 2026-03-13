/// Contexto de usuario compartido
///
/// Punto único para información de sesión/usuario en ambos flujos.
/// No contiene lógica de negocio, solo estado compartido básico.
class UserContext {
  final String? userId;
  final String? eventId;

  UserContext({this.userId, this.eventId});
}
