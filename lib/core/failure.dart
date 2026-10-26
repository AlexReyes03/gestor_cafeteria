//1. Conexion
//2. Error servidor
//3. Respuestas

// Clase sellada para gestionar los estados de fallo

// Clase principal -> Sellada -> Va a saber quienes son sus hijos
sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;
}

// 1. Sin Conexion, DNS, timeouts
final class NetworkFailure extends Failure {
  const NetworkFailure() : super("No se pudo conectar al servidor");
}

// 2. 5xx Servidor no responde
final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode) : super("Error del Servidor");
  final int statusCode;
}

// Token No valido
final class InvalidTokenFailure extends Failure {
  const InvalidTokenFailure() : super("Token no valido");
}

// 3. 404
final class NotFoundFailure extends Failure {
  const NotFoundFailure() : super("Recurso no encontrado");
}

// 4. 409
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

// 5. 422
final class UnprocessableEntityFailure extends Failure {
  const UnprocessableEntityFailure(this.fields) : super("Error de Validación");
  final Map<String, String> fields;
}

// 6. Error desconocido
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(this.statusCode, super.message);
  final int statusCode;
}