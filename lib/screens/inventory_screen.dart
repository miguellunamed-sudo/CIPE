import 'package:flutter/material.dart';
import 'package:papeleria_app/models/product_model.dart';
import 'package:papeleria_app/services/api_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  List<Product> _todos = [];
  List<Product> _filtrados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarInventario();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarInventario() async {
    setState(() => _cargando = true);
    try {
      final lista = await ApiService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _todos = lista;
        _filtrados = lista;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar inventario: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _filtrar(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtrados = _todos;
      } else {
        _filtrados = _todos.where((p) {
          return p.nombre.toLowerCase().contains(query) ||
              (p.codigoBarras ?? '').toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
                IconButton.filledTonal(
                  onPressed: _cargarInventario,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar inventario',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código de barras...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _filtrados.isEmpty
                      ? const Center(child: Text('No hay productos registrados'))
                      : ListView.separated(
                          itemCount: _filtrados.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = _filtrados[index];
                            final bajoStock = p.stockActual <= p.stockMinimo;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    bajoStock ? Colors.redAccent : Colors.blueAccent,
                                child: Text(
                                  '${p.stockActual}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                p.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Código: ${p.codigoBarras ?? "Sin código"} | Costo: \$${p.costoCompra.toStringAsFixed(2)}',
                              ),
                              trailing: Text(
                                '\$${p.precioVenta.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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