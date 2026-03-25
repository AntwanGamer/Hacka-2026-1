import 'package:flutter/material.dart';
import 'dart:math'; // Para max y min
import 'package:zombie/db/metodosPersonas.dart';

class PersonasView extends StatefulWidget {
  const PersonasView({super.key});

  @override
  State<PersonasView> createState() => _PersonasViewState();
}

class _PersonasViewState extends State<PersonasView> {
  final MetodosPersonas metodos = MetodosPersonas();
  
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _rowsPerPage = 8;

  // --- HELPER PARA MOSTRAR SNACKBAR (ESTILIZADO) ---
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

  // --- HELPER PARA COLOR DE CHIP SEGÚN ROL ---
  Color _getColorPorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'dueño': return Colors.purple;
      case 'cocinero': return Colors.orange;
      case 'motorista': return Colors.blue;
      default: return Colors.grey;
    }
  }

  // --- DIÁLOGO CREAR / EDITAR ---
  Future<void> _showPersonaDialog(BuildContext parentContext, {Map<String, dynamic>? persona}) async {
    final isEditing = persona != null;
    final formKey = GlobalKey<FormState>();
    final List<String> opcionesTipo = ['Cocinero', 'Motorista', 'Dueño'];

    String? tipoSeleccionado;
    if (isEditing && opcionesTipo.contains(persona['tipo_persona'])) {
      tipoSeleccionado = persona['tipo_persona'];
    }

    final nombreController = TextEditingController(text: isEditing ? persona['nombre'] : '');
    final tipoController = TextEditingController(text: tipoSeleccionado ?? '');
    final contactoController = TextEditingController(text: isEditing ? persona['info_contacto'] : '');

    final theme = Theme.of(parentContext);

    await showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              title: Row(
                children: [
                  Icon(isEditing ? Icons.edit_note : Icons.person_add, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(isEditing ? 'Editar Persona' : 'Nueva Persona'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      dropdownColor: theme.colorScheme.surface,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Rol / Puesto',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      items: opcionesTipo.map((String tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setStateDialog(() {
                          tipoSeleccionado = nuevoValor;
                          tipoController.text = nuevoValor ?? '';
                        });
                      },
                      validator: (value) => value == null ? 'Selecciona una opción' : null,
                    ),

                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: contactoController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Contacto (Tel/Email)',
                        prefixIcon: const Icon(Icons.contact_phone_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.error)), 
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        if (isEditing) {
                          await metodos.actualizarPersona(
                            persona['id_personas'], 
                            nombre: nombreController.text,
                            tipoPersona: tipoController.text,
                            infContacto: contactoController.text,
                          );
                          if (parentContext.mounted) _mostrarSnackBar(parentContext, "Actualizado correctamente");
                        } else {
                          await metodos.insertarPersona(
                            nombre: nombreController.text,
                            tipoPersona: tipoController.text,
                            infContacto: contactoController.text,
                          );
                          if (parentContext.mounted) _mostrarSnackBar(parentContext, "Creado correctamente");
                        }
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        if (parentContext.mounted) _mostrarSnackBar(parentContext, "Error: $e", isError: true);
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
    
    // Estilos de texto
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.people_alt_rounded, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Gestión de Personal", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    Text("Administra cocineros, motoristas y dueños", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // --- 2. BARRA DE HERRAMIENTAS (BUSCADOR + BOTÓN) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
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
                        hintText: 'Buscar por nombre o puesto...',
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
                    onPressed: () => _showPersonaDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. TABLA DE DATOS ESTILIZADA ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: metodos.streamPersonas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
                }
                
                if (snapshot.hasError) {
                   return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error)));
                }

                final List<Map<String, dynamic>> allPersonas = snapshot.data ?? [];
                
                // Filtrado
                final searchTerm = _searchController.text.toLowerCase();
                final filteredPersonas = allPersonas.where((p) {
                  final nombre = p['nombre'].toString().toLowerCase();
                  final tipo = p['tipo_persona'].toString().toLowerCase();
                  return nombre.contains(searchTerm) || tipo.contains(searchTerm);
                }).toList();

                // Paginación
                final totalRecords = filteredPersonas.length;
                final totalPages = (totalRecords / _rowsPerPage).ceil();

                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }

                final startIndex = _currentPage * _rowsPerPage;
                final endIndex = min(startIndex + _rowsPerPage, totalRecords);
                final personasToShow = (totalRecords > 0) ? filteredPersonas.sublist(startIndex, endIndex) : [];

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
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64), // Ajuste ancho
                          child: DataTable(
                            headingRowHeight: 50,
                            dataRowMaxHeight: 60,
                            horizontalMargin: 20,
                            columnSpacing: 40,
                            headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                            dividerThickness: 0.5,
                            columns: [
                              DataColumn(label: Text('#', style: headerStyle)),
                              DataColumn(label: Text('Nombre', style: headerStyle)),
                              DataColumn(label: Text('Rol', style: headerStyle)),
                              DataColumn(label: Text('Contacto', style: headerStyle)),
                              DataColumn(label: Text('Acciones', style: headerStyle)),
                            ],
                            rows: personasToShow.map((personaMap) {
                              final roleColor = _getColorPorRol(personaMap['tipo_persona'] ?? '');
                              
                              return DataRow(cells: [
                                DataCell(Text((personaMap['id_personas'] ?? '').toString(), style: cellStyle)),
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: roleColor.withOpacity(0.1),
                                        child: Text(
                                          (personaMap['nombre'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: roleColor),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(personaMap['nombre'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                    ],
                                  )
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: roleColor.withOpacity(0.3))
                                    ),
                                    child: Text(
                                      personaMap['tipo_persona'] ?? '',
                                      style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(Text(personaMap['info_contacto'] ?? '', style: cellStyle)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                                        tooltip: "Editar",
                                        onPressed: () => _showPersonaDialog(context, persona: personaMap),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                        tooltip: "Eliminar",
                                        onPressed: () async {
                                           final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: theme.colorScheme.surface,
                                              title: const Text('Confirmar eliminación'),
                                              content: Text('¿Deseas eliminar a "${personaMap['nombre']}"? Esta acción no se puede deshacer.'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                                  onPressed: () => Navigator.pop(ctx, true), 
                                                  child: const Text('Eliminar')
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              await metodos.eliminarPersonaConVerificacion(personaMap['id_personas']);
                                              if (context.mounted) _mostrarSnackBar(context, "Eliminado correctamente");
                                            } catch (e) {
                                              if (context.mounted) _mostrarSnackBar(context, "Error: $e", isError: true);
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
                      
                      // Paginación (Reutilizando estilo limpio)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${startIndex + 1}-${endIndex} de $totalRecords',
                              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage == 0 ? null : () => setState(() => _currentPage--),
                                  disabledColor: Colors.grey.withOpacity(0.3),
                                  color: theme.colorScheme.primary,
                                ),
                                Text('${_currentPage + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage >= (totalPages - 1) ? null : () => setState(() => _currentPage++),
                                  disabledColor: Colors.grey.withOpacity(0.3),
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