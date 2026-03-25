import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zombie/db/metodosAsociacionesRecolectoras.dart';

// --- 1. Modelo de Datos ---
class Asociacion {
  final int id;
  String nombre;
  String tipo;
  String contacto;
  final String creado;
  String actualizado;

  Asociacion({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.contacto,
    required this.creado,
    required this.actualizado,
  });
}

// --- 2. Provider conectado a Supabase ---
class AsociacionesDatabase extends ChangeNotifier {
  final _metodos = MetodosAsociacionesRecolectoras();

  List<Asociacion> asociaciones = [];

  void iniciarStream() {
    _metodos.streamAsociaciones().listen((data) {
      asociaciones = data.map((row) {
        return Asociacion(
          id: row['id'],
          nombre: row['nombre_asociacion'] ?? '',
          tipo: row['tipo_asociacion'] ?? '',
          contacto: row['contacto_asociacion'] ?? '',
          creado: "N/A",
          actualizado: "N/A",
        );
      }).toList();
      notifyListeners();
    });
  }

  Future<void> crearAsociacion(
    String nombre,
    String tipo,
    String contacto,
  ) async {
    await _metodos.insertarAsociacion(
      nombre: nombre,
      tipoAsociacion: tipo,
      contacto: contacto,
    );
  }

  Future<void> editarAsociacion(
    Asociacion a,
    String nombre,
    String tipo,
    String contacto,
  ) async {
    await _metodos.actualizarAsociacion(
      a.id,
      nombre: nombre,
      tipoAsociacion: tipo,
      contacto: contacto,
    );
  }

  Future<void> eliminarAsociacion(Asociacion a) async {
    await _metodos.eliminarAsociacion(a.id);
  }
}

// --- 3. Vista ---
class AsociacionesView extends StatefulWidget {
  const AsociacionesView({super.key});

  @override
  State<AsociacionesView> createState() => _AsociacionesViewState();
}

class _AsociacionesViewState extends State<AsociacionesView> {
  int _currentPage = 0;
  final int _rowsPerPage = 8;

  // Controlador de búsqueda
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<AsociacionesDatabase>(context, listen: false).iniciarStream();
  }

  @override
  Widget build(BuildContext context) {
    final asociacionesDb = Provider.of<AsociacionesDatabase>(context);
    final theme = Theme.of(context);

    // Lista completa
    final allAsociaciones = asociacionesDb.asociaciones;

    // FILTRO de búsqueda
    final search = _searchController.text.toLowerCase();

    final filteredAsociaciones = allAsociaciones.where((a) {
      return a.nombre.toLowerCase().contains(search) ||
          a.tipo.toLowerCase().contains(search) ||
          a.contacto.toLowerCase().contains(search);
    }).toList();

    // PAGINACIÓN
    final totalRecords = filteredAsociaciones.length;
    final totalPages = totalRecords == 0
        ? 1
        : (totalRecords / _rowsPerPage).ceil();

    _currentPage = _currentPage.clamp(0, totalPages - 1);

    final startIndex = totalRecords == 0 ? 0 : _currentPage * _rowsPerPage;
    final endIndex = totalRecords == 0
        ? 0
        : (startIndex + _rowsPerPage).clamp(0, totalRecords);

    final asociacionesToShow = totalRecords > 0
        ? filteredAsociaciones.sublist(startIndex, endIndex)
        : [];

    final startRecord = totalRecords > 0 ? startIndex + 1 : 0;
    final endRecord = endIndex;

    final double headingRowHeight = 56.0;
    final double dataRowHeight = 52.0;
    final int visibleRows = asociacionesToShow.isNotEmpty
        ? asociacionesToShow.length
        : 1;
    final double tableMaxHeight =
        headingRowHeight + (visibleRows * dataRowHeight);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 50),

          // -------------------------------------------------
          // 🔍 BARRA DE BÚSQUEDA CON onChanged
          // -------------------------------------------------
          Row(
            children: [
              Container(width: 150),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _currentPage = 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar asociación...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(
                        0.6,
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 260),
            ],
          ),

          Container(height: 50),

          // ---- BOTÓN NUEVA ASOCIACIÓN ----
          Row(
            children: [
              Container(width: 150),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  minimumSize: const Size(180, 50),
                ),
                onPressed: () {
                  _mostrarFormulario(context, asociacionesDb);
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 30),
                label: const Text(
                  'Nueva Asociación',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------
          // 📄 TABLA CON ENCABEZADOS EN NEGRITAS
          // -------------------------------------------------
          Row(
            children: [
              Container(width: 150),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(0),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SizedBox(
                        height: tableMaxHeight,
                        child: SingleChildScrollView(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: DataTable(
                                    headingRowHeight: headingRowHeight,
                                    dataRowMaxHeight: dataRowHeight,
                                    dataRowMinHeight: dataRowHeight,
                                    headingRowColor: MaterialStateProperty.all(
                                      theme.colorScheme.surfaceVariant
                                          .withOpacity(0.6),
                                    ),
                                    dividerThickness: 1.0,
                                    columnSpacing: 40.0,
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          'ID',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Nombre de la Asociación',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Tipo de Asociación',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Contacto',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Acciones',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: asociacionesToShow.map((asociacion) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(asociacion.id.toString()),
                                          ),
                                          DataCell(Text(asociacion.nombre)),
                                          DataCell(Text(asociacion.tipo)),
                                          DataCell(Text(asociacion.contacto)),
                                          DataCell(
                                            Row(
                                              children: [
                                                ElevatedButton.icon(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    'Editar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.blue,
                                                      ),
                                                  onPressed: () {
                                                    _mostrarFormulario(
                                                      context,
                                                      asociacionesDb,
                                                      asociacion: asociacion,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton.icon(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  onPressed: () {
                                                    asociacionesDb
                                                        .eliminarAsociacion(
                                                          asociacion,
                                                        );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      _buildPaginationControls(
                        totalPages: totalPages,
                        totalRecords: totalRecords,
                        startRecord: startRecord,
                        endRecord: endRecord,
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 260),
            ],
          ),
        ],
      ),
    );
  }

  // --- FORMULARIO ---
  void _mostrarFormulario(
    BuildContext context,
    AsociacionesDatabase db, {
    Asociacion? asociacion,
  }) {
    final esEdicion = asociacion != null;

    final nombreCtrl = TextEditingController(text: asociacion?.nombre ?? "");
    final tipoCtrl = TextEditingController(text: asociacion?.tipo ?? "");
    final contactoCtrl = TextEditingController(
      text: asociacion?.contacto ?? "",
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(esEdicion ? "Editar Asociación" : "Nueva Asociación"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                TextField(
                  controller: tipoCtrl,
                  decoration: const InputDecoration(labelText: "Tipo"),
                ),
                TextField(
                  controller: contactoCtrl,
                  decoration: const InputDecoration(labelText: "Contacto"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (esEdicion) {
                  db.editarAsociacion(
                    asociacion!,
                    nombreCtrl.text,
                    tipoCtrl.text,
                    contactoCtrl.text,
                  );
                } else {
                  db.crearAsociacion(
                    nombreCtrl.text,
                    tipoCtrl.text,
                    contactoCtrl.text,
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  // --- PAGINACIÓN ---
  Widget _buildPaginationControls({
    required int totalPages,
    required int totalRecords,
    required int startRecord,
    required int endRecord,
  }) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final Color textColor = theme.brightness == Brightness.dark
        ? Colors.white70
        : const Color.fromARGB(136, 90, 87, 87);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando $startRecord al $endRecord de $totalRecords registros',
            style: TextStyle(fontSize: 14, color: textColor),
          ),
          Row(
            children: [
              TextButton(
                onPressed: _currentPage == 0
                    ? null
                    : () {
                        setState(() {
                          _currentPage--;
                        });
                      },
                child: const Text('Anterior'),
              ),
              const SizedBox(width: 16),
              Text(
                'Página ${_currentPage + 1} de $totalPages',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _currentPage >= (totalPages - 1)
                    ? null
                    : () {
                        setState(() {
                          _currentPage++;
                        });
                      },
                child: const Text('Siguiente'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
