import 'package:flutter/material.dart';
import 'package:papeleria_app/models/product_model.dart';
import 'package:papeleria_app/services/api_service.dart';

class KardexScreen extends StatefulWidget {
  const KardexScreen({super.key});

  @override
  State<KardexScreen> createState() => _KardexScreenState();
}

class _KardexScreenState extends State<KardexScreen> {
  List<dynamic> _movimientos = [];
  Map<int, String> _nombresArticulos = {};
  String _filtroTipo = 'TODOS'; // TODOS, ENTRADA, SALIDA
  String _busqueda = '';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarKardex();
  }

  Future<void> _cargarKardex() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        ApiService.getMovimientos(),
        ApiService.getAllProducts(),
      ]);

      final movs = results[0] as List<dynamic>;
      final productos = results[1] as List<Product>;

      if (!mounted) return;
      setState(() {
        _movimientos = movs;
        _nombresArticulos = {
          for (final p in productos) p.id: p.nombre,
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar Kardex: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<dynamic> get _filtrados {
    return _movimientos.where((m) {
      final tipo = (m['tipoMovimiento'] ?? '').toString().toUpperCase();
      if (_filtroTipo != 'TODOS' && tipo != _filtroTipo) return false;

      if (_busqueda.trim().isNotEmpty) {
        final q = _busqueda.trim().toLowerCase();
        final idArt = (m['idArticulo'] ?? 0) as int;
        final nombre = (_nombresArticulos[idArt] ?? '').toLowerCase();
        final motivo = (m['motivo'] ?? '').toString().toLowerCase();
        return nombre.contains(q) || motivo.contains(q);
      }
      return true;
    }).toList();
  }

  String _fmtFecha(String? raw) {
    if (raw == null || raw.isEmpty) return 'Sin fecha';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;

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
                  'Kardex — Movimientos de Inventario',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                IconButton.filledTonal(
                  onPressed: _cargarKardex,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar bitácora',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _busqueda = v),
                    decoration: InputDecoration(
                      hintText: 'Filtrar por producto o motivo...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'TODOS', label: Text('Todos')),
                    ButtonSegment(value: 'ENTRADA', label: Text('Entradas')),
                    ButtonSegment(value: 'SALIDA', label: Text('Salidas')),
                  ],
                  selected: {_filtroTipo},
                  onSelectionChanged: (set) =>
                      setState(() => _filtroTipo = set.first),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : lista.isEmpty
                      ? const Center(
                          child: Text('No hay movimientos registrados'))
                      : ListView.separated(
                          itemCount: lista.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = lista[index];
                            final tipo = (m['tipoMovimiento'] ?? '')
                                .toString()
                                .toUpperCase();
                            final esEntrada = tipo == 'ENTRADA';
                            final idArt = (m['idArticulo'] ?? 0) as int;
                            final nombreArt =
                                _nombresArticulos[idArt] ?? 'Artículo #$idArt';
                            final cant = m['cantidad'] ?? 0;
                            final motivo = m['motivo'] ?? 'Sin motivo';
                            final fecha = _fmtFecha(m['fecha'] as String?);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: esEntrada
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.redAccent.withValues(alpha: 0.2),
                                child: Icon(
                                  esEntrada
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: esEntrada
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                              ),
                              title: Text(
                                nombreArt,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('$motivo  •  $fecha'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: esEntrada
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.redAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${esEntrada ? '+' : '-'}$cant ($tipo)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: esEntrada
                                        ? Colors.green
                                        : Colors.redAccent,
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