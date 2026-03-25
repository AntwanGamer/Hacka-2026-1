import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:math'; 
import 'package:zombie/db/metodosUsuarios.dart'; 

class UsuariosView extends StatefulWidget {
  const UsuariosView({super.key});

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView> {
  final MetodosUsuarios metodos = MetodosUsuarios();
  
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _rowsPerPage = 8;

  void _mostrarSnackBar(BuildContext context, String mensaje, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? theme.colorScheme.error : Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
  // --- DIÁLOGO CRUD ---
  Future<void> _showUsuarioDialog(BuildContext parentContext, {Map<String, dynamic>? usuario}) async {
    final isEditing = usuario != null;
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(parentContext);
    bool isLoading = false;

    // 1. DEFINIR ROLES PERMITIDOS
    final List<String> rolesPermitidos = ['Admin', 'Capturista'];

    // 2. CONFIGURAR VALOR INICIAL
    String rolInicial = 'Capturista'; 
    if (isEditing) {
      final rolDb = usuario['rol']?.toString() ?? '';
      if (rolesPermitidos.contains(rolDb)) {
        rolInicial = rolDb;
      } else if (rolDb.toLowerCase() == 'admin') {
        rolInicial = 'Admin';
      }
    }

    final nombreController = TextEditingController(text: isEditing ? usuario['nombre'] : '');
    final roleController = TextEditingController(text: rolInicial);
    final contactoController = TextEditingController(text: isEditing ? usuario['contacto']?.toString() : '');
    final emailController = TextEditingController(text: isEditing ? usuario['email'] : '');
    final passController = TextEditingController(); 

    await showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Icon(isEditing ? Icons.manage_accounts : Icons.person_add_alt, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(isEditing ? 'Editar Usuario' : 'Nuevo Usuario', style: TextStyle(color: theme.colorScheme.onSurface)),
                ],
              ),
              content: SizedBox(
                width: 400, // Ancho fijo para que no se vea aplastado
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // NOMBRE
                        TextFormField(
                          controller: nombreController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Nombre Completo',
                            prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          ),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // ROL
                        DropdownButtonFormField<String>(
                          value: roleController.text,
                          dropdownColor: theme.colorScheme.surface,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Rol',
                            prefixIcon: Icon(Icons.security, color: theme.colorScheme.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          ),
                          items: rolesPermitidos.map((String role) {
                            return DropdownMenuItem(value: role, child: Text(role));
                          }).toList(),
                          onChanged: (val) {
                            roleController.text = val ?? 'Capturista';
                          },
                        ),
                        const SizedBox(height: 16),

                        // CONTACTO
                        TextFormField(
                          controller: contactoController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            prefixIcon: Icon(Icons.phone_iphone, color: theme.colorScheme.primary),
                            hintText: '10 dígitos',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (v.length != 10) return 'Debe tener 10 dígitos';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // EMAIL
                        TextFormField(
                          controller: emailController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            // Si es edición, deshabilitamos email (Supabase auth restrictions)
                            enabled: !isEditing, 
                          ),
                          enabled: !isEditing,
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                        ),

                        // PASSWORD (Solo si es nuevo)
                        if (!isEditing) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passController,
                            style: TextStyle(color: theme.colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            ),
                            obscureText: true,
                            validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                          ),
                        ],

                        if (isLoading) 
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: CircularProgressIndicator(color: theme.colorScheme.primary),
                          )
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                  child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.error)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: isLoading ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setStateDialog(() => isLoading = true);
                      
                      String? error;
                      try {
                        if (isEditing) {
                          error = await metodos.actualizarUsuario(
                            usuario['id'].toString(), 
                            nombre: nombreController.text,
                            role: roleController.text,
                            contacto: contactoController.text,
                            email: emailController.text,
                          );
                        } else {
                          error = await metodos.crearUsuarioCompleto(
                            nombre: nombreController.text,
                            role: roleController.text,
                            contacto: contactoController.text,
                            email: emailController.text,
                            password: passController.text,
                          );
                        }
                      } catch (e) {
                        error = e.toString();
                      }

                      if (error == null) {
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (parentContext.mounted) _mostrarSnackBar(parentContext, 'Operación exitosa', isError: false);
                      } else {
                        setStateDialog(() => isLoading = false);
                        if (parentContext.mounted) _mostrarSnackBar(parentContext, error, isError: true);
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final headerStyle = TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 15);
    final cellStyle = TextStyle(color: theme.colorScheme.onSurfaceVariant);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // --- 1. TÍTULO E INTRODUCCIÓN ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.admin_panel_settings, color: theme.colorScheme.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Gestión de Usuarios", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    Text("Controla el acceso y roles del personal", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- 2. BARRA DE HERRAMIENTAS ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: theme.shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  // Buscador
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      onChanged: (val) => setState(() => _currentPage = 0),
                      decoration: InputDecoration(
                        hintText: 'Buscar usuario por nombre, email o rol...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Botón Agregar
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () => _showUsuarioDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. TABLA DE USUARIOS ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: metodos.streamUsuarios(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error)));
                }

                final List<Map<String, dynamic>> allUsuarios = snapshot.data ?? [];
                
                final searchTerm = _searchController.text.toLowerCase();
                final filteredUsuarios = allUsuarios.where((u) {
                  final nombre = (u['nombre'] ?? '').toString().toLowerCase();
                  final email = (u['email'] ?? '').toString().toLowerCase();
                  final rol = (u['rol'] ?? '').toString().toLowerCase();
                  return nombre.contains(searchTerm) || email.contains(searchTerm) || rol.contains(searchTerm);
                }).toList();

                final totalRecords = filteredUsuarios.length;
                final totalPages = (totalRecords / _rowsPerPage).ceil();

                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }

                final startIndex = _currentPage * _rowsPerPage;
                final endIndex = min(startIndex + _rowsPerPage, totalRecords);
                final usuariosToShow = (totalRecords > 0) ? filteredUsuarios.sublist(startIndex, endIndex) : [];

                return Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                          child: DataTable(
                            headingRowHeight: 50,
                            dataRowMaxHeight: 60,
                            horizontalMargin: 20,
                            columnSpacing: 40,
                            headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                            dividerThickness: 0.5,
                            columns: [
                              DataColumn(label: Text('Nombre', style: headerStyle)),
                              DataColumn(label: Text('Rol', style: headerStyle)),
                              DataColumn(label: Text('Contacto', style: headerStyle)),
                              DataColumn(label: Text('Email', style: headerStyle)),
                              DataColumn(label: Text('Acciones', style: headerStyle)),
                            ],
                            rows: usuariosToShow.map((usuarioMap) {
                              // Estilo especial para Admin
                              final esAdmin = (usuarioMap['rol'] == 'Admin');
                              final rolColor = esAdmin ? Colors.orange : Colors.blue;

                              return DataRow(cells: [
                                // Nombre con Avatar
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: rolColor.withOpacity(0.1),
                                        child: Icon(esAdmin ? Icons.security : Icons.person, size: 16, color: rolColor),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(usuarioMap['nombre'] ?? '-', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, fontSize: 14)),
                                    ],
                                  )
                                ),
                                // Rol con Chip
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: rolColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: rolColor.withOpacity(0.3))
                                    ),
                                    child: Text(
                                      usuarioMap['rol'] ?? 'User',
                                      style: TextStyle(color: rolColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(Text(usuarioMap['contacto'] ?? '-', style: cellStyle)),
                                DataCell(Text(usuarioMap['email'] ?? '-', style: cellStyle)),
                                // Acciones limpias
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                                        tooltip: "Editar",
                                        onPressed: () => _showUsuarioDialog(context, usuario: usuarioMap),
                                      ),
                                      const SizedBox(width: 0),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                        tooltip: "Eliminar",
                                        onPressed: () async {
                                           final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: theme.colorScheme.surface,
                                              title: const Text('Eliminar Usuario'),
                                              content: Text('¿Deseas eliminar a "${usuarioMap['nombre']}"?\n\nEsta acción no se puede deshacer.'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                                  onPressed: () => Navigator.of(ctx).pop(true), 
                                                  child: const Text('Confirmar')
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (confirm == true) {
                                            try {
                                              String? resultado = await metodos.eliminarUsuarioInteligente(usuarioMap['id'].toString());
                                              if (context.mounted && resultado != null) {
                                                 bool esMensajeError = resultado.toLowerCase().contains('error') || resultado.contains('falló');
                                                 _mostrarSnackBar(context, resultado, isError: esMensajeError);
                                              }
                                            } catch (e) {
                                              if (context.mounted) _mostrarSnackBar(context, "Error al eliminar: $e", isError: true);
                                            }
                                          }
                                        }, 
                                      ),
                                    ],
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                      
                      // Paginación
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${startIndex + 1}-${endIndex} de $totalRecords registros',
                              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage == 0 ? null : () => setState(() => _currentPage--),
                                  disabledColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                                  color: theme.colorScheme.primary,
                                ),
                                Text('${_currentPage + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage >= (totalPages - 1) ? null : () => setState(() => _currentPage++),
                                  disabledColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}