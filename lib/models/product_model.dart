class Product {
  final int id;
  final String nombre;
  final String? codigoBarras;
  final double precioVenta;
  final int stockActual;
  final String? ubicacion;

  Product({
    required this.id,
    required this.nombre,
    this.codigoBarras,
    required this.precioVenta,
    required this.stockActual,
    this.ubicacion,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['idArticulo'] ?? json['id'] ?? 0) as int,
      nombre: (json['nombre'] ?? '') as String,
      codigoBarras: (json['codigoBarras'] ?? json['codigo_barras']) as String?,
      precioVenta: double.parse(
        (json['precioFinal'] ?? json['precioVenta'] ?? 0).toString(),
      ),
      stockActual: (json['stockActual'] ?? json['stock_actual'] ?? 0) as int,
      ubicacion: (json['ubicacion'] ?? json['descripcion']) as String?,
    );
  }
}
