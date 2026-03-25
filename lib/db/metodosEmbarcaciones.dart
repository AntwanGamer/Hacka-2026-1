import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosEmbarcaciones{
  final supabase = Supabase.instance.client;
  
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

  Future<void> eliminarEmbarcacionConVerificacion(int id) async{
    final manifiesto = await supabase
      .from('manifiestos')
      .select('id_manifiesto')
      .eq('id_embarcacion', id);
    if (manifiesto.isEmpty){
      await supabase.from('embarcacion').delete().eq('id_embarcacion', id);
    }
    else {
      await supabase.from('embarcacion').update({'activo': false}).eq('id_embarcacion', id);
    }
  } 

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

  // Devuelve el nombre de la embarcación dado su id, o null si no existe
  Future<String?> obtenerNombreEmbarcacionPorId(int id) async {
    try {
      final res = await supabase
          .from('embarcacion')
          .select('nombre_embarcacion')
          .eq('id_embarcacion', id)
          .maybeSingle();
      if (res == null) return null;
      if (res is Map) return res['nombre_embarcacion']?.toString();
      return null;
    } catch (e) {
      rethrow;
    }
  }

  

  //coso para mostrar los datos en tabla
  Stream<List<Map<String, dynamic>>> streamEmbarcaciones() {
    return supabase
        .from('embarcacion')
        .stream(primaryKey: ['id_embarcacion'])
        //.eq('activo', true)
        .order('id_embarcacion')
        .map((rows) => rows.map((r) => r as Map<String, dynamic>)
        .where((persona) => persona['activo'] == true)
        .toList());
  }
}