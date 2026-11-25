import 'package:flutter/material.dart';
import 'package:papeleria_app/models/product_model.dart';
import 'package:papeleria_app/services/api_service.dart';

class HistorialVentasScreen extends StatefulWidget {
  const HistorialVentasScreen({super.key});

  @override
  State<HistorialVentasScreen> createState() => _HistorialVentasScreenState();
}

class _HistorialVentasScreenState extends State<HistorialVentasScreen> {
  List<dynamic> _ventas = [];
  Map<int, String> _nombresProductos = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        ApiService.getVentas(),
        ApiService.getAllProducts(),
      ]);

      final ventasData = results[0];
      final productos = results[1] as List<Product>;

      // Ordenar de la venta más reciente a la más antigua
      ventasData.sort((a, b) {
        final idA = (a['idVenta'] ?? 0) as int;
        final idB = (b['idVenta'] ?? 0) as int;
        return idB.compareTo(idA);
      });

      if (!mounted) return;
      setState(() {
        _ventas = ventasData;
        _nombresProductos = {
          for (final p in productos) p.id: p.nombre,
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar historial: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double get _totalAcumulado {
    return _ventas.fold(0.0, (sum, v) {
      final total = ((v['total'] ?? 0) as num).toDouble();
      return sum + total;
    });
  }

  String _formatearFecha(String? raw) {
    if (raw == null || raw.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(raw);
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final hora = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dia/$mes/${dt.year}  $hora:$min';
    } catch (_) {
      return raw;
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
                  'Historial de Ventas',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                IconButton.filledTonal(
                  onPressed: _cargarDatos,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar ventas',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ventas Registradas',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            '${_ventas.length} tickets',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Ingresado',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            '\$${_totalAcumulado.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _ventas.isEmpty
                      ? const Center(child: Text('Aún no hay ventas registradas'))
                      : ListView.builder(
                          itemCount: _ventas.length,
                          itemBuilder: (context, index) {
                            final venta = _ventas[index];
                            final idVenta = venta['idVenta'] ?? 0;
                            final total =
                                ((venta['total'] ?? 0) as num).toDouble();
                            final fecha =
                                _formatearFecha(venta['fecha'] as String?);
                            final detalles =
                                (venta['detalles'] as List<dynamic>?) ?? [];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(Icons.receipt, color: Colors.white),
                                ),
                                title: Text(
                                  'Venta #$idVenta',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(fecha),
                                trailing: Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                children: detalles.map((det) {
                                  final idArt = (det['idArticulo'] ?? 0) as int;
                                  final nombreArt = _nombresProductos[idArt] ??
                                      'Artículo #$idArt';
                                  final cant = det['cantidad'] ?? 0;
                                  final precio =
                                      ((det['precioUnitario'] ?? 0) as num)
                                          .toDouble();
                                  final sub =
                                      ((det['subtotal'] ?? 0) as num).toDouble();

                                  return ListTile(
                                    dense: true,
                                    title: Text('$cant x $nombreArt'),
                                    subtitle: Text(
                                        '\$${precio.toStringAsFixed(2)} c/u'),
                                    trailing: Text(
                                      '\$${sub.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  );
                                }).toList(),
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