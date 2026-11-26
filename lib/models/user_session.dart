class UserSession {
  final int idUsuario;
  final String nombreCompleto;
  final String username;
  final String rol; // 'Administrador' o 'Empleado'

  UserSession({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.username,
    required this.rol,
  });

  bool get isAdmin => rol.toLowerCase() == 'administrador';

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final rolObj = json['rol'] as Map<String, dynamic>?;
    return UserSession(
      idUsuario: (json['idUsuario'] ?? 0) as int,
      nombreCompleto: (json['nombreCompleto'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      rol: (rolObj?['nombre'] ?? 'Empleado') as String,
    );
  }

  // Sesión global actual
  static UserSession? current;
}