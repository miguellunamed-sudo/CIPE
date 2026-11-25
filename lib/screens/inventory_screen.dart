import 'package:flutter/material.dart';
import 'package:papeleria_app/models/product_model.dart';
import 'package:papeleria_app/services/api_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Product>> fetchProducts(String query) async {
    final allProducts = await ApiService.getAllProducts();

    if (query.trim().isEmpty) {
      allProducts.sort((a, b) => a.nombre.compareTo(b.nombre));
      return allProducts;
    }

    final q = query.trim().toLowerCase();
    final filtered = allProducts.where((p) {
      final matchNombre = p.nombre.toLowerCase().contains(q);
      final matchCodigo = (p.codigoBarras ?? '').toLowerCase().contains(q);
      return matchNombre || matchCodigo;
    }).toList();

    filtered.sort((a, b) => a.nombre.compareTo(b.nombre));
    return filtered;
  }

  void _refreshList([String? query]) {
    setState(() {
      _productsFuture = fetchProducts(query ?? _searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Inventario Total',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  tooltip: 'Actualizar inventario',
                  icon: const Icon(Icons.refresh, size: 28),
                  onPressed: () => _refreshList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: (value) => _refreshList(value),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código de barras...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar inventario: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron productos.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${product.stockActual}'),
                        ),
                        title: Text(
                          product.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Código: ${product.codigoBarras ?? "Sin código"}',
                        ),
                        trailing: Text(
                          '\$${product.precioVenta.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
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