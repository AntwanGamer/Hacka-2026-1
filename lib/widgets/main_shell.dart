import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zombie/main.dart'; // Enum Screen y MyApp
import 'package:zombie/widgets/side_bar.dart'; // Tu sidebar nuevo
import 'package:zombie/Screens/inicioSesion.dart'; // Para redirigir al Login

// Importa tus Vistas
import 'package:zombie/pantalla_principal.dart'; 
import 'package:zombie/Screens/reciboBasuron.dart';
import 'package:zombie/manifiestos.dart'; 
import 'package:zombie/Screens/personas.dart'; 
import 'package:zombie/Screens/embarcaciones.dart'; 
import 'package:zombie/Screens/bitacora.dart'; 
import 'package:zombie/Screens/usuarios.dart'; 

class MainShell extends StatefulWidget {
  // 1. RECIBIMOS EL ROL
  final String rolUsuario;

  const MainShell({super.key, required this.rolUsuario});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  Screen _currentScreen = Screen.dashboard;

  // Lógica de Cerrar Sesión
  Future<void> _cerrarSesion() async {
    final theme = Theme.of(context);
    
    // 1. Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que quieres salir del sistema?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text("Cancelar")
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error
            ),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Salir")
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 2. Cerrar sesión en Supabase
        await Supabase.instance.client.auth.signOut();
        
        if (!mounted) return;

        // 3. Navegar al Login (borrando historial)
        // OJO: Como tu main está en inicioSesion.dart, redirigimos a LoginApp
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginApp()),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cerrar sesión: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  // Títulos para la barra superior
  String _getScreenTitle(Screen screen) {
    switch (screen) {
      case Screen.dashboard: return 'Panel de Control';
      case Screen.clientes: return 'Gestión';
      case Screen.productos: return 'Gestión';
      case Screen.ventas: return 'Gestión';
      case Screen.asociaciones: return 'Registros';
      case Screen.residuos: return 'Gestión';
      case Screen.usuarios: return 'Seguridad';
    }
  }

  // Selector de Vistas
  Widget _buildScreenContent(Screen screen) {
    // Asegúrate que los nombres de las clases coincidan con tus archivos
    switch (screen) {
      case Screen.dashboard: return const DashboardView();
      case Screen.clientes: return const PersonasView();
      case Screen.productos: return const EmbarcacionesView();
      case Screen.ventas: return const ManifiestosView(); 
      case Screen.residuos: return const ReciboBasuronView();
      case Screen.asociaciones: return const BiotacoraView(); 
      case Screen.usuarios: return const UsuariosView();
      default: return const Center(child: Text("Vista no encontrada"));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // 1. SIDEBAR FIJO
          FixedSidebar(
            currentScreen: _currentScreen,
            // 2. PASAMOS LA BOLA: El rol llega aquí
            rolUsuario: widget.rolUsuario, 
            onNavigate: (Screen newScreen) {
              setState(() => _currentScreen = newScreen);
            },
          ),

          // 2. CONTENIDO + TOP BAR
          Expanded(
            child: Column(
              children: [
                // --- TOP BAR PERSONALIZADA ---
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3))
                    ),
                  ),
                  child: Row(
                    children: [
                      // Título dinámico
                      Text(
                        _getScreenTitle(_currentScreen),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      
                      const Spacer(),

                      // Botón Tema (Sol/Luna)
                      IconButton.filledTonal(
                        onPressed: () => MyApp.of(context).toggleTheme(),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: theme.colorScheme.primary, // Verde DCK
                        ),
                        tooltip: "Cambiar tema",
                      ),

                      const SizedBox(width: 12),

                      // Botón Cerrar Sesión (Rojo suave)
                      IconButton.filled(
                        onPressed: _cerrarSesion,
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: "Cerrar sesión",
                      ),
                    ],
                  ),
                ),

                // --- VISTA PRINCIPAL ---
                Expanded(
                  child: Container(
                    color: theme.colorScheme.background, // Fondo gris/negro
                    child: _buildScreenContent(_currentScreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}