import 'package:flutter/material.dart';
import 'package:zombie/main.dart'; // para el enum Screen

class FixedSidebar extends StatelessWidget {
  final Screen currentScreen;
  final ValueChanged<Screen> onNavigate;
  // 1. RECIBIMOS EL ROL
  final String rolUsuario; 

  const FixedSidebar({
    super.key,
    required this.currentScreen,
    required this.onNavigate,
    required this.rolUsuario, // 2. Agregado al constructor
  });

  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Screen targetScreen,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // --- ESTILO MATERIAL 3 ADAPTATIVO ---
    
    // Fondo: Verde suave si está seleccionado, transparente si no.
    final Color backgroundColor = isSelected 
        ? colorScheme.primaryContainer 
        : Colors.transparent;

    // Icono/Texto: Verde fuerte si seleccionado, Gris/Negro si no.
    final Color foregroundColor = isSelected
        ? colorScheme.onPrimaryContainer // Verde oscuro / Blanco según modo
        : colorScheme.onSurfaceVariant; // Gris elegante

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12), // Bordes redondeados modernos
        ),
        child: ListTile(
          onTap: isSelected ? null : () => onNavigate(targetScreen),
          selected: isSelected,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          
          leading: Icon(icon, color: foregroundColor, size: 24),
          title: Text(
            title,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Un gris muy sutil para diferenciar el sidebar del contenido principal
    final sidebarColor = theme.brightness == Brightness.dark 
        ? theme.colorScheme.surfaceContainerLow 
        : Colors.white;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: sidebarColor,
        border: Border(right: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
      ),
      child: Column(
        children: [
          // --- HEADER CON LOGO ---
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Logo con sombra suave
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5)
                      )
                    ]
                  ),
                  child: Image.asset(
                    'lib/assets/DCKLogoSinFondo.png',
                    height: 80, 
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'DCK Admin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary, // Verde de la marca
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // --- LISTA DE MENÚ ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader(context, "PANEL DE CONTROL"),
                _buildDrawerItem(
                  context: context,
                  title: 'Estadísticas',
                  icon: Icons.dashboard_rounded, // Icono redondeado moderno
                  targetScreen: Screen.dashboard,
                  isSelected: currentScreen == Screen.dashboard,
                ),

                const SizedBox(height: 20),
                _buildSectionHeader(context, "GESTIÓN"),
                
                _buildDrawerItem(
                  context: context,
                  title: 'Personas',
                  icon: Icons.people_alt_rounded,
                  targetScreen: Screen.clientes,
                  isSelected: currentScreen == Screen.clientes,
                ),
                _buildDrawerItem(
                  context: context,
                  title: 'Embarcaciones',
                  icon: Icons.sailing_rounded,
                  targetScreen: Screen.productos,
                  isSelected: currentScreen == Screen.productos,
                ),
                _buildDrawerItem(
                  context: context,
                  title: 'Manifiestos',
                  icon: Icons.receipt_long_rounded,
                  targetScreen: Screen.ventas,
                  isSelected: currentScreen == Screen.ventas,
                ),
                _buildDrawerItem(
                  context: context,
                  title: 'Recibos Basurón',
                  icon: Icons.delete_outline_rounded,
                  targetScreen: Screen.residuos,
                  isSelected: currentScreen == Screen.residuos,
                ),

                const SizedBox(height: 20),
                _buildSectionHeader(context, "REGISTROS"),

                _buildDrawerItem(
                  context: context,
                  title: 'Bitácora',
                  icon: Icons.history_edu_rounded,
                  targetScreen: Screen.asociaciones,
                  isSelected: currentScreen == Screen.asociaciones,
                ),


                const SizedBox(height: 20),

                // 3. CONDICIÓN PARA OCULTAR
                // Si el rol NO es Capturista, mostramos Usuarios.
                if (rolUsuario != 'Capturista')

                _buildSectionHeader(context, "SEGURIDAD"),
                if (rolUsuario != 'Capturista')
                  _buildDrawerItem(
                    context: context,
                    title: 'Usuarios',
                    icon: Icons.admin_panel_settings_rounded,
                    targetScreen: Screen.usuarios,
                    isSelected: currentScreen == Screen.usuarios,
                  ),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 28.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.outline,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}