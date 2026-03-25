import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:zombie/db/metodosManifiestos.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zombie/db/metodosObservaciones.dart';
import 'package:zombie/db/metodosPersonas.dart';
import 'package:zombie/generar_pdf_manifiesto.dart';
import 'package:flutter/services.dart' show rootBundle, FilteringTextInputFormatter, TextInputFormatter;
import 'package:zombie/Screens/embarcaciones.dart' show DateTextFormatter;
import 'package:zombie/db/metodosEmbarcaciones.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:zombie/main.dart';

// Adapter class (Intacto)
class PdfManifiestoAdapter {
  final num aceite;
  final num basura;
  final int filtro_aceite;
  final int filtro_diesel;
  final int filtro_aire;
  final String? observations;

  PdfManifiestoAdapter({
    required this.aceite,
    required this.basura,
    required this.filtro_aceite,
    required this.filtro_diesel,
    required this.filtro_aire,
    this.observations,
  });

  factory PdfManifiestoAdapter.fromMap(Map<String, dynamic> m) {
    num parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      return num.tryParse(v.toString()) ?? 0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? parseNum(v).toInt();
    }

    return PdfManifiestoAdapter(
      aceite: parseNum(m['aceite'] ?? m['aceite_usado_l'] ?? m['aceite_usado_litros'] ?? 0),
      basura: parseNum(m['basura'] ?? m['basura_kg'] ?? 0),
      filtro_aceite: parseInt(m['filtro_aceite'] ?? m['filtros_aceite'] ?? m['filtros_aceite_unidades'] ?? 0),
      filtro_diesel: parseInt(m['filtro_diesel'] ?? m['filtros_diesel'] ?? 0),
      filtro_aire: parseInt(m['filtro_aire'] ?? m['filtros_aire'] ?? 0),
      observations: (m['observations'] ?? m['observaciones'])?.toString(),
    );
  }
}

class ManifiestosView extends StatefulWidget {
  const ManifiestosView({super.key});

  @override
  State<ManifiestosView> createState() => _ManifiestosViewState();
}

class _ManifiestosViewState extends State<ManifiestosView> {
  // Controllers
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController aceiteUsadoController = TextEditingController();
  final TextEditingController basuraController = TextEditingController();
  final TextEditingController filtrosAceiteController = TextEditingController();
  final TextEditingController filtrosDieselController = TextEditingController();
  final TextEditingController filtrosAireController = TextEditingController();
  final TextEditingController observacionesController = TextEditingController();
  final TextEditingController nombreBarcoContrller = TextEditingController();
  final TextEditingController motoristaController = TextEditingController();
  final TextEditingController cocineroController = TextEditingController();
  final TextEditingController primerOficialControler = TextEditingController();

  // State flags
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  bool _isUploading = false;
  bool agregandoPDFdesdeTabla = false;
  bool primeraVezEntrandoPagina = true;
  bool agregarManifiesto = false;
  
  // Helpers
  final MetodosEmbarcaciones metodosEmbarcaciones = MetodosEmbarcaciones();
  final MetodosPersonas metodosPersonas = MetodosPersonas();
  final MetodosManifiestos metodos = MetodosManifiestos();
  final MetodosObservaciones metodosObservaciones = MetodosObservaciones();
  
  int? _selectedMotoristaId;
  int? _selectedCocineroId;
  int? _selectedEmbarcacionId;

  // PDF & Files logic
  bool pdfCargadoDesdeSupa = false;
  bool pdfEliminadoDelSupa = false;
  Uint8List? _pdfCache;
  String? linkManifiestoSellado_supabase;
  PlatformFile? linkManifiestoSellado_pc;
  String nombreArchivoPDF = '';

  Map<String, dynamic>? manifiestoParaActualizar;
  
  // Search & Pagination
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _rowsPerPage = 8;
  bool cargarNombresEmbarcacionesEnTabla = true;

  @override
  void dispose() {
    fechaController.dispose();
    aceiteUsadoController.dispose();
    basuraController.dispose();
    filtrosAceiteController.dispose();
    filtrosDieselController.dispose();
    filtrosAireController.dispose();
    observacionesController.dispose();
    nombreBarcoContrller.dispose();
    motoristaController.dispose();
    cocineroController.dispose();
    primerOficialControler.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- HELPER PARA SNACKBAR ESTILIZADO ---
  void _mostrarSnackBar(BuildContext context, String mensaje, {bool isError = false}) {
    final theme = Theme.of(context);
    final bgColor = isError ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer;
    final contentColor = isError ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: contentColor),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje, style: TextStyle(color: contentColor, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void reiniciarCampos() {
    pdfEliminadoDelSupa = false;
    fechaController.clear();
    aceiteUsadoController.clear();
    basuraController.clear();
    filtrosAceiteController.clear();
    filtrosDieselController.clear();
    filtrosAireController.clear();
    observacionesController.clear();
    nombreBarcoContrller.clear();
    motoristaController.clear();
    cocineroController.clear();
    primerOficialControler.clear();
    linkManifiestoSellado_pc = null;
    linkManifiestoSellado_supabase = null;
    nombreArchivoPDF = '';
    _selectedEmbarcacionId = null;
    _selectedMotoristaId = null;
    _selectedCocineroId = null;
  }

  // -----------------------------------------------------------
  // WIDGETS ESTILO "PAPEL BLANCO" (Tus originales)
  // -----------------------------------------------------------
  Widget _manifiestoPaper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white, // SIEMPRE BLANCO
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _manifestField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    String? initialValue,
    bool isLargeText = false,
    bool isDate = false,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.black54, // SIEMPRE NEGRO SUAVE
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextFormField(
            initialValue: initialValue,
            controller: controller,
            onChanged: onChanged,
            readOnly: false,
            decoration: InputDecoration(
              labelText: isDate ? 'Fecha de Registro' : null,
              hintText: isDate ? 'DD/MM/AAAA' : null,
              counterText: isDate ? "" : null,
              suffixIcon: isDate 
                ? const Icon(Icons.calendar_today, color: Colors.black54, size: 18)
                : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
              border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black87, width: 1.5)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black87, width: 1.5)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 2)),
              labelStyle: const TextStyle(color: Colors.black54),
              hintStyle: const TextStyle(color: Colors.black38),
            ),
            keyboardType: isDate ? TextInputType.number : TextInputType.text,
            maxLength: isDate ? 10 : null,
            inputFormatters: isDate
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    DateTextFormatter(),
                  ]
                : null,
            style: TextStyle(
              color: Colors.black, // SIEMPRE NEGRO
              fontSize: isLargeText ? 18 : 16,
              fontWeight: isLargeText ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _manifestInputRow({
    required String label,
    required TextEditingController controller,
    required String unit,
    String? initialValue,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              initialValue: initialValue,
              onChanged: onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: const TextStyle(color: Colors.black26),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                isDense: true,
                border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
                enabledBorder:  OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)), // Borde gris
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 2)),
              ),
              style: const TextStyle(color: Colors.black, fontSize: 16), // SIEMPRE NEGRO
            ),
          ),
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(unit, style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // --- BUILD PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    if (primeraVezEntrandoPagina) {
      unawaited(_generarPdfEnBackgroundInicial());
      unawaited(descargarSoloPdf());
      primeraVezEntrandoPagina = false;
    }
    
    if (cargarNombresEmbarcacionesEnTabla) {
      cargarNombresEmbarcacionesEnTabla = false;
    }

    final theme = Theme.of(context);

    if (agregarManifiesto) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: _buildFormulario(theme),
      );
    } else {
      reiniciarCampos();
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: _buildTablaView(theme),
      );
    }
  }

  // VISTA 1: TABLA DE MANIFIESTOS (Estilo Premium)
  Widget _buildTablaView(ThemeData theme) {
    final headerStyle = TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 15);
    final cellStyle = TextStyle(color: theme.colorScheme.onSurfaceVariant);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description_rounded, color: theme.colorScheme.onPrimaryContainer, size: 28),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Gestión de Manifiestos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  Text("Administra manifiestos de entrega de residuos", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    onChanged: (val) => setState(() => _currentPage = 0),
                    decoration: InputDecoration(
                      hintText: 'Buscar por embarcación o fecha...',
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
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    setState(() {
                      manifiestoParaActualizar = null;
                      agregarManifiesto = true;
                      agregandoPDFdesdeTabla = false;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: metodos.streamManifiestosConNombreEmbarcaciones(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error)));
              }
              final List<Map<String, dynamic>> allManifiestos = snapshot.data ?? [];
              final searchTerm = _searchController.text.toLowerCase();
              final filteredManifiestos = allManifiestos.where((p) {
                final nombre = (p['nombre_embarcacion'] ?? '').toString().toLowerCase();
                final idStr = (p['id_embarcacion'] ?? '').toString().toLowerCase();
                final fecha = (p['fecha_manifiesto'] ?? '').toString().toLowerCase();
                return nombre.contains(searchTerm) || idStr.contains(searchTerm) || fecha.contains(searchTerm);
              }).toList();
              final totalRecords = filteredManifiestos.length;
              final totalPages = (totalRecords / _rowsPerPage).ceil();
              if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
              final startIndex = _currentPage * _rowsPerPage;
              final endIndex = min(startIndex + _rowsPerPage, totalRecords);
              final manifiestosToShow = (totalRecords > 0) ? filteredManifiestos.sublist(startIndex, endIndex) : [];

              return Card(
                elevation: 0,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant)),
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
                          columnSpacing: 30,
                          headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                          dividerThickness: 0.5,
                          columns: [
                            DataColumn(label: Text('#', style: headerStyle)),
                            DataColumn(label: Text('Embarcación', style: headerStyle)),
                            DataColumn(label: Text('Fecha', style: headerStyle)),
                            DataColumn(label: Text('Aceite (L)', style: headerStyle)),
                            DataColumn(label: Text('Basura (kg)', style: headerStyle)),
                            //DataColumn(label: Text('PDF', style: headerStyle)),
                            DataColumn(label: Text('Acciones', style: headerStyle)),
                          ],
                          rows: manifiestosToShow.map((mMap) {
                            String fechaBonita = mMap['fecha_manifiesto'] ?? '';
                            try {
                              DateTime dt = DateTime.parse(fechaBonita);
                              fechaBonita = "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}";
                            } catch(e){}
                            return DataRow(cells: [
                              DataCell(Text((mMap['id_manifiesto'] ?? '').toString(), style: cellStyle)),
                              DataCell(Row(children: [
                                CircleAvatar(radius: 14, backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Icon(Icons.directions_boat, size: 14, color: theme.colorScheme.primary)),
                                const SizedBox(width: 8),
                                Text(mMap['nombre_embarcacion'] ?? (mMap['id_embarcacion'] ?? '').toString(), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                              ])),
                              DataCell(Row(children: [
                                Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary.withOpacity(0.7)),
                                const SizedBox(width: 6),
                                Text(fechaBonita, style: cellStyle),
                              ])),
                              DataCell(Text((mMap['aceite_usado_l'] ?? '0').toString(), style: cellStyle)),
                              DataCell(Text((mMap['basura_kg'] ?? '0').toString(), style: cellStyle)),
                              /*DataCell(
                                (mMap['link_manifiestos_pdf'] != null)
                                ? IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), tooltip: "Ver PDF", onPressed: () => verPDF(mMap['link_manifiestos_pdf']))
                                : IconButton(icon: const Icon(Icons.upload_file, color: Colors.orange), tooltip: "Subir PDF", onPressed: () { agregandoPDFdesdeTabla = true; _ShowDialogAgregarManifiesto(context, mMap['id_manifiesto']); })
                              ),*/
                              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                (mMap['link_manifiestos_pdf'] != null)
                                ? IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), tooltip: "Ver PDF", onPressed: () => verPDF(mMap['link_manifiestos_pdf']))
                                : IconButton(icon: const Icon(Icons.upload_file, color: Colors.orange), tooltip: "Subir PDF", onPressed: () { agregandoPDFdesdeTabla = true; _ShowDialogAgregarManifiesto(context, mMap['id_manifiesto']); }),
                                const SizedBox(width: 8),
                                IconButton(icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary), tooltip: "Editar", onPressed: () async { setState(() { manifiestoParaActualizar = mMap; agregarManifiesto = true; }); _llenarControladoresParaEditar(mMap); },),
                                const SizedBox(width: 8),
                                IconButton(icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error), tooltip: "Eliminar", onPressed: () async { _confirmarEliminacion(mMap); }),
                              ])),
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
                          Text('${startIndex + 1}-${endIndex} de $totalRecords registros', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _currentPage == 0 ? null : () => setState(() => _currentPage--), color: theme.colorScheme.primary, disabledColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                              Text('${_currentPage + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _currentPage >= (totalPages - 1) ? null : () => setState(() => _currentPage++), color: theme.colorScheme.primary, disabledColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
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
    );
  }

  // VISTA 2: FORMULARIO (ESTILO PAPEL BLANCO)
  Widget _buildFormulario(ThemeData theme) {
    final isEditing = manifiestoParaActualizar != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: theme.colorScheme.surfaceContainerHighest),
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () {
                  setState(() {
                    agregarManifiesto = false;
                    cargarNombresEmbarcacionesEnTabla = true;
                  });
                },
              ),
              const SizedBox(width: 16),
              Text(
                isEditing ? "Editar Manifiesto" : "Nuevo Manifiesto",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const Spacer(),
              if (linkManifiestoSellado_pc != null)
                Chip(
                  avatar: const Icon(Icons.attach_file, size: 16),
                  label: Text("PDF Seleccionado: ${linkManifiestoSellado_pc!.name}"),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FORMULARIO GRANDE (IZQUIERDA)
              Expanded(
                flex: 3,
                child: _manifiestoPaper(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: Text('Coordinación General de Puertos y Marina Mercante', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                      const Center(child: Text('Dirección General de Marina Mercante', style: TextStyle(color: Colors.black54, fontSize: 12))),
                      const Divider(height: 30, color: Colors.black26),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildBarcoAutocomplete(theme)), 
                          const SizedBox(width: 20),
                          Expanded(
                            child: _manifestField(
                              context: context,
                              label: "Fecha",
                              isDate: true,
                              controller: fechaController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text("ENTREGA DE RESIDUOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                      const Divider(color: Colors.black26),
                      _manifestInputRow(label: "Aceite Usado", controller: aceiteUsadoController, unit: "Litros"),
                      _manifestInputRow(label: "Basura", controller: basuraController, unit: "Kg"),
                      _manifestInputRow(label: "Filtros Aceite", controller: filtrosAceiteController, unit: "Unidades"),
                      _manifestInputRow(label: "Filtros Diésel", controller: filtrosDieselController, unit: "Unidades"),
                      _manifestInputRow(label: "Filtros Aire", controller: filtrosAireController, unit: "Unidades"),
                      const SizedBox(height: 30),
                      const Text("OBSERVACIONES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                      const Divider(color: Colors.black26),
                      _manifestField(context: context, label: "AGREGUE AQUÍ SUS OBSERVACIONES...", controller: observacionesController, isLargeText: true),
                      const SizedBox(height: 30),
                      const Text("RESPONSABLES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                      const Divider(color: Colors.black26),
                      Row(
                        children: [
                          Expanded(child: _buildPersonaAutocomplete(theme, "Motorista", motoristaController, (id) => _selectedMotoristaId = id)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildPersonaAutocomplete(theme, "Cocinero", cocineroController, (id) => _selectedCocineroId = id)),
                        ],
                      ),
                      
                      const SizedBox(height: 40),

                      // BOTÓN GUARDAR (DENTRO DEL FORMULARIO PARA QUE HAYA QUE SCROLLEAR)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _guardarManifiesto,
                          icon: const Icon(Icons.save),
                          label: Text(isEditing ? "ACTUALIZAR MANIFIESTO" : "GUARDAR MANIFIESTO"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary, // Verde DCK
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // AREA DE ARCHIVOS (DERECHA)
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _uploadExcelArea(context),
                    const SizedBox(height: 20),
                    if (_isGeneratingPdf) 
                      CircularProgressIndicator(color: theme.colorScheme.primary)
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              await _generarPdfEnBackgroundInicial();
                              await descargarSoloPdf();
                            } catch (e) {
                              _mostrarSnackBar(context, "Error al descargar PDF: $e", isError: true);
                            }
                          },
                          icon: Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
                          label: Text("Previsualizar / Descargar PDF", style: TextStyle(color: theme.colorScheme.primary)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), side: BorderSide(color: theme.colorScheme.primary)),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (isEditing && pdfCargadoDesdeSupa && !pdfEliminadoDelSupa) ...[
                      Card(
                        color: theme.colorScheme.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text("Archivo Actual en Sistema", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => verPDF(nombreArchivoPDF),
                                    icon: const Icon(Icons.visibility),
                                    label: const Text("Ver"),
                                    style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                                  ),
                                  FilledButton.icon(
                                    onPressed: eliminarPDF_temporalmente,
                                    icon: const Icon(Icons.delete),
                                    label: const Text("Eliminar"),
                                    style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- AUTOCOMPLETES FORZADOS A NEGRO SOBRE BLANCO ---
  Widget _buildBarcoAutocomplete(ThemeData theme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: metodosEmbarcaciones.streamEmbarcaciones(),
      builder: (context, snapshot) {
        final lista = snapshot.data ?? [];
        final opciones = lista.map((e) {
          final idVal = e['id_embarcacion'];
          final nombreVal = e['nombre_embarcacion']?.toString() ?? '';
          return {'id': idVal, 'nombre': nombreVal};
        }).toList();

        return Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return opciones.map((o) => o['nombre'] as String);
            return opciones.where((o) => (o['nombre'] as String).toLowerCase().contains(textEditingValue.text.toLowerCase())).map((o) => o['nombre'] as String);
          },
          onSelected: (selection) {
            nombreBarcoContrller.text = selection;
            final match = opciones.firstWhere((o) => o['nombre'] == selection, orElse: () => {'id': null});
            if (match['id'] != null) _selectedEmbarcacionId = int.parse(match['id'].toString());
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            if (nombreBarcoContrller.text.isNotEmpty && textController.text.isEmpty) textController.text = nombreBarcoContrller.text;
            textController.addListener(() => nombreBarcoContrller.text = textController.text);

            return TextField(
              controller: textController,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.black), 
              decoration: const InputDecoration(
                labelText: "Nombre de Embarcación",
                labelStyle: TextStyle(color: Colors.black54),
                prefixIcon: Icon(Icons.directions_boat, color: Colors.black54),
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 2)),
                filled: true,
                fillColor: Colors.white,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: Colors.white, // Fondo blanco para las opciones
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option, style: const TextStyle(color: Colors.black)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPersonaAutocomplete(ThemeData theme, String label, TextEditingController controller, Function(int) onSelectId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: metodosPersonas.streamPersonas(),
      builder: (context, snapshot) {
        final lista = snapshot.data ?? [];
        final opciones = lista.map((e) {
          final idVal = e['id_personas'];
          final nombreVal = e['nombre']?.toString() ?? '';
          return {'id': idVal, 'nombre': nombreVal};
        }).toList();

        return Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return opciones.map((o) => o['nombre'] as String);
            return opciones.where((o) => (o['nombre'] as String).toLowerCase().contains(textEditingValue.text.toLowerCase())).map((o) => o['nombre'] as String);
          },
          onSelected: (selection) {
            controller.text = selection;
            final match = opciones.firstWhere((o) => o['nombre'] == selection, orElse: () => {'id': null});
            if (match['id'] != null) onSelectId(int.parse(match['id'].toString()));
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
             if (controller.text.isNotEmpty && textController.text.isEmpty) textController.text = controller.text;
            textController.addListener(() => controller.text = textController.text);

            return TextField(
              controller: textController,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.person_outline, color: Colors.black54),
                border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black26)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 2)),
                filled: true,
                fillColor: Colors.white, // SIEMPRE BLANCO
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: Colors.white,
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option, style: const TextStyle(color: Colors.black)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _uploadExcelArea(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async { await pickPDF(); },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 60, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(linkManifiestoSellado_pc != null ? "Archivo Seleccionado" : "Clic para subir PDF escaneado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            if (linkManifiestoSellado_pc != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Chip(
                  label: Text(linkManifiestoSellado_pc!.name),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  onDeleted: () { setState(() { linkManifiestoSellado_pc = null; }); },
                ),
              )
            else
               Text("Solo archivos .pdf", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE NEGOCIO ---
  Future<void> pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null && result.files.single.path != null) {
          linkManifiestoSellado_pc = result.files.single;
          nombreArchivoPDF = metodos.ArreglarNombreArchivo(linkManifiestoSellado_pc!.name);
          pdfEliminadoDelSupa = true; 
          if (agregandoPDFdesdeTabla != true)
          {
            setState(() {
            });
          }
        _mostrarSnackBar(context, 'Archivo seleccionado: ${linkManifiestoSellado_pc!.name}');
      }
    } catch (e) {
      _mostrarSnackBar(context, "Error seleccionando archivo: $e", isError: true);
    }
  }

  void _llenarControladoresParaEditar(Map<String, dynamic> mMap) async {
    nombreBarcoContrller.text = mMap['nombre_embarcacion'] ?? ''; 
    try {
      DateTime dt = DateTime.parse(mMap['fecha_manifiesto']);
      fechaController.text = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    } catch (e) { fechaController.text = ''; }

    aceiteUsadoController.text = (mMap['aceite_usado_l'] ?? '').toString();
    basuraController.text = (mMap['basura_kg'] ?? '').toString();
    filtrosAceiteController.text = (mMap['filtro_aceite'] ?? '').toString();
    filtrosDieselController.text = (mMap['filtro_diesel'] ?? '').toString();
    filtrosAireController.text = (mMap['filtro_aire'] ?? '').toString();
    observacionesController.text = (mMap['observacion'] ?? '').toString();
    
    _selectedEmbarcacionId = mMap['id_embarcacion'];
    _selectedMotoristaId = mMap['id_motorista'];
    _selectedCocineroId = mMap['id_cocinero'];

    // Obtener nombres de motorista y cocinero basándose en sus IDs
    try {
      final personas = await metodosPersonas.streamPersonas().first;
      
      // Buscar y asignar motorista
      if (_selectedMotoristaId != null) {
        final motorista = personas.firstWhere(
          (p) => (p['id_personas'] ?? p['id'] ?? p['id_persona']) == _selectedMotoristaId,
          orElse: () => {},
        );
        motoristaController.text = motorista['nombre']?.toString() ?? '';
      } else {
        motoristaController.text = '';
      }
      
      // Buscar y asignar cocinero
      if (_selectedCocineroId != null) {
        final cocinero = personas.firstWhere(
          (p) => (p['id_personas'] ?? p['id'] ?? p['id_persona']) == _selectedCocineroId,
          orElse: () => {},
        );
        cocineroController.text = cocinero['nombre']?.toString() ?? '';
      } else {
        cocineroController.text = '';
      }
    } catch (e) {
      print('Error al cargar nombres de personas: $e');
      motoristaController.text = '';
      cocineroController.text = '';
    }

    setState(() {
      nombreArchivoPDF = mMap['link_manifiestos_pdf'] ?? '';
      pdfCargadoDesdeSupa = nombreArchivoPDF.isNotEmpty;
      pdfEliminadoDelSupa = false;
      linkManifiestoSellado_pc = null;     
    });
  }

  // --- LAS FUNCIONES INSERTAR Y ACTUALIZAR QUE FALTABAN ---
  Future<void> _insertarManifiesto(DateTime fechaParaEnviar, String? uid) async {
    String? finalNombreArchivoPDF = nombreArchivoPDF;
    if (linkManifiestoSellado_pc != null) {
       try {
         finalNombreArchivoPDF = metodos.ArreglarNombreArchivo(nombreArchivoPDF);
         await metodos.uploadPDF(finalNombreArchivoPDF, linkManifiestoSellado_pc!);
       } catch (e) {
         if (e.toString().contains('ya existe')) {
           _mostrarSnackBar(context, "El archivo ya existe, cámbiale el nombre.", isError: true);
           throw Exception("Archivo duplicado");
         }
       }
    } else if (pdfEliminadoDelSupa) {
       finalNombreArchivoPDF = null;
    }
    
    if (finalNombreArchivoPDF != null && finalNombreArchivoPDF.isEmpty) finalNombreArchivoPDF = null;

    await metodos.insertarManifiesto(
      idEmbarcacion: _selectedEmbarcacionId ?? int.tryParse(nombreBarcoContrller.text) ?? 0,
      fechaManifiesto: fechaParaEnviar,
      aceiteUsadoLitros: double.tryParse(aceiteUsadoController.text) ?? 0.0,
      basuraKg: double.tryParse(basuraController.text) ?? 0.0,
      filtrosAceite: int.tryParse(filtrosAceiteController.text) ?? 0,
      filtrosDiesel: int.tryParse(filtrosDieselController.text) ?? 0,
      filtrosAire: int.tryParse(filtrosAireController.text) ?? 0,
      idMotorista: _selectedMotoristaId ?? int.tryParse(motoristaController.text) ?? 0,
      idCocinero: _selectedCocineroId ?? int.tryParse(cocineroController.text) ?? 0,
      linkManifiestoSellado: finalNombreArchivoPDF,
      observacion: observacionesController.text,
      idUsuario: uid
    );
  }

  Future<void> _actualizarManifiesto(DateTime fechaParaEnviar, String? uid) async {
    String? nombreArchivoPDF_supabase;
    if (pdfEliminadoDelSupa && pdfCargadoDesdeSupa) {          
      metodos.eliminarPDF(manifiestoParaActualizar!['link_manifiestos_pdf'], manifiestoParaActualizar!['id_manifiesto']);
      pdfCargadoDesdeSupa = false;
    }                                  
    
    if (pdfCargadoDesdeSupa) {
      nombreArchivoPDF_supabase = manifiestoParaActualizar!['link_manifiestos_pdf'];
    } else if (linkManifiestoSellado_pc != null) {
      try {
        nombreArchivoPDF_supabase = metodos.ArreglarNombreArchivo(linkManifiestoSellado_pc!.name);    
        await metodos.uploadPDF(nombreArchivoPDF, linkManifiestoSellado_pc!);
        setState(() {
          linkManifiestoSellado_pc = null;
          pdfEliminadoDelSupa = false;
          pdfCargadoDesdeSupa = true;
        });
      } catch (e) {
        if (e.toString().contains('ya existe')) {
           _mostrarSnackBar(context, "El archivo ya existe.", isError: true);
           throw Exception("Archivo duplicado");
        }
        rethrow;
      }
    }

    String? finalNombreArchivoPDF = nombreArchivoPDF_supabase;
    if (nombreArchivoPDF.isEmpty || nombreArchivoPDF_supabase == '') {
      finalNombreArchivoPDF = null;
    }

    await metodos.actualizarManifiesto(
      manifiestoParaActualizar!['id_manifiesto'],
      idEmbarcacion: _selectedEmbarcacionId!, 
      fechaManifiesto: fechaParaEnviar, 
      aceiteUsadoLitros: double.tryParse(aceiteUsadoController.text) ?? 0.0,
      basuraKg: double.tryParse(basuraController.text) ?? 0.0,
      filtrosAceite: int.tryParse(filtrosAceiteController.text) ?? 0,
      filtrosDiesel: int.tryParse(filtrosDieselController.text) ?? 0,
      filtrosAire: int.tryParse(filtrosAireController.text) ?? 0,
      idMotorista: _selectedMotoristaId ?? int.tryParse(motoristaController.text) ?? 0,
      idCocinero: _selectedCocineroId ?? int.tryParse(cocineroController.text) ?? 0,
      linkManifiestoSellado: finalNombreArchivoPDF,
      observacion: observacionesController.text,
      idUsuario: uid
    );
  }

  Future<void> _guardarManifiesto() async {
    String errorMsg = '';
    if (fechaController.text.isEmpty) errorMsg += "• Fecha requerida\n";
    if (nombreBarcoContrller.text.isEmpty) errorMsg += "• Embarcación requerida\n";
    
    if (errorMsg.isNotEmpty) {
      _mostrarSnackBar(context, "Faltan datos:\n$errorMsg", isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<String> partes = fechaController.text.split('/');
      DateTime fechaParaEnviar = DateTime(int.parse(partes[2]), int.parse(partes[1]), int.parse(partes[0]));
      
      final User? user = Supabase.instance.client.auth.currentUser;
      final uid = user?.id;

      if (manifiestoParaActualizar != null) {
        await _actualizarManifiesto(fechaParaEnviar, uid);
        _mostrarSnackBar(context, "Manifiesto actualizado correctamente");
      } else {
        await _insertarManifiesto(fechaParaEnviar, uid);
        _mostrarSnackBar(context, "Manifiesto creado correctamente");
      }

      setState(() {
        agregarManifiesto = false;
        cargarNombresEmbarcacionesEnTabla = true;
      });

    } catch (e) {
      _mostrarSnackBar(context, "Error al guardar: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _generarPdfEnBackgroundInicial() async {
    if (_isGeneratingPdf) return;
    if (!mounted) return;
    setState(() => _isGeneratingPdf = true);
    try {
      final manifiesto = {
          'aceite': aceiteUsadoController.text,
          'basura': basuraController.text,
          'filtro_aceite': filtrosAceiteController.text,
          'filtro_diesel': filtrosDieselController.text,
          'filtro_aire': filtrosAireController.text,
          'observations': observacionesController.text,
        };
      String? svgContent;
      try {
        svgContent = await rootBundle.loadString('lib/assets/sello.svg');
      } catch (e) {
        try {
          svgContent = await rootBundle.loadString('assets/sello.svg');
        } catch (e2) {
          svgContent = null;
        }
      }
      List<String> partes = fechaController.text.split('/');
      DateTime fechaParaEnviar;
      if (fechaController.text.isEmpty) {
        fechaParaEnviar = DateTime.now();
      } else {
        int dia = int.parse(partes[0]);
        int mes = int.parse(partes[1]);
        int anio = int.parse(partes[2]);
        fechaParaEnviar = DateTime(anio, mes, dia);
      }
      final datos = {
        'svg': svgContent,
        'fechaDocumento': fechaParaEnviar,
        'barco': nombreBarcoContrller.text,
        'maquinista': motoristaController.text,
        'cocinero': cocineroController.text,
        'manifiesto': manifiesto,
      };
      final bytes = await compute(_isolateGenerarPdf, datos);
      if (mounted) {
        setState(() {
          _pdfCache = bytes;
          _isGeneratingPdf = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> descargarSoloPdf() async {
    if (_pdfCache == null) return;
    if (!mounted) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final fileName = "${twoDigits(now.month)}-${twoDigits(now.day)}-${now.year.toString().substring(2)}_${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}_ManifiestoDeBarco.pdf";
      final completer = Completer<void>();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          if (!completer.isCompleted) completer.complete();
          return;
        }
        _doSharePdf(completer, fileName);
      });
      await completer.future;
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _doSharePdf(Completer<void> completer, String fileName) {
    unawaited(
      (() async {
        try {
          if (_pdfCache != null) {
            await Printing.sharePdf(bytes: _pdfCache!, filename: fileName);
            if (mounted) _mostrarSnackBar(context, "PDF descargado");
          }
        } catch (e, st) {
          if (mounted) _mostrarSnackBar(context, 'Error al compartir PDF: $e', isError: true);
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      })(),
    );
  }

  Future<Uint8List> _isolateGenerarPdf(Map<String, dynamic> params) async {
    final svgString = params['svg'] as String?;
    final mData = params['manifiesto'] as Map<String, dynamic>;
    final manifiestoObj = PdfManifiestoAdapter.fromMap(mData);
    return await PdfGenerator.generarPdfBytes(
      m: manifiestoObj,
      nombreBarco: params['barco'] ?? '',
      nombreMaquinista: params['maquinista'] ?? '',
      nombreCocinero: params['cocinero'] ?? '',
      svgEscudoString: svgString,
      fechaDocumento: params['fechaDocumento'] ?? DateTime.now(),
    );
  }

  void verPDF(String link) async {
    String? urlPDF = await metodos.obtenerUrlVisualizacion(link);
    if (urlPDF != null) {
      final uri = Uri.parse(urlPDF);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    } else {
      _mostrarSnackBar(context, "No se pudo obtener el enlace", isError: true);
    }
  }

  void _confirmarEliminacion(Map<String, dynamic> mMap) async {
     final theme = Theme.of(context);
     final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro? Se borrará el manifiesto y su PDF.'),
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
        await metodos.eliminarManifiesto(mMap['id_manifiesto'], mMap['link_manifiestos_pdf'] ?? '');
        if (context.mounted) _mostrarSnackBar(context, "Eliminado correctamente");
      } catch (e) {
        if (context.mounted) _mostrarSnackBar(context, "Error: $e", isError: true);
      }
    }
  }
  
  Future<void> _ShowDialogAgregarManifiesto(BuildContext context, int idManifiesto) async {
    agregandoPDFdesdeTabla = true;
    reiniciarCampos();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Cargar Documento de Manifiesto', style: TextStyle(color: theme.colorScheme.onSurface)),
          content: StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 500,
                          child: _uploadExcelArea(context),
                        ),
                      ],
                    ),
                  ),
                  if (_isUploading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                         child: CircularProgressIndicator(color: theme.colorScheme.primary),
                      ),
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : () {
                agregandoPDFdesdeTabla = false;
                Navigator.of(context).pop();
              },
              child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.error)),
            ),
            FilledButton.icon(
                style: FilledButton.styleFrom(
                   backgroundColor: theme.colorScheme.primary,
                   foregroundColor: theme.colorScheme.onPrimary
                ),
                onPressed: _isUploading ? null : () async {
                  if (linkManifiestoSellado_pc != null) {
                    setState(() => _isUploading = true);
                    try {
                      await metodos.actualizarPDF(
                        idManifiesto,
                        nombreArchivoPDF: nombreArchivoPDF,
                        linkManifiestoSellado: linkManifiestoSellado_pc!,
                      );
                      if (mounted) {
                        agregandoPDFdesdeTabla = false;
                         setState(() {
                           linkManifiestoSellado_pc = null;
                           nombreArchivoPDF = '';
                         });
                        Navigator.of(context).pop();
                        _mostrarSnackBar(context, 'Documento guardado correctamente');
                      }
                    } catch (e) {
                       if (mounted) _mostrarSnackBar(context, 'Error al subir el PDF: $e', isError: true);
                    } finally {
                      if (mounted) setState(() => _isUploading = false);
                    }
                  } else {
                    _mostrarSnackBar(context, "Seleccione un archivo primero.", isError: true);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
  
  void eliminarPDF_temporalmente() {
     setState(() {
       pdfEliminadoDelSupa = true;
       nombreArchivoPDF = '';
     });
     _mostrarSnackBar(context, "PDF marcado para eliminación. Guarde para confirmar.");
  }
}