import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosPersonas {
  final supabase = Supabase.instance.client;

  Future<void> insertarCliente({
    required String nombre,
    required String tipoPersona,
    required String infContacto,
  }) async {
    await supabase.from('personas').insert({
      'nombre': nombre,
      'tipo_persona': tipoPersona,
      'info_contacto': infContacto,
      'activo': true,
    });
  }

  Future<void> eliminarPersonaConVerificacion(int id) async {
    final asignacion = await supabase
        .from('asignaciones')
        .select('id_asignacion')
        .eq('persona_id', id);
    if (asignacion.isEmpty) {
      await supabase.from('personas').delete().eq('id_personas', id);
    } else {
      await supabase
          .from('personas')
          .update({'activo': false})
          .eq('id_personas', id);
    }
  }

  Future<void> actualizarPersona(
    int id, {
    required String nombre,
    required String tipoPersona,
    required String infContacto,
  }) async {
    await supabase
        .from('personas')
        .update({
          'nombre': nombre,
          'tipo_persona': tipoPersona,
          'info_contacto': infContacto,
        })
        .eq('id_personas', id);
  }

  //coso para mostrar los datos en tabla
  Stream<List<Map<String, dynamic>>> streamPersonas() {
    return supabase
        .from('personas')
        .stream(primaryKey: ['id_personas'])
        .eq('activo', true)
        .order('id_personas')
        .map((rows) => rows.map((r) => r as Map<String, dynamic>).toList());
  }
}
