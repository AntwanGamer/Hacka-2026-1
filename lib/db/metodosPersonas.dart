import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosPersonas{
  final supabase = Supabase.instance.client;
  
  Future<void> insertarPersona({
    required String nombre,
    required String tipoPersona,
    required String infContacto
  }) async {
    await supabase.from('personas').insert({
      'nombre': nombre,
      'tipo_persona': tipoPersona,
      'info_contacto': infContacto,
      'activo': true
    });
  }

Future<void> eliminarPersonaConVerificacion(int id) async {
    // Verificamos si el ID aparece en la columna 'id_motorista' O en 'id_cocinero'
    final usoEnManifiestos = await supabase
        .from('manifiestos')
        .select('id_manifiesto')
        .or('id_motorista.eq.$id,id_cocinero.eq.$id'); // <--- AQUI ESTA EL CAMBIO

    // Si la lista está vacía, nadie lo está usando, así que BORRAMOS DE VERDAD
    if (usoEnManifiestos.isEmpty) {
      await supabase.from('personas').delete().eq('id_personas', id);
    } 
    // Si la lista tiene datos, significa que se usa como motorista o cocinero, así que solo DESACTIVAMOS
    else {
      await supabase.from('personas').update({'activo': false}).eq('id_personas', id);
    }
  }

  Future<void> actualizarPersona(
    int id, {
    required String nombre,
    required String tipoPersona,
    required String infContacto
  }) async {
    await supabase.from('personas').update({
      'nombre': nombre,
      'tipo_persona': tipoPersona,
      'info_contacto': infContacto
    }).eq('id_personas', id);
  }

  //coso para mostrar los datos en tabla
  Stream<List<Map<String, dynamic>>> streamPersonas() {
    return supabase
        .from('personas')
        .stream(primaryKey: ['id_personas'])
        //.eq('activo', true)
        .order('id_personas')
        .map((rows) => rows.map((r) => r as Map<String, dynamic>)
        .where((persona) => persona['activo'] == true)
        .toList());
  }

  Future<String?> obtenerNombrePorId(int id) async {
    try {
      final res = await supabase.from('personas').select('nombre').eq('id_personas', id).maybeSingle();
      if (res == null) return null;
      if (res is Map && res['nombre'] != null) return res['nombre'].toString();
      return null;
    } catch (e) {
      return null;
    }
  }
}