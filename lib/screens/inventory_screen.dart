import 'package:flutter/material.dart';
import 'package:papeleria_app/models/product_model.dart';
import 'package:papeleria_app/models/user_session.dart';
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
        _filtrar(_searchCtrl.text);
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

  Future<void> _dialogoSurtir(Product p) async {
    final cantCtrl = TextEditingController(text: '1');
    final motivoCtrl = TextEditingController(text: 'Compra a proveedor');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Surtir: ${p.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock actual: ${p.stockActual} unidades',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cantCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Unidades que entran',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo / Nota',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final cant = int.tryParse(cantCtrl.text.trim()) ?? 0;
              if (cant <= 0) return;
              try {
                await ApiService.surtirStock(
                  idArticulo: p.id,
                  cantidad: cant,
                  motivo: motivoCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text(
              'Sumar al Stock',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _cargarInventario();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stock actualizado y registrado en Kardex'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _dialogoEditar(Product p) async {
    final nombreCtrl = TextEditingController(text: p.nombre);
    final codigoCtrl = TextEditingController(text: p.codigoBarras ?? '');
    final costoCtrl = TextEditingController(text: p.costoCompra.toString());
    final margenCtrl = TextEditingController(text: p.margenGanancia.toString());
    final minCtrl = TextEditingController(text: p.stockMinimo.toString());

    double calcularPrecio() {
      final c = double.tryParse(costoCtrl.text.trim()) ?? 0;
      final m = double.tryParse(margenCtrl.text.trim()) ?? 0;
      return double.parse((c * (1 + m / 100)).toStringAsFixed(2));
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Editar Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codigoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Código de barras',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costoCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setModalState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Costo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: margenCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setModalState(() {}),
                        decoration: const InputDecoration(
                          labelText: '% Margen',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Nuevo Precio Público: \$${calcularPrecio().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock mínimo de alerta',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty) return;
                try {
                  await ApiService.updateProduct(
                    idArticulo: p.id,
                    nombre: nombreCtrl.text.trim(),
                    codigoBarras: codigoCtrl.text.trim().isEmpty
                        ? null
                        : codigoCtrl.text.trim(),
                    costoCompra: double.tryParse(costoCtrl.text.trim()) ?? 0,
                    margenGanancia:
                        double.tryParse(margenCtrl.text.trim()) ?? 0,
                    precioFinal: calcularPrecio(),
                    stockMinimo: int.tryParse(minCtrl.text.trim()) ?? 1,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('$e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await _cargarInventario();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(Product p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Seguro que deseas eliminar "${p.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService.deleteProduct(p.id);
        await _cargarInventario();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ Producto eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
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
                        final esAdmin = UserSession.current?.isAdmin ?? false;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: bajoStock
                                ? Colors.redAccent
                                : Colors.blueAccent,
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
                            esAdmin
                                ? 'Código: ${p.codigoBarras ?? "Sin código"} | Costo: \$${p.costoCompra.toStringAsFixed(2)} | Mín: ${p.stockMinimo}'
                                : 'Código: ${p.codigoBarras ?? "Sin código"} | Stock mínimo: ${p.stockMinimo}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${p.precioVenta.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                tooltip: 'Surtir stock',
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                                onPressed: () => _dialogoSurtir(p),
                              ),
                              if (esAdmin) ...[
                                IconButton(
                                  tooltip: 'Editar producto',
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed: () => _dialogoEditar(p),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar producto',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _confirmarEliminar(p),
                                ),
                              ],
                            ],
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
