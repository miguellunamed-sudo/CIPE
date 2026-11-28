import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:papeleria_app/models/product_model.dart';
import 'package:papeleria_app/models/user_session.dart';

class ApiService {
  static const String baseUrl = 'https://cipe-backend.onrender.com';

  // 1. Buscar producto por código de barras
  static Future<Product?> getProductByCodigo(String codigo) async {
    final uri = Uri.parse('$baseUrl/api/articulos/codigo/$codigo');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Product.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // 2. Listar todos los productos
  static Future<List<Product>> getAllProducts() async {
    final uri = Uri.parse('$baseUrl/api/articulos');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // 3. Crear un nuevo artículo
  static Future<Product> createProduct({
    required String nombre,
    String? codigoBarras,
    double costoCompra = 0.0,
    double margenGanancia = 0.0,
    required double precioFinal,
    required int stockActual,
    int stockMinimo = 1,
    int? idProveedor,
    int? idUbicacion,
  }) async {
    final uri = Uri.parse('$baseUrl/api/articulos');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'codigoBarras': codigoBarras,
        'costoCompra': costoCompra,
        'margenGanancia': margenGanancia,
        'precioFinal': precioFinal,
        'stockActual': stockActual,
        'stockMinimo': stockMinimo,
        'idProveedor': idProveedor,
        'idUbicacion': idUbicacion,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Product.fromJson(data);
    } else {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // 4. Registrar venta, descontar stock y guardar Kardex
  static Future<dynamic> registrarVenta({
    int? idUsuario,
    required List<dynamic> items,
  }) async {
    final uri = Uri.parse('$baseUrl/api/ventas');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idUsuario': idUsuario, 'items': items}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Error al cobrar (${response.statusCode}): ${response.body}',
      );
    }
  }

  // 5. Listar y crear Proveedores
  static Future<List<dynamic>> getProveedores() async {
    final uri = Uri.parse('$baseUrl/api/proveedores');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error al cargar proveedores (${response.statusCode})');
    }
  }

  static Future<dynamic> createProveedor({
    required String nombre,
    String? telefono,
  }) async {
    final uri = Uri.parse('$baseUrl/api/proveedores');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'telefono': telefono}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear proveedor (${response.statusCode})');
    }
  }

  // 6. Listar y crear Ubicaciones
  static Future<List<dynamic>> getUbicaciones() async {
    final uri = Uri.parse('$baseUrl/api/ubicaciones');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error al cargar ubicaciones (${response.statusCode})');
    }
  }

  static Future<dynamic> createUbicacion({required String descripcion}) async {
    final uri = Uri.parse('$baseUrl/api/ubicaciones');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'descripcion': descripcion}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear ubicación (${response.statusCode})');
    }
  }

  // 7. Listar historial de ventas
  static Future<List<dynamic>> getVentas() async {
    final uri = Uri.parse('$baseUrl/api/ventas');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error al cargar ventas (${response.statusCode})');
    }
  }

  // 8. Surtir stock a un artículo existente (suma stock + registra ENTRADA en Kardex)
  static Future<Product> surtirStock({
    required int idArticulo,
    required int cantidad,
    String motivo = 'Reabastecimiento de mercancía',
  }) async {
    final uri = Uri.parse('$baseUrl/api/articulos/$idArticulo/surtir');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cantidad': cantidad, 'motivo': motivo}),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
        'Error al surtir (${response.statusCode}): ${response.body}',
      );
    }
  }

  // 9. Editar artículo existente
  static Future<Product> updateProduct({
    required int idArticulo,
    required String nombre,
    String? codigoBarras,
    required double costoCompra,
    required double margenGanancia,
    required double precioFinal,
    required int stockMinimo,
  }) async {
    final uri = Uri.parse('$baseUrl/api/articulos/$idArticulo');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'codigoBarras': codigoBarras,
        'costoCompra': costoCompra,
        'margenGanancia': margenGanancia,
        'precioFinal': precioFinal,
        'stockMinimo': stockMinimo,
      }),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
        'Error al actualizar (${response.statusCode}): ${response.body}',
      );
    }
  }

  // 10. Eliminar artículo
  static Future<void> deleteProduct(int idArticulo) async {
    final uri = Uri.parse('$baseUrl/api/articulos/$idArticulo');
    final response = await http.delete(uri);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : 'Error al eliminar (${response.statusCode})',
      );
    }
  }

  // 11. Iniciar sesión
  static Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final session = UserSession.fromJson(data);
      UserSession.current = session;
      return session;
    } else {
      throw Exception(
        response.body.isNotEmpty ? response.body : 'Credenciales inválidas',
      );
    }
  }

  // 12. Consultar turno de caja activo
  static Future<dynamic> getCorteActivo() async {
    final uri = Uri.parse('$baseUrl/api/cortes/activo');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al consultar caja (${response.statusCode})');
    }
  }

  // 13. Abrir caja
  static Future<dynamic> abrirCaja({required double montoInicial}) async {
    final uri = Uri.parse('$baseUrl/api/cortes/abrir');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'montoInicial': montoInicial,
        'idUsuario': UserSession.current?.idUsuario,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : 'Error al abrir caja (${response.statusCode})',
      );
    }
  }

  // 14. Cerrar caja
  static Future<dynamic> cerrarCaja({
    required int idCorte,
    required double montoFinalReal,
  }) async {
    final uri = Uri.parse('$baseUrl/api/cortes/$idCorte/cerrar');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'montoFinalReal': montoFinalReal}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : 'Error al cerrar caja (${response.statusCode})',
      );
    }
  }

  // 15. Listar historial de cortes
  static Future<List<dynamic>> getHistorialCortes() async {
    final uri = Uri.parse('$baseUrl/api/cortes');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception(
        'Error al cargar historial de cortes (${response.statusCode})',
      );
    }
  }

  // 16. Listar movimientos de inventario (Kardex)
  static Future<dynamic> getMovimientos() async {
    final uri = Uri.parse('$baseUrl/api/movimientos');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error al cargar Kardex (${response.statusCode})');
    }
  }

  // 17. Listar todos los usuarios
  static Future<List<dynamic>> getUsuarios() async {
    final uri = Uri.parse('$baseUrl/api/auth/usuarios');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error al cargar usuarios (${response.statusCode})');
    }
  }

  // 18. Crear nuevo usuario (Administrador o Empleado)
  static Future<dynamic> createUsuario({
    required String nombreCompleto,
    required String username,
    required String password,
    required String rol,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/usuarios');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombreCompleto': nombreCompleto,
        'username': username,
        'password': password,
        'rol': rol,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : 'Error al crear usuario (${response.statusCode})',
      );
    }
  }

  // 19. Restablecer contraseña de un usuario
  static Future<void> resetUsuarioPassword({
    required int idUsuario,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/usuarios/$idUsuario/password');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': newPassword}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        response.body.isNotEmpty
            ? response.body
            : 'Error al cambiar contraseña (${response.statusCode})',
      );
    }
  }

  // 20. Activar / desactivar usuario
  static Future<void> toggleUsuarioEstado({
    required int idUsuario,
    required bool activo,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/usuarios/$idUsuario/estado');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'activo': activo}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar estado (${response.statusCode})');
    }
  }
}
