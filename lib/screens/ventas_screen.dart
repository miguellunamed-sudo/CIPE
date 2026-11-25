import 'package:flutter/material.dart';
import 'package:papeleria_app/models/product_model.dart';
import 'package:papeleria_app/services/api_service.dart';

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
  final FocusNode _barcodeFocusNode = FocusNode();
  final TextEditingController _barcodeController = TextEditingController();

  final List<CartItem> _carrito = [];
  List<Product> _catalogoCompleto = [];
  List<Product> _sugerencias = [];
  double _totalVenta = 0.0;
  bool _buscando = false;
  bool _cobrando = false;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogo() async {
    try {
      final productos = await ApiService.getAllProducts();
      if (mounted) {
        setState(() {
          _catalogoCompleto = productos;
        });
      }
    } catch (_) {}
  }

  void _calcularTotal() {
    setState(() {
      _totalVenta = _carrito.fold(0, (sum, item) => sum + item.subtotal);
    });
  }

  void _agregarProductoAlTicket(Product producto) {
    setState(() {
      final index = _carrito.indexWhere(
        (item) => item.producto.id == producto.id,
      );
      if (index >= 0) {
        _carrito[index].cantidad++;
      } else {
        _carrito.add(CartItem(producto: producto));
      }
      _sugerencias = [];
      _calcularTotal();
    });
    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
  }

  void _onSearchChanged(String texto) {
    final q = texto.trim().toLowerCase();
    if (q.length < 2) {
      if (_sugerencias.isNotEmpty) {
        setState(() => _sugerencias = []);
      }
      return;
    }

    setState(() {
      _sugerencias = _catalogoCompleto.where((p) {
        final matchNombre = p.nombre.toLowerCase().contains(q);
        final matchCodigo = (p.codigoBarras ?? '').toLowerCase().contains(q);
        return matchNombre || matchCodigo;
      }).toList();
    });
  }

  void _onScan(String code) async {
    final limpio = code.trim();
    if (limpio.isEmpty || _buscando) return;

    final exacto = _catalogoCompleto.where(
      (p) =>
          (p.codigoBarras ?? '').toLowerCase() == limpio.toLowerCase() ||
          p.nombre.toLowerCase() == limpio.toLowerCase(),
    );
    if (exacto.isNotEmpty) {
      _agregarProductoAlTicket(exacto.first);
      return;
    }

    if (_sugerencias.length == 1) {
      _agregarProductoAlTicket(_sugerencias.first);
      return;
    }

    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
    await _buscarYAgregarProducto(limpio);
  }

  Future<void> _buscarYAgregarProducto(String codigo) async {
    setState(() => _buscando = true);
    try {
      final productoNuevo = await ApiService.getProductByCodigo(codigo);
      if (!mounted) return;

      if (productoNuevo == null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Producto "$codigo" no encontrado'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      if (!_catalogoCompleto.any((p) => p.id == productoNuevo.id)) {
        _catalogoCompleto.add(productoNuevo);
      }
      _agregarProductoAlTicket(productoNuevo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _buscando = false);
        _barcodeFocusNode.requestFocus();
      }
    }
  }

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

  Future<void> _finalizarVenta() async {
    if (_carrito.isEmpty || _cobrando) return;

    setState(() => _cobrando = true);

    try {
      final itemsPayload = _carrito
          .map((item) => {
                'idArticulo': item.producto.id,
                'cantidad': item.cantidad,
              })
          .toList();

      final ventaGuardada = await ApiService.registrarVenta(
        items: itemsPayload,
      );

      if (!mounted) return;

      setState(() {
        _carrito.clear();
        _sugerencias = [];
        _calcularTotal();
      });

      await _cargarCatalogo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Venta #${ventaGuardada['idVenta']} registrada con éxito',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cobrando = false);
        _barcodeFocusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Punto de Venta',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Recargar catálogo',
                        icon: const Icon(Icons.refresh),
                        onPressed: _cargarCatalogo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _barcodeController,
                    focusNode: _barcodeFocusNode,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onScan,
                    style: const TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      hintText: 'Escanear código de barras o buscar por nombre...',
                      prefixIcon: const Icon(Icons.qr_code_scanner, size: 28),
                      suffixIcon: _buscando
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            )
                          : (_barcodeController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _barcodeController.clear();
                                    setState(() => _sugerencias = []);
                                    _barcodeFocusNode.requestFocus();
                                  },
                                )
                              : null),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: _sugerencias.isNotEmpty
                        ? Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListView.separated(
                              itemCount: _sugerencias.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final prod = _sugerencias[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${prod.stockActual}'),
                                  ),
                                  title: Text(
                                    prod.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Código: ${prod.codigoBarras ?? "Sin código"}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '\$${prod.precioVenta.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.add_circle,
                                        color: Colors.blueAccent,
                                      ),
                                    ],
                                  ),
                                  onTap: () => _agregarProductoAlTicket(prod),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.storefront,
                                  size: 80,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _barcodeController.text.length >= 2
                                      ? 'Sin coincidencias para "${_barcodeController.text}"'
                                      : 'Escanea o escribe el nombre de un producto',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 450,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                left: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 2),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ticket de Venta',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      Icons.receipt_long,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
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
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 22),
                                          color: Colors.redAccent,
                                          onPressed: () => _restarCantidad(i),
                                        ),
                                        Text(
                                          '${item.cantidad}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 22),
                                          color: Colors.green,
                                          onPressed: () => _sumarCantidad(i),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.producto.nombre,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '\$${item.producto.precioVenta.toStringAsFixed(2)} c/u',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _eliminarDelCarrito(i),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(thickness: 2, height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL:',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${_totalVenta.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                  ),
                  onPressed: (_carrito.isEmpty || _cobrando) ? null : _finalizarVenta,
                  icon: _cobrando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.print, size: 30),
                  label: Text(
                    _cobrando ? 'PROCESANDO COBRO...' : 'COBRAR Y GUARDAR',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}