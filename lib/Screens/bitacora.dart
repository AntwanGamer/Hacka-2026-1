import 'package:flutter/material.dart';
import 'dart:math'; 
import 'package:zombie/db/metodosBitacora.dart'; 
import 'package:flutter/services.dart';

class BiotacoraView extends StatefulWidget {
  const BiotacoraView({super.key});

  @override
  State<BiotacoraView> createState() => _BiotacoraView();
}

class _BiotacoraView extends State<BiotacoraView> {
  final MetodosBitacora metodos = MetodosBitacora();

  // Mapas para traducir IDs
  Map<String, String> _nombresUsuarios = {};
  Map<String, String> _nombresBarcos = {};
  Map<String, String> _nombresPersonas = {};

  // Diccionario de nombres bonitos
  final Map<String, String> _diccionarioColumnas = {
    'basura_kg': 'Basura (kg)',
    'aceite_usado_l': 'Aceite (L)',
    'filtro_aceite': 'Filtro Aceite',
    'filtro_diesel': 'Filtro Diesel',
    'filtro_aire': 'Filtro Aire',
    'nombre_embarcacion': 'Embarcación',
    'tipo_embarcacion': 'Tipo',
    'id_embarcacion': 'Barco',
    'id_motorista': 'Maquinista',
    'id_cocinero': 'Cocinero',
    'observacion': 'Observación',
    'fecha_manifiesto': 'Fecha',
    'link_manifiestos_pdf': 'PDF',
    'id_usuario': 'Usuario Modificador',
  };

  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  void _cargarCatalogos() async {
    final usuarios = await metodos.obtenerMapaUsuarios();
    final barcos = await metodos.obtenerMapaEmbarcaciones();
    final personas = await metodos.obtenerMapaPersonas();

    if (mounted) {
      setState(() {
        _nombresUsuarios = usuarios;
        _nombresBarcos = barcos;
        _nombresPersonas = personas;
      });
    }
  }

  // --- HELPER PARA COLOR DE OPERACIÓN ---
  Color _getColorOperacion(String op) {
    switch (op.toUpperCase()) {
      case 'INSERT': return Colors.green;
      case 'UPDATE': return Colors.blue;
      case 'DELETE': return Colors.red;
      default: return Colors.grey;
    }
  }

  // --- LÓGICA DEL POPUP (ESTILIZADO) ---
  void _mostrarDetallesCambio(Map<String, dynamic> row) {
    final theme = Theme.of(context);
    final Map<String, dynamic> anterior = row['registro_anterior'] ?? {};
    final Map<String, dynamic> nuevo = row['registro_nuevo'] ?? {};

    // 1. Obtener llaves relevantes
    List<String> allKeys = {...anterior.keys, ...nuevo.keys}
        .where((k) => k != 'usuario_id' && k != 'created_at' && k != 'id_usuario')
        .toList();

    // 2. Orden deseado
    final List<String> ordenDeseado = [
      'id_manifiesto', 'id', 'id_embarcacion', 'fecha_manifiesto',
      'id_motorista', 'id_cocinero', 'observacion',
      'filtro_diesel', 'filtro_aceite', 'filtro_aire', 'link_manifiestos_pdf',
    ];

    allKeys.sort((a, b) {
      int indexA = ordenDeseado.indexOf(a);
      int indexB = ordenDeseado.indexOf(b);
      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return a.compareTo(b);
    });

    showDialog(
      context: context,
      builder: (context) {
        double gridHeight = (allKeys.length / 3).ceil() * 90.0;
        if (gridHeight > 450) gridHeight = 450;

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          title: Row(
            children: [
              Icon(Icons.history_edu, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text("Detalle de Cambios", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ],
          ),
          content: SizedBox(
            width: 800,
            height: allKeys.isEmpty ? 50 : gridHeight,
            child: allKeys.isEmpty
                ? Center(child: Text("Sin detalles visuales.", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
                : GridView.builder(
                    itemCount: allKeys.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (ctx, i) {
                      final key = allKeys[i];
                      var valAnt = anterior[key];
                      var valNue = nuevo[key];

                      // --- TRADUCCIÓN ---
                      if (key == 'id_embarcacion') {
                        valAnt = _nombresBarcos[valAnt.toString()] ?? valAnt;
                        valNue = _nombresBarcos[valNue.toString()] ?? valNue;
                      } else if (key == 'id_motorista' || key == 'id_cocinero') {
                        valAnt = _nombresPersonas[valAnt.toString()] ?? valAnt;
                        valNue = _nombresPersonas[valNue.toString()] ?? valNue;
                      } else if (key == 'id_usuario') {
                        valAnt = _nombresUsuarios[valAnt.toString()] ?? valAnt;
                        valNue = _nombresUsuarios[valNue.toString()] ?? valNue;
                      }

                      bool cambio = valAnt.toString() != valNue.toString();
                      bool esNuevo = valAnt == null && valNue != null;
                      bool esBorrado = valAnt != null && valNue == null;
                      
                      String titulo = _diccionarioColumnas[key] ?? key.replaceAll('_', ' ').toUpperCase();

                      return Card(
                        elevation: 0,
                        color: cambio ? theme.colorScheme.primaryContainer.withOpacity(0.1) : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: cambio ? theme.colorScheme.primary.withOpacity(0.3) : Colors.transparent
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(titulo, 
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant),
                                maxLines: 1, overflow: TextOverflow.ellipsis
                              ),
                              const SizedBox(height: 2),
                              if (esNuevo)
                                Text("$valNue", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis))
                              else if (esBorrado)
                                Text("$valAnt", style: const TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough, fontSize: 13))
                              else
                                Row(
                                  children: [
                                    if (cambio) ...[
                                      Expanded(child: Text("$valAnt", style: TextStyle(fontSize: 11, color: theme.colorScheme.error, overflow: TextOverflow.ellipsis), maxLines: 1)),
                                      Icon(Icons.arrow_right_alt, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                    ],
                                    Expanded(
                                      flex: 2,
                                      child: Text("$valNue",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cambio ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1),
                                    ),
                                  ],
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text("Cerrar", style: TextStyle(color: theme.colorScheme.primary))
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 15);
    final cellStyle = TextStyle(color: theme.colorScheme.onSurfaceVariant);

    final double headingRowHeight = 56.0;
    final double dataRowHeight = 52.0;

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
                  child: Icon(Icons.history, color: theme.colorScheme.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bitácora de Movimientos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    Text("Historial de cambios y auditoría del sistema", style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
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
                        hintText: 'Buscar por usuario, tabla u operación...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. TABLA ---
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: metodos.streamBitacora(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
                }

                final List<Map<String, dynamic>> allRecords = snapshot.data ?? [];

                // Filtrado
                final searchTerm = _searchController.text.toLowerCase();
                final filteredRecords = allRecords.where((r) {
                  final tabla = (r['nombre_tabla'] ?? '').toString().toLowerCase();
                  final operacion = (r['tipo_operacion'] ?? '').toString().toLowerCase();
                  final nombreUser = (_nombresUsuarios[r['usuario_id'].toString()] ?? '').toLowerCase();
                  return tabla.contains(searchTerm) || operacion.contains(searchTerm) || nombreUser.contains(searchTerm);
                }).toList();

                // Paginación
                final totalRecords = filteredRecords.length;
                final totalPages = (totalRecords / _rowsPerPage).ceil();

                if (_currentPage >= totalPages && totalPages > 0) {
                  _currentPage = totalPages - 1;
                }

                final startIndex = _currentPage * _rowsPerPage;
                final endIndex = min(startIndex + _rowsPerPage, totalRecords);
                final recordsToShow = (totalRecords > 0) ? filteredRecords.sublist(startIndex, endIndex) : [];

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
                            headingRowHeight: headingRowHeight,
                            dataRowMaxHeight: dataRowHeight,
                            horizontalMargin: 20,
                            columnSpacing: 40,
                            headingRowColor: MaterialStateProperty.all(theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                            dividerThickness: 0.5,
                            columns: [
                              DataColumn(label: Text('Fecha', style: headerStyle)),
                              DataColumn(label: Text('Tabla', style: headerStyle)),
                              DataColumn(label: Text('Movimiento', style: headerStyle)),
                              DataColumn(label: Text('Usuario', style: headerStyle)),
                              DataColumn(label: Text('Detalles', style: headerStyle)),
                            ],
                            rows: recordsToShow.map((row) {
                              
                              final fechaRaw = row['fecha_movimiento'].toString().split('.')[0];
                              // Intento de formato bonito de fecha
                              String fecha = fechaRaw;
                              try {
                                final dt = DateTime.parse(row['fecha_movimiento'].toString());
                                fecha = "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2,'0')}";
                              } catch(e) {}

                              final nombreUsuario = _nombresUsuarios[row['usuario_id'].toString()] ?? 'Usuario desconocido';
                              final opColor = _getColorOperacion(row['tipo_operacion'] ?? '');

                              return DataRow(cells: [
                                DataCell(Text(fecha, style: cellStyle)),
                                DataCell(Text(row['nombre_tabla'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                                
                                // Chip de Movimiento
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: opColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: opColor.withOpacity(0.3))
                                    ),
                                    child: Text(
                                      row['tipo_operacion'] ?? '',
                                      style: TextStyle(color: opColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ),
                                ),
                                
                                DataCell(
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 5),
                                      Text(nombreUsuario, style: cellStyle),
                                    ],
                                  )
                                ),
                                
                                // Botón de Detalles (LIMPIO)
                                DataCell(
                                  TextButton.icon(
                                    icon: Icon(Icons.visibility_outlined, size: 18, color: theme.colorScheme.primary),
                                    label: Text("Ver cambios", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                    onPressed: () => _mostrarDetallesCambio(row),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      alignment: Alignment.centerLeft,
                                    ),
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

  // Widget Paginación (Integrado arriba, este ya no se usa pero lo dejo por si acaso prefieres modularizarlo)
  Widget _buildPaginationControls({
    required int totalPages,
    required int totalRecords,
    required int startRecord,
    required int endRecord,
  }) {
    return const SizedBox.shrink(); // Ya está integrado en el Card
  }
}