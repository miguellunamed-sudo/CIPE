import 'package:flutter/material.dart';
import '../database/db_connection.dart';
import '../models/product_model.dart';

class ItemCarrito {
  final Product producto;
  int cantidad;

  ItemCarrito({required this.producto, this.cantidad = 1});

  double get subtotal => producto.precioVenta * cantidad;
}

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final List<ItemCarrito> _carrito = [];
  final _searchCtrl = TextEditingController();
  List<Product> _resultadosBusqueda = [];

  void _buscarProducto(String query) async {
    if (query.isEmpty) {
      setState(() => _resultadosBusqueda = []);
      return;
    }

    final conn = await DbConnection.connect();
    final results = await conn.execute(
      "SELECT id_producto, nombre, codigo_barras, precio_venta, stock_actual FROM productos "
      "WHERE nombre ILIKE '%$query%' OR codigo_barras = '$query' LIMIT 5"
    );
    await conn.close();

    setState(() {
      _resultadosBusqueda = results.map((row) => Product(
        id: row[0] as int,
        nombre: row[1] as String,
        codigoBarras: row[2] as String?,
        precioVenta: double.parse(row[3].toString()),
        stockActual: row[4] as int,
      )).toList();
    });
  }

  void _agregarAlCarrito(Product p) {
    setState(() {
      final index = _carrito.indexWhere((item) => item.producto.id == p.id);
      if (index != -1) {
        _carrito[index].cantidad++;
      } else {
        _carrito.add(ItemCarrito(producto: p));
      }
      _searchCtrl.clear();
      _resultadosBusqueda = [];
    });
  }

  // --- NUEVAS FUNCIONES PARA CONTROLAR LA CANTIDAD ---
  void _sumarCantidad(int index) {
    setState(() {
      _carrito[index].cantidad++;
    });
  }

  void _restarCantidad(int index) {
    setState(() {
      if (_carrito[index].cantidad > 1) {
        _carrito[index].cantidad--;
      } else {
        // Si llega a 0, lo quitamos del carrito
        _carrito.removeAt(index);
      }
    });
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
    });
  }
  // ---------------------------------------------------

  double get _totalVenta => _carrito.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _finalizarVenta() async {
    if (_carrito.isEmpty) return;

    try {
      final conn = await DbConnection.connect();
      
      final vResult = await conn.execute(
        'INSERT INTO ventas (total) VALUES (\$1) RETURNING id_venta',
        parameters: [_totalVenta],
      );
      final idVenta = vResult[0][0] as int;

      for (var item in _carrito) {
        await conn.execute(
          'INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario) VALUES (\$1, \$2, \$3, \$4)',
          parameters: [idVenta, item.producto.id, item.cantidad, item.producto.precioVenta],
        );

        await conn.execute(
          'UPDATE productos SET stock_actual = stock_actual - \$1 WHERE id_producto = \$2',
          parameters: [item.cantidad, item.producto.id],
        );
      }

      await conn.close();
      
      setState(() => _carrito.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Venta guardada en la base de datos'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error en venta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // PARTE IZQUIERDA: Buscador
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Escanear código o buscar nombre...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onChanged: _buscarProducto,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _resultadosBusqueda.length,
                    itemBuilder: (context, i) {
                      final p = _resultadosBusqueda[i];
                      return Card(
                        child: ListTile(
                          title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Stock: ${p.stockActual} | \$${p.precioVenta}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.blueAccent),
                            onPressed: () => _agregarAlCarrito(p),
                          ),
                          onTap: () => _agregarAlCarrito(p),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const VerticalDivider(width: 1),

        // PARTE DERECHA: Ticket interactivo
        Container(
          width: 450, // Ancho fijo en lugar de Expanded para simular un panel lateral real
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, // Se adapta al modo Lite y Ultra Dark
            border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 2)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ticket de Venta', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary, size: 30),
                ],
              ),
              const Divider(thickness: 2, height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: _carrito.length,
                  itemBuilder: (context, i) {
                    final item = _carrito[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Controles de cantidad agrupados
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 22),
                                  color: Colors.redAccent,
                                  onPressed: () => _restarCantidad(i),
                                ),
                                Text('${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 22),
                                  color: Colors.green,
                                  onPressed: () => _sumarCantidad(i),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Detalles del producto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.producto.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text('\$${item.producto.precioVenta.toStringAsFixed(2)} c/u', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          ),
                          // Subtotal y botón de eliminar
                          Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _eliminarDelCarrito(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(thickness: 2, height: 30),
              // Contenedor de TOTAL dinámico (sin color blanco fijo)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('\$${_totalVenta.toStringAsFixed(2)}', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                ),
                onPressed: _carrito.isEmpty ? null : _finalizarVenta,
                icon: const Icon(Icons.print, size: 30),
                label: const Text('COBRAR Y GUARDAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}