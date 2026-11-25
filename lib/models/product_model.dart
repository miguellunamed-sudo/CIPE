class Product {
  final int id;
  final String nombre;
  final String? codigoBarras;
  final double costoCompra;
  final double margenGanancia;
  final double precioVenta;
  final int stockActual;
  final int stockMinimo;
  final int? idProveedor;
  final int? idUbicacion;

  Product({
    required this.id,
    required this.nombre,
    this.codigoBarras,
    this.costoCompra = 0.0,
    this.margenGanancia = 0.0,
    required this.precioVenta,
    required this.stockActual,
    this.stockMinimo = 1,
    this.idProveedor,
    this.idUbicacion,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['idArticulo'] ?? json['id'] ?? 0) as int,
      nombre: (json['nombre'] ?? '') as String,
      codigoBarras: json['codigoBarras'] as String?,
      costoCompra: ((json['costoCompra'] ?? 0) as num).toDouble(),
      margenGanancia: ((json['margenGanancia'] ?? 0) as num).toDouble(),
      precioVenta: ((json['precioFinal'] ?? json['precioVenta'] ?? 0) as num).toDouble(),
      stockActual: (json['stockActual'] ?? 0) as int,
      stockMinimo: (json['stockMinimo'] ?? 1) as int,
      idProveedor: json['idProveedor'] as int?,
      idUbicacion: json['idUbicacion'] as int?,
    );
  }
}