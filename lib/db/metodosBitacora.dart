import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosBitacora {
  final supabase = Supabase.instance.client;

  // Stream corregido
  Stream<List<Map<String, dynamic>>> streamBitacora() {
    return supabase
        .from('bitacora')
        .stream(primaryKey: ['id_bitacora'])
        .order('fecha_movimiento', ascending: false) // Lo más nuevo primero
        .map((rows) => rows.map((r) => r as Map<String, dynamic>).toList());
  }

  Future<Map<String, String>> obtenerMapaUsuarios() async {
    try {
      final List<Map<String, dynamic>> response = await supabase
          .from('profiles')
          .select('id, nombre');

      final Map<String, String> mapa = {};

      for (var user in response) {
        if (user['id'] != null && user['nombre'] != null) {
          mapa[user['id'].toString()] = user['nombre'].toString();
        }
      }
      return mapa;
    } catch (e) {
      print("Error cargando perfiles: $e");
      return {};
    }
  }
  // En tu archivo db/metodosBitacora.dart

Future<Map<String, String>> obtenerMapaEmbarcaciones() async {
  try {
    final response = await supabase.from('embarcacion').select('id_embarcacion, nombre_embarcacion');
    final Map<String, String> mapa = {};
    for (var item in response) {
      mapa[item['id_embarcacion'].toString()] = item['nombre_embarcacion'].toString();
    }
    return mapa;
  } catch (e) {
    return {};
  }
}

Future<Map<String, String>> obtenerMapaPersonas() async {
  try {
    // Traemos a todas las personas (sirve para motoristas y cocineros)
    final response = await supabase.from('personas').select('id_personas, nombre');
    final Map<String, String> mapa = {};
    for (var item in response) {
      mapa[item['id_personas'].toString()] = item['nombre'].toString();
    }
    return mapa;
  } catch (e) {
    return {};
  }
}
}
  /*
  Future<void> insertarEmbarcacion({
    required String nombre,
    required String tipoEmbarcacion,
    required DateTime fechaRegistro
  }) async {
    await supabase.from('embarcacion').insert({
      'nombre_embarcacion': nombre,
      'tipo_embarcacion': tipoEmbarcacion,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'activo': true
    });
  }
  */

/*
  Future<void> eliminarEmbarcacionConVerificacion(int id) async{
    final asignacion = await supabase
      .from('asignaciones')
      .select('id_asignacion')
      .eq('embarcacion_id', id);
    final manifiesto = await supabase
      .from('manifiestos')
      .select('id_manifiesto')
      .eq('id_embarcacion', id);
    if (asignacion.isEmpty && manifiesto.isEmpty){
      await supabase.from('embarcacion').delete().eq('id_embarcacion', id);
    }
    else {
      await supabase.from('embarcacion').update({'activo': false}).eq('id_embarcacion', id);
    }
  } 
*/

/*
  Future<void> actualizarEmbarcacion(
    int id, {
    required String nombre,
    required String tipoEmbarcacion,
    required DateTime fechaRegistro
  }) async {
    await supabase.from('embarcacion').update({
      'nombre_embarcacion': nombre,
      'tipo_embarcacion': tipoEmbarcacion,
      'fecha_registro': fechaRegistro.toIso8601String(),
    }).eq('id_embarcacion', id);
  }

*/