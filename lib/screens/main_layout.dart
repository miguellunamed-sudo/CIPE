import 'package:flutter/material.dart';
import 'entradas_screen.dart';
import 'inventory_screen.dart';
import 'ventas_screen.dart'; // Tu archivo de ventas que vimos en el explorador

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
  // El índice 0 corresponde a Ventas, asegurando que sea la pantalla predeterminada al arrancar
  int _selectedIndex = 0;

  // Arreglo con las instancias de tus pantallas limpias
  final List<Widget> _screens = const [
    VentasScreen(),
    InventoryScreen(),
    EntradasScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mantenemos un AppBar global minimalista únicamente para el botón del Drawer
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
                /*child: Text(
                  'Menú CIPE',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),*/
                child: Image.asset('assets/LOGO.png'),
              ),
              //child: Image(image: ../assets/LOGO.png),
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
      // Muestra la pantalla correspondiente al índice seleccionado
      body: _screens[_selectedIndex],
    );
  }
}