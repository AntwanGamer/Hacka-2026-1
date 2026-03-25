import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flutter/services.dart'; // Necesario para inputFormatters
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/reciboBasuronDatabase.dart';
import '../db/reciboBasuronModelo.dart';
import 'package:url_launcher/url_launcher.dart';

class ReciboBasuronView extends StatefulWidget {
  const ReciboBasuronView({super.key});

  @override
  State<ReciboBasuronView> createState() => _ReciboBasuronViewState();
}

class _ReciboBasuronViewState extends State<ReciboBasuronView> {
  int _currentPage = 0;
  final int _rowsPerPage = 8;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = Provider.of<ReciboBasuronDatabase>(context, listen: false);
      db.cargarDatos();
    });
  }

  // --- HELPER PARA MOSTRAR SNACKBAR ---
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = Provider.of<ReciboBasuronDatabase>(context);

    // Lógica de datos
    final allRecibos = db.recibos;
    final searchTerm = _searchController.text.toLowerCase();
    final filtered = allRecibos.where((r) {
      return r.tipoDesecho.toLowerCase().contains(searchTerm);
    }).toList();

    final totalRecords = filtered.length;
    final totalPages = totalRecords == 0 ? 1 : (totalRecords / _rowsPerPage).ceil();
    _currentPage = _currentPage.clamp(0, max(0, totalPages - 1));
    final startIndex = totalRecords == 0 ? 0 : _currentPage * _rowsPerPage;
    final endIndex = totalRecords == 0 ? 0 : min(startIndex + _rowsPerPage, totalRecords);
    final recibosToShow = totalRecords > 0 ? filtered.sublist(startIndex, endIndex) : [];

    final headerStyle = TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 15);
    final cellStyle = TextStyle(color: theme.colorScheme.onSurfaceVariant);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // --- TÍTULO ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: theme.colorScheme.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Recibos de Basurón", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    Text("Gestiona los comprobantes de disposición final", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- BARRA DE HERRAMIENTAS ---
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
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      onChanged: (_) => setState(() => _currentPage = 0),
                      decoration: InputDecoration(
                        hintText: "Buscar por tipo...",
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                    ),
                    onPressed: () => _formulario(context, db),
                    icon: const Icon(Icons.add),
                    label: const Text("Nuevo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- TABLA ---
            Card(
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
                          DataColumn(label: Text("ID", style: headerStyle)),
                          DataColumn(label: Text("Tipo", style: headerStyle)),
                          DataColumn(label: Text("Fecha", style: headerStyle)),
                          DataColumn(label: Text("Cantidad", style: headerStyle)),
                          DataColumn(label: Text("Acciones", style: headerStyle)),
                        ],
                        rows: recibosToShow.map((r) {
                          // Colores para el chip de tipo
                          final isLiquido = r.tipoDesecho.toLowerCase().contains("liquid");
                          final chipColor = isLiquido ? Colors.blue : Colors.brown;

                          // Formateo de fecha para mostrar (si viene YYYY-MM-DD lo muestra bonito)
                          String fechaBonita = r.fechaRecibo;
                          try {
                            DateTime parsed = DateTime.parse(r.fechaRecibo);
                            fechaBonita = "${parsed.day.toString().padLeft(2,'0')}/${parsed.month.toString().padLeft(2,'0')}/${parsed.year}";
                          } catch (e) { /* Fallback */ }

                          return DataRow(
                            cells: [
                              DataCell(Text(r.id.toString(), style: cellStyle)),
                              
                              // Chip de Tipo
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: chipColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: chipColor.withOpacity(0.3))
                                  ),
                                  child: Text(
                                    r.tipoDesecho,
                                    style: TextStyle(
                                      color: chipColor,
                                      fontWeight: FontWeight.bold, 
                                      fontSize: 12
                                    ),
                                  ),
                                ),
                              ),
                              
                              DataCell(
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Text(fechaBonita, style: cellStyle),
                                  ],
                                )
                              ),
                              DataCell(Text("${r.cantidadKg} kg", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                              
                              // ACCIONES
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.image_outlined, size: 20, color: Colors.orange),
                                      tooltip: "Ver Recibo",
                                      onPressed: r.recibo.isEmpty ? null : () => _mostrarImagenDialog(context, r.recibo),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.download_rounded, size: 20, color: Colors.green),
                                      tooltip: "Abrir enlace",
                                      onPressed: r.recibo.isEmpty ? null : () async {
                                        final uri = Uri.parse(r.recibo);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        } else {
                                          if (context.mounted) _mostrarSnackBar(context, "No se pudo abrir el enlace", isError: true);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                                      tooltip: "Editar",
                                      onPressed: () => _formulario(context, db, recibo: r),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                                      tooltip: "Eliminar",
                                      onPressed: () => _confirmarEliminar(context, db, r),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
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
                              color: theme.colorScheme.primary,
                              disabledColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                            ),
                            Text('${_currentPage + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage >= (totalPages - 1) ? null : () => setState(() => _currentPage++),
                              color: theme.colorScheme.primary,
                              disabledColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- DIÁLOGOS ---

  void _mostrarImagenDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(ctx)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, ReciboBasuronDatabase db, ReciboBasuronModelo r) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text("Confirmar eliminación"),
        content: Text("¿Estás seguro de que deseas eliminar este registro?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await db.eliminarRecibo(r);
                if (context.mounted) _mostrarSnackBar(context, "Recibo eliminado correctamente");
              } catch (e) {
                if (context.mounted) _mostrarSnackBar(context, "Error al eliminar: $e", isError: true);
              }
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  // --- FORMULARIO CON FORMATO DD/MM/AAAA ---
  void _formulario(BuildContext context, ReciboBasuronDatabase db, {ReciboBasuronModelo? recibo}) {
    final isEditing = recibo != null;
    final List<String> listaTipos = ["Solido", "Liquido"];
    String? tipoSeleccionado = (isEditing && listaTipos.contains(recibo.tipoDesecho)) ? recibo.tipoDesecho : null;

    final cantidadCtrl = TextEditingController(text: recibo?.cantidadKg.toString() ?? "");
    
    // Convertir fecha YYYY-MM-DD a DD/MM/AAAA para el campo de texto
    String fechaInicial = "";
    if (isEditing && recibo != null) {
      try {
        DateTime dt = DateTime.parse(recibo.fechaRecibo);
        fechaInicial = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
      } catch (e) {
        fechaInicial = "";
      }
    }
    final fechaCtrl = TextEditingController(text: fechaInicial);

    DateTime? selectedDate = recibo != null ? DateTime.tryParse(recibo.fechaRecibo) : null;

    Uint8List? imagenBytes;
    String? nombreImagen;
    String? urlImagenActual = recibo?.recibo;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            
            Future<void> seleccionarImagen() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final bytes = await image.readAsBytes();
                setStateDialog(() {
                  imagenBytes = bytes;
                  nombreImagen = image.name;
                });
              }
            }

            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Icon(isEditing ? Icons.edit_note : Icons.note_add, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(isEditing ? "Editar Recibo" : "Nuevo Recibo", style: TextStyle(color: theme.colorScheme.onSurface)),
                ],
              ),
              content: SizedBox(
                width: 900,
                height: 500,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- COLUMNA 1: DATOS ---
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Información General", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 10),
                            
                            DropdownButtonFormField<String>(
                              value: tipoSeleccionado,
                              dropdownColor: theme.colorScheme.surface,
                              style: TextStyle(color: theme.colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: "Tipo de Desecho",
                                prefixIcon: Icon(Icons.category_outlined, color: theme.colorScheme.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              ),
                              items: listaTipos.map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo))).toList(),
                              onChanged: (val) => setStateDialog(() => tipoSeleccionado = val),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: cantidadCtrl,
                              style: TextStyle(color: theme.colorScheme.onSurface),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                labelText: "Cantidad (kg)",
                                prefixIcon: Icon(Icons.scale_outlined, color: theme.colorScheme.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // CAMPO FECHA CON MÁSCARA AUTOMÁTICA
                            TextFormField(
                              controller: fechaCtrl,
                              style: TextStyle(color: theme.colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: "Fecha de Registro",
                                hintText: "DD/MM/AAAA",
                                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                counterText: "",
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                DateTextFormatter(), // <--- AQUÍ SE APLICA EL FORMATO AUTOMÁTICO
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    VerticalDivider(color: theme.colorScheme.outlineVariant),
                    const SizedBox(width: 20),

                    // --- COLUMNA 2: IMAGEN ---
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Evidencia Fotográfica", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 10),
                          
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outlineVariant, style: BorderStyle.solid),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imagenBytes != null
                                    ? Image.memory(imagenBytes!, fit: BoxFit.contain)
                                    : (urlImagenActual != null && urlImagenActual!.isNotEmpty)
                                        ? Image.network(urlImagenActual!, fit: BoxFit.contain)
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_photo_alternate_outlined, size: 50, color: theme.colorScheme.outline),
                                              const SizedBox(height: 10),
                                              Text("No hay imagen seleccionada", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                                            ],
                                          ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.secondaryContainer,
                                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: seleccionarImagen,
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text("Subir Foto"),
                                ),
                              ),
                              if (imagenBytes != null || (urlImagenActual != null && urlImagenActual!.isNotEmpty)) ...[
                                const SizedBox(width: 10),
                                IconButton.filled(
                                  style: IconButton.styleFrom(backgroundColor: theme.colorScheme.errorContainer),
                                  onPressed: () {
                                    setStateDialog(() {
                                      imagenBytes = null;
                                      urlImagenActual = "";
                                    });
                                  },
                                  icon: Icon(Icons.delete_forever, color: theme.colorScheme.onErrorContainer),
                                  tooltip: "Quitar imagen",
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cancelar", style: TextStyle(color: theme.colorScheme.error)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    if (tipoSeleccionado == null || fechaCtrl.text.isEmpty) {
                      _mostrarSnackBar(context, "Faltan campos obligatorios", isError: true);
                      return;
                    }

                    final currentUser = Supabase.instance.client.auth.currentUser;
                    if (currentUser == null) {
                       _mostrarSnackBar(context, "Error: Usuario no autenticado", isError: true);
                       return;
                    }

                    try {
                      // CONVERTIR DD/MM/AAAA -> DateTime
                      DateTime fechaParaEnviar;
                      try {
                        List<String> parts = fechaCtrl.text.split('/');
                        if (parts.length != 3) throw Exception("Formato invalido");
                        fechaParaEnviar = DateTime(
                          int.parse(parts[2]), // Año
                          int.parse(parts[1]), // Mes
                          int.parse(parts[0])  // Día
                        );
                      } catch (e) {
                        _mostrarSnackBar(context, "Fecha inválida (Use DD/MM/AAAA)", isError: true);
                        return;
                      }

                      String urlFinal = urlImagenActual ?? "";
                      if (imagenBytes != null && nombreImagen != null) {
                        final nuevaUrl = await db.subirImagen(imagenBytes!, nombreImagen!);
                        if (nuevaUrl != null) urlFinal = nuevaUrl;
                      }

                      if (isEditing) {
                        await db.editarRecibo(
                          recibo!,
                          tipoDesecho: tipoSeleccionado!,
                          fechaRecibo: fechaParaEnviar,
                          cantidadKg: int.tryParse(cantidadCtrl.text) ?? 0,
                          recibo: urlFinal,
                        );
                        if (context.mounted) _mostrarSnackBar(context, "Actualizado correctamente");
                      } else {
                        await db.crearRecibo(
                          tipoDesecho: tipoSeleccionado!,
                          fechaRecibo: fechaParaEnviar,
                          cantidadKg: int.tryParse(cantidadCtrl.text) ?? 0,
                          idUsuario: currentUser.id,
                          recibo: urlFinal,
                        );
                        if (context.mounted) _mostrarSnackBar(context, "Creado correctamente");
                      }
                      
                      if (context.mounted) Navigator.pop(ctx);

                    } catch (e) {
                      if (context.mounted) _mostrarSnackBar(context, "Error al guardar: $e", isError: true);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Formateador de Fecha Automático (DD/MM/AAAA)
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