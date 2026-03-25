import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math'; 
import 'package:zombie/db/metodosEmbarcaciones.dart';

class EmbarcacionesView extends StatefulWidget {
  const EmbarcacionesView({super.key});

  @override
  State<EmbarcacionesView> createState() => _EmbarcacionesView();
}

class _EmbarcacionesView extends State<EmbarcacionesView> {
  final MetodosEmbarcaciones metodos = MetodosEmbarcaciones();
  
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

  // --- HELPER PARA COLOR DE CHIP ---
  Color _getColorPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'pesquero': return Colors.blue;
      case 'turístico': return Colors.orange;
      case 'recreativo': return Colors.purple;
      case 'organizaciones ecológicas': return Colors.green;
      case 'N/A': return Colors.grey;
      default: return Colors.grey;
    }
  }

  // --- DIÁLOGO CRUD ---
  Future<void> _showEmbarcacionDialog(BuildContext parentContext, {Map<String, dynamic>? embarcacion}) async {
    final isEditing = embarcacion != null;
    final formKey = GlobalKey<FormState>();
    final theme = Theme.of(parentContext);

    final List<String> opcionesTipo = [
      'Pesquero', 'Turístico', 'Recreativo', 'Organizaciones ecológicas', 'N/A'
    ];

    String? tipoSeleccionado;
    if (isEditing && opcionesTipo.contains(embarcacion['tipo_embarcacion'])) {
      tipoSeleccionado = embarcacion['tipo_embarcacion'];
    }

    final nombreController = TextEditingController(text: isEditing ? embarcacion['nombre_embarcacion'] : '');
    final tipoController = TextEditingController(text: tipoSeleccionado ?? '');

    String fechaInicial = '';
    if (isEditing && embarcacion['fecha_registro'] != null) {
      try {
        DateTime fechaDt = DateTime.parse(embarcacion['fecha_registro']);
        fechaInicial = "${fechaDt.day.toString().padLeft(2, '0')}/${fechaDt.month.toString().padLeft(2, '0')}/${fechaDt.year}";
      } catch (e) {
        fechaInicial = '';
      }
    }
    final fechaController = TextEditingController(text: fechaInicial);

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
                  Icon(isEditing ? Icons.edit_note : Icons.sailing, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? 'Editar Embarcación' : 'Nueva Embarcación',
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20),
                    ),
                  ),
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
                        labelText: 'Nombre de la Embarcación',
                        prefixIcon: Icon(Icons.directions_boat_filled_outlined, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: tipoSeleccionado,
                      isExpanded: true,
                      dropdownColor: theme.colorScheme.surface,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(Icons.category_outlined, color: theme.colorScheme.primary),
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
                      controller: fechaController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Fecha de Registro',
                        hintText: 'DD/MM/AAAA',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        counterText: "",
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        DateTextFormatter(),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (v.length != 10) return 'Formato incompleto';
                        return null;
                      },
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
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        List<String> partes = fechaController.text.split('/');
                        int dia = int.parse(partes[0]);
                        int mes = int.parse(partes[1]);
                        int anio = int.parse(partes[2]);
                        DateTime fechaParaEnviar = DateTime(anio, mes, dia);

                        if (isEditing) {
                          await metodos.actualizarEmbarcacion(
                            embarcacion['id_embarcacion'],
                            nombre: nombreController.text,
                            tipoEmbarcacion: tipoController.text,
                            fechaRegistro: fechaParaEnviar,
                          );
                          if (parentContext.mounted) _mostrarSnackBar(parentContext, "Actualizado correctamente");
                        } else {
                          await metodos.insertarEmbarcacion(
                            nombre: nombreController.text,
                            tipoEmbarcacion: tipoController.text,
                            fechaRegistro: fechaParaEnviar,
                          );
                          if (parentContext.mounted) _mostrarSnackBar(parentContext, "Creado correctamente");
                        }
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      } catch (e) {
                        if (parentContext.mounted) {
                          String errorMsg = e.toString().contains('Format') 
                              ? "Formato de fecha inválido" 
                              : "Error: $e";
                          _mostrarSnackBar(parentContext, errorMsg, isError: true);
                        }
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

            // --- 1. TÍTULO ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.sailing_rounded, color: theme.colorScheme.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Gestión de Embarcaciones", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    Text("Administra la flota registrada en el sistema", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
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
                        hintText: 'Buscar embarcación...',
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
                  
                  // Botón Agregar Estilo "Nuevo"
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () => _showEmbarcacionDialog(context),
                    icon: const Icon(Icons.add), // Icono más simple
                    label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.bold)), // Texto corto
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. TABLA DE DATOS ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: metodos.streamEmbarcaciones(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
                }
                
                if (snapshot.hasError) {
                   return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error)));
                }

                final List<Map<String, dynamic>> allEmbarcaciones = snapshot.data ?? [];
                
                final searchTerm = _searchController.text.toLowerCase();
                final filteredEmbarcaciones = allEmbarcaciones.where((p) {
                  final nombre = p['nombre_embarcacion'].toString().toLowerCase();
                  final tipo = p['tipo_embarcacion'].toString().toLowerCase();
                  return nombre.contains(searchTerm) || tipo.contains(searchTerm);
                }).toList();

                final totalRecords = filteredEmbarcaciones.length;
                final totalPages = (totalRecords / _rowsPerPage).ceil();

                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }

                final startIndex = _currentPage * _rowsPerPage;
                final endIndex = min(startIndex + _rowsPerPage, totalRecords);
                final embarcacionesToShow = (totalRecords > 0) ? filteredEmbarcaciones.sublist(startIndex, endIndex) : [];

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
                              DataColumn(label: Text('Tipo', style: headerStyle)),
                              DataColumn(label: Text('Fecha Registro', style: headerStyle)),
                              DataColumn(label: Text('Acciones', style: headerStyle)),
                            ],
                            rows: embarcacionesToShow.map((embMap) {
                              final tipoColor = _getColorPorTipo(embMap['tipo_embarcacion'] ?? '');
                              
                              return DataRow(cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      Icon(Icons.directions_boat, size: 18, color: theme.colorScheme.primary.withOpacity(0.7)),
                                      const SizedBox(width: 10),
                                      Text(embMap['nombre_embarcacion'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                                    ],
                                  )
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: tipoColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: tipoColor.withOpacity(0.3))
                                    ),
                                    child: Text(
                                      embMap['tipo_embarcacion'] ?? '',
                                      style: TextStyle(color: tipoColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      Icon(Icons.event, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 5),
                                      Text(embMap['fecha_registro'] ?? '', style: cellStyle),
                                    ],
                                  )
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                                        tooltip: "Editar",
                                        onPressed: () => _showEmbarcacionDialog(context, embarcacion: embMap),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                        tooltip: "Eliminar",
                                        onPressed: () async {
                                           final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: theme.colorScheme.surface,
                                              title: const Text('Confirmar Eliminación'),
                                              content: Text('¿Estás seguro de que deseas eliminar la embarcación "${embMap['nombre_embarcacion']}"?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                                  onPressed: () => Navigator.of(ctx).pop(true), 
                                                  child: const Text('Eliminar')
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              await metodos.eliminarEmbarcacionConVerificacion(embMap['id_embarcacion']);
                                              if (context.mounted) _mostrarSnackBar(context, "Embarcación eliminada");
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

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }
    var dateText = _addSlashes(newValue.text);
    return newValue.copyWith(
      text: dateText,
      selection: TextSelection.collapsed(offset: dateText.length),
    );
  }

  String _addSlashes(String text) {
    text = text.replaceAll('/', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != 8) {
        if (nonZeroIndex == 2 || nonZeroIndex == 4) {
             buffer.write('/'); 
        }
      }
    }
    return buffer.toString();
  }
}