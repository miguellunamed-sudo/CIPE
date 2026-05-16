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
}