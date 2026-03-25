import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosObservaciones{
  final supabase = Supabase.instance.client;
  
  Future<void> insertarObservacion({
    required String observaciones,
    required DateTime fecha,
    //required String idUsuario,
    required int idEmbarcacion,
  }) async {
    await supabase.from('observacion').insert({
      'observaciones_realizadas': observaciones,
      'fecha_inspeccion': fecha.toIso8601String(),
      //'usuario_inspeccion': idUsuario,
      'embarcacion_vista': idEmbarcacion
    });
  }

  /*
  Future<void> eliminarPersonaConVerificacion(int id) async{
    final asignacion = await supabase
      .from('asignaciones')
      .select('id_asignacion')
      .eq('persona_id', id);
    if (asignacion.isEmpty){
      await supabase.from('personas').delete().eq('id_personas', id);
    }
    else {
      await supabase.from('personas').update({'activo': false}).eq('id_personas', id);
    }
  }*/

  Future<void> actualizarObservacion(
    int id, {
    required String observaciones,
    required DateTime fecha,
    //required String idUsuario,
    required int idEmbarcacion
  }) async {
    await supabase.from('personas').update({
      'observaciones_realizadas': observaciones,
      'fecha_inspeccion': fecha.toIso8601String(),
      //'usuario_inspeccion': idUsuario,
      'embarcacion_vista': idEmbarcacion
    }).eq('id_observacion', id);
  }

  Future<List<Map<String, dynamic>>> seleccionarObservacion(int id) async {
    return await supabase
      .from('observacion')
      .select()
      .eq('id_observacion', id);
  }
}