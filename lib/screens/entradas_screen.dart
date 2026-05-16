import 'package:flutter/material.dart';
import '../database/db_connection.dart';

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

  List<DropdownItem> _proveedores = [];
  List<DropdownItem> _ubicaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    final conn = await DbConnection.connect();
    final provs = await conn.execute('SELECT id_proveedor, nombre FROM proveedores');
    final ubis = await conn.execute('SELECT id_ubicacion, descripcion FROM ubicaciones');
    await conn.close();

    setState(() {
      _proveedores = provs.map((r) => DropdownItem(r[0] as int, r[1] as String)).toList();
      _ubicaciones = ubis.map((r) => DropdownItem(r[0] as int, r[1] as String)).toList();
    });
  }

  Future<void> _guardarProducto() async {
    if (_nombreCtrl.text.isEmpty) return; // Validación básica

    String? codigoFinal = _codigoCtrl.text.trim().isEmpty ? null : _codigoCtrl.text.trim();

    try {
      final conn = await DbConnection.connect();
      await conn.execute(
        'INSERT INTO productos (nombre, codigo_barras, precio_compra, margen_ganancia, stock_actual, id_proveedor, id_ubicacion) '
        'VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)',
        parameters: [
          _nombreCtrl.text, 
          codigoFinal, 
          double.parse(_costoCtrl.text), 
          double.parse(_margenCtrl.text), 
          int.parse(_stockCtrl.text), 
          _selectedProv, 
          _selectedUbi
        ],
      );
      await conn.close();

      // Limpiar formulario y avisar que se guardó
      _nombreCtrl.clear();
      _codigoCtrl.clear();
      _stockCtrl.text = '0';
      _costoCtrl.text = '0.0';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Producto registrado con éxito'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Registro de Nueva Mercancía', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 600, // Limitamos el ancho para que no se vea estirado en escritorio
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.add_box, size: 60, color: Colors.blueGrey),
                    const SizedBox(height: 20),
                    TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder())),
                    const SizedBox(height: 15),
                    TextField(controller: _codigoCtrl, decoration: const InputDecoration(labelText: 'Código de Barras (Opcional)', border: OutlineInputBorder())),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _costoCtrl, decoration: const InputDecoration(labelText: 'Costo de Compra', border: OutlineInputBorder(), prefixText: '\$ '))),
                        const SizedBox(width: 15),
                        Expanded(child: TextField(controller: _margenCtrl, decoration: const InputDecoration(labelText: '% Margen (Por defecto 40%)', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(controller: _stockCtrl, decoration: const InputDecoration(labelText: 'Cantidad en Stock', border: OutlineInputBorder())),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Proveedor', border: OutlineInputBorder()),
                      items: _proveedores.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))).toList(),
                      onChanged: (val) => _selectedProv = val,
                      value: _selectedProv,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Ubicación Física', border: OutlineInputBorder()),
                      items: _ubicaciones.map((u) => DropdownMenuItem(value: u.id, child: Text(u.nombre))).toList(),
                      onChanged: (val) => _selectedUbi = val,
                      value: _selectedUbi,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _guardarProducto,
                      icon: const Icon(Icons.save),
                      label: const Text('GUARDAR PRODUCTO EN INVENTARIO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}