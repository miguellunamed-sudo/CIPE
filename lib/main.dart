import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'; // <-- 1. Importamos el paquete
import 'database/db_connection.dart';
import 'screens/main_layout.dart';

void main() async {
  // Asegura que Flutter esté listo antes de ejecutar código nativo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializamos el controlador de ventanas
  await windowManager.ensureInitialized();

  // 3. Configuramos cómo queremos que se comporte la ventana al arrancar
  WindowOptions windowOptions = const WindowOptions(
    title: 'Sistema Papelería',
    center: true, // Que arranque en el centro si no está maximizada
  );

  // 4. Le decimos que espere a estar lista y entonces se maximice
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    
    // Aquí usamos maximize() en lugar de setFullScreen() para que 
    // la barra de tareas (Windows) o el Dock (Mac) sigan visibles y sea más cómodo.
    await windowManager.maximize(); 
  });

  print('⏳ Intentando conectar a la base de datos...');
  try {
    final connection = await DbConnection.connect();
    print('✅ ¡Conexión exitosa a PostgreSQL!');
    await connection.close();
  } catch (e) {
    print('❌ Error al conectar: $e');
  }

  // Arrancamos la interfaz gráfica
  runApp(const PapeleriaApp());
}

class PapeleriaApp extends StatelessWidget {
  const PapeleriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema Papelería',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainLayout(), 
    );
  }
}