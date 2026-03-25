import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosEstadisticas {
  final supabase = Supabase.instance.client;

  // Cargar lista simple de barcos para el dropdown
  Future<List<Map<String, dynamic>>> obtenerListaBarcos() async {
    try {
      final response = await supabase
          .from('embarcacion')
          .select('id_embarcacion, nombre_embarcacion')
          .order('nombre_embarcacion');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // KPIs con filtro opcional
  Future<Map<String, dynamic>> obtenerKPIs(int anio, {int? barcoId}) async {
    final response = await supabase.rpc('get_kpis_general', params: {
      'p_anio': anio,
      'p_barco_id': barcoId // Puede ser null
    });
    return response as Map<String, dynamic>;
  }

  // Tendencia con filtro opcional
  Future<List<Map<String, dynamic>>> obtenerTendencia(int anio, {int? barcoId}) async {
    final response = await supabase.rpc('get_tendencia_general', params: {
      'p_anio': anio,
      'p_barco_id': barcoId
    });
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  // Filtros con filtro opcional
  Future<Map<String, dynamic>> obtenerFiltros(int anio, {int? barcoId}) async {
    final response = await supabase.rpc('get_filtros_general', params: {
      'p_anio': anio,
      'p_barco_id': barcoId
    });
    return response as Map<String, dynamic>;
  }

  // Top barcos (Este NO cambia, siempre queremos ver el ranking global para comparar)
  Future<List<Map<String, dynamic>>> obtenerTopBarcos(int anio) async {
    final response = await supabase.rpc('get_top_embarcaciones', params: {'anio': anio});
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }
}