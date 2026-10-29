import 'package:flutter/material.dart';
import '../database/db_connection.dart';
import '../models/product_model.dart'; 

// Clase auxiliar para manejar las cantidades y subtotales en el ticket
class CartItem {
  final Product producto;
  int cantidad;

  CartItem({required this.producto, this.cantidad = 1});

  double get subtotal => producto.precioVenta * cantidad;
}

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  // Controladores para el lector de código de barras
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();

  // Estado del carrito y total
  final List<CartItem> _carrito = [];
  double _totalVenta = 0.0;

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _calcularTotal() {
    setState(() {
      _totalVenta = _carrito.fold(0, (sum, item) => sum + item.subtotal);
    });
  }

  // --- LÓGICA DEL ESCÁNER ---

  void _onScan(String code) async {
    if (code.trim().isEmpty) return;
    
    await _buscarYAgregarProducto(code.trim());
    
    _barcodeController.clear();
    _barcodeFocusNode.requestFocus(); // Mantiene el cursor listo para el siguiente producto
  }

  Future<void> _buscarYAgregarProducto(String codigo) async {
    try {
      final conn = await DbConnection.connect();
      final results = await conn.execute(
        'SELECT id_producto, nombre, codigo_barras, precio_venta, stock_actual FROM productos WHERE codigo_barras = \$1 LIMIT 1',
        parameters: [codigo]
      );
      await conn.close();

      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Producto no encontrado'), backgroundColor: Colors.redAccent),
          );
        }
        return;
      }

      final row = results[0];
      final productoNuevo = Product(
        id: row[0] as int,
        nombre: row[1] as String,
        codigoBarras: row[2] as String?,
        precioVenta: double.parse(row[3].toString()),
        stockActual: row[4] as int,
      );

      setState(() {
        // Verifica si el producto ya está en el ticket para sumar 1, o lo agrega como nuevo
        final index = _carrito.indexWhere((item) => item.producto.id == productoNuevo.id);
        if (index >= 0) {
          _carrito[index].cantidad++;
        } else {
          _carrito.add(CartItem(producto: productoNuevo));
        }
        _calcularTotal();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // --- LÓGICA DEL CARRITO ---

  void _sumarCantidad(int index) {
    setState(() {
      _carrito[index].cantidad++;
      _calcularTotal();
    });
  }

  void _restarCantidad(int index) {
    setState(() {
      if (_carrito[index].cantidad > 1) {
        _carrito[index].cantidad--;
      } else {
        _carrito.removeAt(index);
      }
      _calcularTotal();
    });
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      _carrito.removeAt(index);
      _calcularTotal();
    });
  }

  void _finalizarVenta() {
    // Aquí irá tu lógica de inserción INSERT INTO ventas...
    setState(() {
      _carrito.clear();
      _calcularTotal();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Venta registrada con éxito'), backgroundColor: Colors.green),
    );
    _barcodeFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ==========================================
          // PARTE IZQUIERDA: Búsqueda y escáner
          // ==========================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Punto de Venta',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _barcodeController,
                    focusNode: _barcodeFocusNode,
                    autofocus: true, 
                    onSubmitted: _onScan, 
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      hintText: 'Escanear código de barras o buscar...',
                      prefixIcon: const Icon(Icons.qr_code_scanner, size: 28),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                          const SizedBox(height: 20),
                          Text('Escanea un producto para agregarlo al ticket', 
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // PARTE DERECHA: Ticket interactivo
          // ==========================================
          Container(
            width: 450, 
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, 
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
                  child: _carrito.isEmpty
                    ? const Center(child: Text('El ticket está vacío'))
                    : ListView.builder(
                        itemCount: _carrito.length,
                        itemBuilder: (context, i) {
                          final item = _carrito[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Controles de cantidad
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
                                // Subtotal y eliminar
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
                // Contenedor del Total
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
                      Text('\$${_totalVenta.toStringAsFixed(2)}', 
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
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
      ),
    );
  }
}