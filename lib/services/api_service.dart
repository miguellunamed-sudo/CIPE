import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:papeleria_app/models/product_model.dart';

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

  // 3. Crear un nuevo artículo en Neon vía Spring Boot
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
}
