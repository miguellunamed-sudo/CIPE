import 'package:flutter/material.dart';
import 'package:papeleria_app/screens/entradas_screen.dart';
import 'inventory_screen.dart';
import 'ventas_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder nos dice cuánto espacio hay disponible en tiempo real
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si el ancho es mayor a 700 píxeles, extendemos el menú
        bool esPantallaGrande = constraints.maxWidth > 700;

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                // Aquí está el truco: se extiende solo si hay espacio
                extended: esPantallaGrande, 
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: Colors.blueGrey[50],
                leading: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Si el menú está contraído, hacemos el logo más chiquito
                    Image.asset(
                      'assets/LOGO.png',
                      width: esPantallaGrande ? 100 : 40,
                      height: esPantallaGrande ? 100 : 40,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.store, size: esPantallaGrande ? 50 : 30),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.point_of_sale_outlined),
                    selectedIcon: Icon(Icons.point_of_sale, color: Colors.blue),
                    label: Text('Nueva Venta'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory, color: Colors.blue),
                    label: Text('Inventario'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.add_box_outlined),
                    selectedIcon: Icon(Icons.add_box, color: Colors.blue),
                    label: Text('Entradas'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.warning_amber_rounded),
                    selectedIcon: Icon(Icons.warning, color: Colors.orange),
                    label: Text('Stock Bajo'),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _construirPantallaActiva(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
    
  Widget _construirPantallaActiva() {
    switch (_selectedIndex) {
      case 0:
        return const VentasScreen();
      case 1:
        return const InventoryScreen();
      case 2:
        return const EntradasScreen();
      case 3:
        return const Center(child: Text('Stock Bajo'));
      default:
        return const Center(child: Text('Seleccione una opción'));
    }
  }
}