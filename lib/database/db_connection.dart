import 'package:postgres/postgres.dart';

class DbConnection {
  // Método para establecer la conexión
  static Future<Connection> connect() async {
    final connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        database: 'CIPE', 
        username: 'postgres', // Este suele ser el usuario por defecto
        password: '171104', // Sustituye esto por la contraseña de tu PostgreSQL
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.disable, // Como estamos en local, no necesitamos SSL
      ),
    );
    
    return connection;
  }
}