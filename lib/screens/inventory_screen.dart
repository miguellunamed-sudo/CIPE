import 'package:flutter/material.dart';
import '../database/db_connection.dart';
import '../models/product_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<Product>> _futureProducts;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureProducts = fetchProducts('');
  }

  void _buscar() {
    setState(() {
      _searchQuery = _searchController.text;
      _futureProducts = fetchProducts(_searchQuery);
    });
  }

  Future<List<Product>> fetchProducts(String query) async {
    final conn = await DbConnection.connect();
    
    String sql = '''
      SELECT p.id_producto, p.nombre, p.codigo_barras, p.precio_venta, p.stock_actual, u.descripcion 
      FROM productos p 
      LEFT JOIN ubicaciones u ON p.id_ubicacion = u.id_ubicacion
    ''';
    
    if (query.isNotEmpty) {
      sql += " WHERE p.nombre ILIKE '%$query%' OR p.codigo_barras ILIKE '%$query%'";
    }
    
    sql += " ORDER BY p.nombre ASC";

    final results = await conn.execute(sql);
    await conn.close();

    return results.map((row) => Product(
      id: row[0] as int,
      nombre: row[1] as String,
      codigoBarras: row[2] as String?,
      precioVenta: double.parse(row[3].toString()),
      stockActual: row[4] as int,
      ubicacion: row[5] as String?,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título integrado al cuerpo
            const Text(
              'Inventario Total',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // --- BARRA DE BÚSQUEDA ---
            TextField(
              controller: _searchController,
              onChanged: (value) => _buscar(),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código de barras...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _buscar();
                      },
                    )
                  : null,
                filled: true,
                // fillColor quitado para que respete el modo oscuro del Theme
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // --- TABLA DE RESULTADOS ---
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _futureProducts, 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No se encontraron productos.'));
                  }

                  final products = snapshot.data!;

                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            // Eliminamos el headingRowColor fijo para que se adapte al tema oscuro
                            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            dataRowMaxHeight: 70, // Filas más altas para mejor lectura
                            columns: const [
                              DataColumn(label: Text('Nombre')),
                              DataColumn(label: Text('Código')),
                              DataColumn(label: Text('Precio')),
                              DataColumn(label: Text('Stock')),
                              DataColumn(label: Text('Ubicación')),
                            ],
                            rows: products.map((p) => DataRow(cells: [
                              DataCell(Text(p.nombre)),
                              DataCell(Text(p.codigoBarras ?? 'N/A')),
                              DataCell(Text('\$${p.precioVenta.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(
                                Text(p.stockActual.toString(), 
                                  style: TextStyle(
                                    color: p.stockActual <= 0 ? Colors.redAccent : null,
                                    fontWeight: p.stockActual <= 0 ? FontWeight.bold : FontWeight.normal
                                  )
                                )
                              ),
                              DataCell(Text(p.ubicacion ?? 'Sin asignar')),
                            ])).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}