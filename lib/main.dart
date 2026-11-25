import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo ejecuta window_manager en escritorio (macOS / Windows), nunca en Chrome
  if (!kIsWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      title: 'Sistema Papelería',
      center: true,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize();
    });
  }

  runApp(const PapeleriaApp());
}

// Configuración global de accesibilidad
const TextTheme accessibilityTextTheme = TextTheme(
  bodyLarge: TextStyle(fontSize: 22.0),
  bodyMedium: TextStyle(fontSize: 20.0), // Tamaño base ampliado
  titleLarge: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
  labelLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600), // Botones
);

const IconThemeData accessibilityIconTheme = IconThemeData(
  size: 36.0, // El tamaño default de Flutter es 24.0
);

// TEMA LITE DARK (Grises para menor fatiga visual)
final ThemeData liteDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF2C2C2C),
  colorScheme: const ColorScheme.dark(
    primary: Colors.blueAccent,
    surface: Color(0xFF3A3A3A), // Contraste suave para tarjetas
  ),
  textTheme: accessibilityTextTheme,
  iconTheme: accessibilityIconTheme,
  useMaterial3: true,
);

// TEMA ULTRA DARK (Negro puro para máximo contraste)
final ThemeData ultraDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  colorScheme: const ColorScheme.dark(
    primary: Colors.blueAccent,
    surface: Color(0xFF121212), // Casi negro
  ),
  textTheme: accessibilityTextTheme,
  iconTheme: accessibilityIconTheme,
  useMaterial3: true,
);

class PapeleriaApp extends StatefulWidget {
  const PapeleriaApp({super.key});

  @override
  State<PapeleriaApp> createState() => _PapeleriaAppState();
}

class _PapeleriaAppState extends State<PapeleriaApp> {
  // Estado inicial del tema
  ThemeData _currentTheme = liteDarkTheme;
  bool _isUltraDark = false;

  void toggleTheme() {
    setState(() {
      _isUltraDark = !_isUltraDark;
      _currentTheme = _isUltraDark ? ultraDarkTheme : liteDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema Papelería',
      theme: _currentTheme,
      // Mantiene tu layout original con Inventario Total y el botón de tema
      home: MainLayout(onThemeToggle: toggleTheme, isUltraDark: _isUltraDark),
    );
  }
}