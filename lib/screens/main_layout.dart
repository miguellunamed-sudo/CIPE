import 'package:flutter/material.dart';
import 'package:papeleria_app/screens/entradas_screen.dart';
import 'package:papeleria_app/screens/historial_ventas_screen.dart';
import 'package:papeleria_app/screens/inventory_screen.dart';
import 'package:papeleria_app/screens/ventas_screen.dart';

class MainLayout extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isUltraDark;

  const MainLayout({
    super.key,
    required this.onThemeToggle,
    required this.isUltraDark,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    VentasScreen(),
    InventoryScreen(),
    EntradasScreen(),
    HistorialVentasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
              ),
              child: Center(
                child: Image.asset('assets/LOGO.png'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Punto de Venta'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Inventario Total'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Nueva Mercancía'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Historial de Ventas'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(),
            ExpansionTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: SwitchListTile(
                    title: const Text('Modo Ultra Dark'),
                    secondary: const Icon(Icons.contrast),
                    value: widget.isUltraDark,
                    onChanged: (bool value) {
                      widget.onThemeToggle();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}