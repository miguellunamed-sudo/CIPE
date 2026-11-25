import 'package:flutter/material.dart';
import 'package:papeleria_app/services/api_service.dart';

class DropdownItem {
  final int id;
  final String nombre;
  DropdownItem(this.id, this.nombre);
}

class EntradasScreen extends StatefulWidget {
  const EntradasScreen({super.key});

  @override
  State<EntradasScreen> createState() => _EntradasScreenState();
}

class _EntradasScreenState extends State<EntradasScreen> {
  final _nombreCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _costoCtrl = TextEditingController(text: '0.0');
  final _margenCtrl = TextEditingController(text: '40.0');
  final _stockCtrl = TextEditingController(text: '0');

  int? _selectedProv;
  int? _selectedUbi;
  bool _guardando = false;

  // Listas listas para cuando expongas /api/proveedores y /api/ubicaciones
  final List<DropdownItem> _proveedores = [];
  final List<DropdownItem> _ubicaciones = [];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _costoCtrl.dispose();
    _margenCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  double get _precioFinalCalculado {
    final costo = double.tryParse(_costoCtrl.text.trim()) ?? 0.0;
    final margen = double.tryParse(_margenCtrl.text.trim()) ?? 0.0;
    return costo * (1 + (margen / 100));
  }

  Future<void> _guardarProducto() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Ingresa el nombre del producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final codigoFinal = _codigoCtrl.text.trim().isEmpty
        ? null
        : _codigoCtrl.text.trim();
    final costo = double.tryParse(_costoCtrl.text.trim()) ?? 0.0;
    final margen = double.tryParse(_margenCtrl.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final precioFinal = double.parse(_precioFinalCalculado.toStringAsFixed(2));

    setState(() => _guardando = true);

    try {
      await ApiService.createProduct(
        nombre: nombre,
        codigoBarras: codigoFinal,
        costoCompra: costo,
        margenGanancia: margen,
        precioFinal: precioFinal,
        stockActual: stock,
        idProveedor: _selectedProv,
        idUbicacion: _selectedUbi,
      );

      _nombreCtrl.clear();
      _codigoCtrl.clear();
      _stockCtrl.text = '0';
      _costoCtrl.text = '0.0';
      setState(() {
        _selectedProv = null;
        _selectedUbi = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto registrado en la nube con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Registro de Nueva Mercancía',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.add_box,
                          size: 80,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Producto',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _codigoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Código de Barras (Opcional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _costoCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Costo de Compra',
                                  border: OutlineInputBorder(),
                                  prefixText: '\$ ',
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: _margenCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: '% Margen',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Precio Final al Público: \$${_precioFinalCalculado.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad en Stock',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Proveedor (Opcional)',
                            border: OutlineInputBorder(),
                          ),
                          items: _proveedores
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedProv = val),
                          value: _selectedProv,
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Ubicación Física (Opcional)',
                            border: OutlineInputBorder(),
                          ),
                          items: _ubicaciones
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u.id,
                                  child: Text(u.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedUbi = val),
                          value: _selectedUbi,
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _guardando ? null : _guardarProducto,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _guardando
                                ? 'GUARDANDO EN LA NUBE...'
                                : 'GUARDAR PRODUCTO EN INVENTARIO',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
      ),
    );
  }
}
