import 'package:flutter/material.dart';
import 'package:zombie/Screens/inicioSesion.dart';
import 'widgets/main_shell.dart';
import 'package:provider/provider.dart';
import 'package:zombie/Screens/asociacionesRecolectoras.dart'; 
import 'package:zombie/Screens/reciboBasuron.dart'; 
import 'package:zombie/Screens/usuarios.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zombie/db/reciboBasuronDatabase.dart';

// Enumeración para identificar las vistas de forma segura
enum Screen {
  dashboard,
  clientes,
  productos,
  ventas,
  asociaciones,
  residuos,
  usuarios,
}

// MyApp es el dueño del estado del tema (StatefulWidget)
class MyApp extends StatefulWidget {
  // 1. VARIABLE NUEVA: Recibe el rol
  final String rolUsuario;

  // 2. CONSTRUCTOR: Pide el rol obligatoriamente
  const MyApp({super.key, required this.rolUsuario});

  @override
  State<MyApp> createState() => _MyAppState();

  // Método estático para acceder al estado del tema desde cualquier widget
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark; 

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  // Definimos el color principal de DCK
  static const Color dckGreenSeed = Color.fromARGB(255, 113, 192, 105);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DCK Admin Dashboard',
      debugShowCheckedModeBanner: false,

      themeMode: _themeMode,

      // Tema Claro (Basado en el Verde DCK)
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: dckGreenSeed, 
          brightness: Brightness.light,
          background: Colors.grey.shade50,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      // Tema Oscuro (Basado en el Verde DCK)
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: dckGreenSeed, 
          brightness: Brightness.dark,
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // 3. PASAMOS LA BOLA: Le damos el rol al MainShell
      home: MainShell(rolUsuario: widget.rolUsuario),
    );
  }
}