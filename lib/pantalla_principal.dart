import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:zombie/db/metodosEstadisticas.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final MetodosEstadisticas metodos = MetodosEstadisticas();
  
  int _selectedYear = DateTime.now().year;
  int? _selectedBoatId; 
  List<Map<String, dynamic>> _barcosList = [];

  @override
  void initState() {
    super.initState();
    _cargarBarcos();
  }

  void _cargarBarcos() async {
    final barcos = await metodos.obtenerListaBarcos();
    if (mounted) {
      setState(() {
        _barcosList = barcos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            
            // --- 1. ENCABEZADO Y FILTROS ---
            _buildHeaderFilters(theme),
            
            const SizedBox(height: 20),

            FutureBuilder(
              future: Future.wait([
                metodos.obtenerKPIs(_selectedYear, barcoId: _selectedBoatId),
                metodos.obtenerTendencia(_selectedYear, barcoId: _selectedBoatId),
                metodos.obtenerFiltros(_selectedYear, barcoId: _selectedBoatId),
                metodos.obtenerTopBarcos(_selectedYear),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 300, 
                    child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error)));
                }

                final data = snapshot.data as List;
                final kpis = data[0] as Map<String, dynamic>;
                final tendencia = data[1] as List<Map<String, dynamic>>;
                final filtros = data[2] as Map<String, dynamic>;
                final topBarcos = data[3] as List<Map<String, dynamic>>;

                // Cálculos para equivalencias
                final double basuraKg = double.tryParse(kpis['total_basura'].toString()) ?? 0;
                final double aceiteL = double.tryParse(kpis['total_aceite'].toString()) ?? 0;
                
                final int equivalenciaAutos = (basuraKg / 80).ceil(); 
                final int equivalenciaGarrafones = (aceiteL / 1100).ceil();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- 2. IMPACTO AMBIENTAL (EQUIVALENCIAS) ---
                    Text("Impacto Ambiental", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _impactCard(
                            context: context,
                            title: "Residuos Sólidos",
                            amount: "$basuraKg Kg",
                            comparisonText: "Equivaleso aprox. a $equivalenciaAutos refrigeradores",
                            icon: Icons.kitchen,
                            color: Colors.brown.shade400,
                            
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _impactCard(
                            context: context,
                            title: "Residuos Líquidos",
                            amount: "$aceiteL Litros",
                            comparisonText: "Volumen equivalente a $equivalenciaGarrafones tinacos",
                            icon: Icons.local_drink,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    
                    // --- 3. KPIs NUMÉRICOS (CARDS PEQUEÑAS) ---
                    Text("Indicadores Clave", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _metricCardCompact(context: context, color: Colors.blue.shade600, title: "Basura (Kg)", value: "${kpis['total_basura']}", icon: Icons.delete),
                        _metricCardCompact(context: context, color: Colors.orange.shade600, title: "Aceite (L)", value: "${kpis['total_aceite']}", icon: Icons.water_drop),
                        _metricCardCompact(context: context, color: Colors.green.shade600, title: "Filtros", value: "${kpis['total_filtros']}", icon: Icons.filter_alt),
                        _metricCardCompact(context: context, color: Colors.purple.shade600, title: "Manifiestos", value: "${kpis['total_registros']}", icon: Icons.description),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- 4. GRÁFICO DE TENDENCIA (Ancho completo) ---
                    _chartContainer(
                      context: context,
                      title: "Tendencia de Recolección (Anual)",
                      child: _buildLineChart(tendencia, context),
                    ),
                    
                    const SizedBox(height: 16),

                    // --- 5. FILA COMPARTIDA: FILTROS + RANKING ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IZQUIERDA: PASTEL (Filtros)
                        Expanded(
                          child: _chartContainer(
                            context: context,
                            title: "Desglose Filtros",
                            height: 350, // Altura igualada
                            child: _buildFilterPieChart(filtros, context),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // DERECHA: BARRAS (Ranking)
                        Expanded(
                          child: _chartContainer(
                            context: context,
                            // Cambia título dinámicamente si hay filtro
                            title: _selectedBoatId == null ? "Top 5 Generadores" : "Ranking Global",
                            height: 350, // Altura igualada
                            child: _buildBarChart(topBarcos, context),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 50),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------
  // WIDGETS DE UI
  // ---------------------------

  Widget _buildHeaderFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text("Estadísticas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          const Spacer(),
          // Dropdown Año
          DropdownButton<int>(
            value: _selectedYear,
            underline: Container(),
            dropdownColor: theme.colorScheme.surface,
            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
            items: [2015,2016,2017,2018,2019,2020,2021,2022,2023, 2024, 2025, 2026].map((int year) => DropdownMenuItem<int>(value: year, child: Text("$year"))).toList(),
            onChanged: (val) { if (val != null) setState(() => _selectedYear = val); },
          ),
          const SizedBox(width: 20),
          // Dropdown Barco
          DropdownButton<int?>(
            value: _selectedBoatId,
            hint: Text("Todos los barcos", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            underline: Container(),
            dropdownColor: theme.colorScheme.surface,
            style: TextStyle(color: theme.colorScheme.onSurface),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text("Todos los barcos", style: TextStyle(color: theme.colorScheme.primary))),
              ..._barcosList.map((barco) => DropdownMenuItem<int?>(
                value: barco['id_embarcacion'],
                child: Text(barco['nombre_embarcacion'].toString().length > 15 ? "${barco['nombre_embarcacion'].toString().substring(0, 15)}..." : barco['nombre_embarcacion'].toString()),
              )).toList(),
            ],
            onChanged: (val) => setState(() => _selectedBoatId = val),
          ),
        ],
      ),
    );
  }

  Widget _impactCard({
    required BuildContext context,
    required String title,
    required String amount,
    required String comparisonText,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.05), color.withOpacity(0.15)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    comparisonText,
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _metricCardCompact({required BuildContext context, required Color color, required String title, required String value, required IconData icon}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(title.toUpperCase(), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _chartContainer({required BuildContext context, required String title, required Widget child, double height = 320}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  // --- GRÁFICOS ---
  Widget _buildLineChart(List<Map<String, dynamic>> data, BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) return Center(child: Text("Sin datos", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));

    List<FlSpot> spotsAceite = [];
    List<FlSpot> spotsBasura = [];
    for (var item in data) {
      double mes = (item['mes'] as int).toDouble();
      spotsAceite.add(FlSpot(mes, (item['aceite'] as num).toDouble()));
      spotsBasura.add(FlSpot(mes, (item['basura'] as num).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1)),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (val, meta) {
            const meses = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
            int idx = val.toInt() - 1;
            return idx >= 0 && idx < 12 ? Text(meses[idx], style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)) : const Text('');
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, interval: 500, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant)))),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: spotsAceite, isCurved: true, color: Colors.orange, barWidth: 3, dotData: FlDotData(show: false)),
          LineChartBarData(spots: spotsBasura, isCurved: true, color: Colors.blue, barWidth: 3, dotData: FlDotData(show: false)),
        ],
      ),
    );
  }

  Widget _buildFilterPieChart(Map<String, dynamic> data, BuildContext context) {
    final theme = Theme.of(context);
    double aceite = (data['aceite'] as num).toDouble();
    double diesel = (data['diesel'] as num).toDouble();
    double aire = (data['aire'] as num).toDouble();
    double total = aceite + diesel + aire;

    if (total == 0) return Center(child: Text("Sin filtros", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
    final colorAceite = theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87;

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                PieChartSectionData(value: aceite, color: colorAceite, title: "${(aceite/total*100).toStringAsFixed(0)}%", radius: 30, titleStyle: TextStyle(fontSize: 10, color: theme.colorScheme.surface)),
                PieChartSectionData(value: diesel, color: Colors.amber, title: "${(diesel/total*100).toStringAsFixed(0)}%", radius: 30, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
                PieChartSectionData(value: aire, color: Colors.blueGrey, title: "${(aire/total*100).toStringAsFixed(0)}%", radius: 30, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)),
              ],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendItem(colorAceite, "Aceite ($aceite)", context),
            _legendItem(Colors.amber, "Diesel ($diesel)", context),
            _legendItem(Colors.blueGrey, "Aire ($aire)", context),
          ],
        )
      ],
    );
  }

  Widget _legendItem(Color color, String text, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(text, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface))]),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) return Center(child: Text("Sin datos", style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < data.length; i++) {
      barGroups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: (data[i]['total_kg'] as num).toDouble(), color: theme.colorScheme.primary, width: 16, borderRadius: BorderRadius.circular(4)),
      ]));
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
            int idx = val.toInt();
            if (idx >= 0 && idx < data.length) {
              String nombre = data[idx]['nombre'].toString();
              return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(nombre.length > 8 ? "${nombre.substring(0, 6)}..." : nombre, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)));
            }
            return const Text("");
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}