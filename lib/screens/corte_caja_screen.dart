import 'package:flutter/material.dart';
import 'package:papeleria_app/services/api_service.dart';

class CorteCajaScreen extends StatefulWidget {
  const CorteCajaScreen({super.key});

  @override
  State<CorteCajaScreen> createState() => _CorteCajaScreenState();
}

class _CorteCajaScreenState extends State<CorteCajaScreen> {
  bool _cargando = true;
  bool _procesando = false;
  bool _turnoAbierto = false;

  Map<String, dynamic>? _corteActivo;
  double _ventasTurno = 0.0;
  double _montoEsperado = 0.0;
  List<dynamic> _historial = [];

  final _montoInicialCtrl = TextEditingController(text: '500.00');
  final _montoRealCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarEstadoCaja();
  }

  @override
  void dispose() {
    _montoInicialCtrl.dispose();
    _montoRealCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarEstadoCaja() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        ApiService.getCorteActivo(),
        ApiService.getHistorialCortes(),
      ]);

      final estado = results[0] as Map<String, dynamic>;
      final hist = results[1] as List<dynamic>;

      if (!mounted) return;
      setState(() {
        _turnoAbierto = estado['abierto'] == true;
        _corteActivo = estado['corte'] as Map<String, dynamic>?;
        _ventasTurno = ((estado['ventasTurno'] ?? 0) as num).toDouble();
        _montoEsperado = ((estado['montoEsperado'] ?? 0) as num).toDouble();
        _historial = hist.where((c) => c['fechaCierre'] != null).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirTurno() async {
    final inicial = double.tryParse(_montoInicialCtrl.text.trim()) ?? -1;
    if (inicial < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Ingresa un monto inicial válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _procesando = true);
    try {
      await ApiService.abrirCaja(montoInicial: inicial);
      await _cargarEstadoCaja();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Turno de caja abierto correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _cerrarTurno() async {
    final real = double.tryParse(_montoRealCtrl.text.trim());
    if (real == null || real < 0 || _corteActivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Ingresa el efectivo contado en caja'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _procesando = true);
    try {
      final idCorte = (_corteActivo!['idCorte'] as num).toInt();
      await ApiService.cerrarCaja(idCorte: idCorte, montoFinalReal: real);
      _montoRealCtrl.clear();
      await _cargarEstadoCaja();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Corte de caja cerrado y guardado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  String _fmtFecha(String? raw) {
    if (raw == null) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Corte de Caja',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  IconButton.filledTonal(
                    onPressed: _cargarEstadoCaja,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar cifras',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!_turnoAbierto)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_open, color: Colors.orange, size: 32),
                            SizedBox(width: 12),
                            Text(
                              'La caja está cerrada — Iniciar Nuevo Turno',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 340,
                          child: TextField(
                            controller: _montoInicialCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Fondo inicial en caja',
                              prefixText: '\$ ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 18),
                          ),
                          onPressed: _procesando ? null : _abrirTurno,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(_procesando
                              ? 'ABRIENDO...'
                              : 'ABRIR TURNO DE CAJA'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Turno Activo #${_corteActivo!['idCorte']}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Apertura: ${_fmtFecha(_corteActivo!['fechaApertura'] as String?)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: _DatoCaja(
                                titulo: 'Fondo Inicial',
                                valor: ((_corteActivo!['montoInicial'] ?? 0) as num)
                                    .toDouble(),
                                color: Colors.blueAccent,
                              ),
                            ),
                            Expanded(
                              child: _DatoCaja(
                                titulo: 'Ventas del Turno',
                                valor: _ventasTurno,
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _DatoCaja(
                                titulo: 'Total Esperado en Caja',
                                valor: _montoEsperado,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          children: [
                            SizedBox(
                              width: 320,
                              child: TextField(
                                controller: _montoRealCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Efectivo físico contado al cierre',
                                  prefixText: '\$ ',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 20),
                              ),
                              onPressed: _procesando ? null : _cerrarTurno,
                              icon: const Icon(Icons.lock),
                              label: Text(_procesando
                                  ? 'CERRANDO...'
                                  : 'CERRAR CAJA Y ARQUEAR'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              const Text(
                'Historial de Cortes Cerrados',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_historial.isEmpty)
                const Text('Aún no hay cortes cerrados registrados.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _historial.length,
                  itemBuilder: (context, index) {
                    final c = _historial[index];
                    final esperado =
                        ((c['montoFinalCalculado'] ?? 0) as num).toDouble();
                    final real =
                        ((c['montoFinalReal'] ?? 0) as num).toDouble();
                    final dif = ((c['diferencia'] ?? 0) as num).toDouble();
                    final colorDif = dif == 0
                        ? Colors.green
                        : (dif > 0 ? Colors.blueAccent : Colors.redAccent);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.point_of_sale, color: Colors.white),
                        ),
                        title: Text(
                          'Corte #${c['idCorte']} — Cierre: ${_fmtFecha(c['fechaCierre'] as String?)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Esperado: \$${esperado.toStringAsFixed(2)}  |  Contado: \$${real.toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          'Dif: ${dif >= 0 ? '+' : ''}\$${dif.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: colorDif,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoCaja extends StatelessWidget {
  final String titulo;
  final double valor;
  final Color color;

  const _DatoCaja({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}