import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosAsociacionesRecolectoras {
  final supabase = Supabase.instance.client;

  Future<void> insertarAsociacion({
    required String nombre,
    required String tipoAsociacion,
    required String contacto,
  }) async {
    await supabase.from('asociacionesrecolectoras').insert({
      'nombre_asociacion': nombre,
      'tipo_asociacion': tipoAsociacion,
      'contacto_asociacion': contacto,
    });
  }

  Future<void> eliminarAsociacion(int id) async {
    await supabase.from('asociacionesrecolectoras').delete().eq('id', id);
  }

  Future<void> actualizarAsociacion(
    int id, {
    required String nombre,
    required String tipoAsociacion,
    required String contacto,
  }) async {
    await supabase
        .from('asociacionesrecolectoras')
        .update({
          'nombre_asociacion': nombre,
          'tipo_asociacion': tipoAsociacion,
          'contacto_asociacion': contacto,
        })
        .eq('id', id);
  }

  Stream<List<Map<String, dynamic>>> streamAsociaciones() {
    return supabase
        .from('asociacionesrecolectoras')
        .stream(primaryKey: ['id'])
        .order('id')
        .map((rows) => rows.map((r) => r as Map<String, dynamic>).toList());
  }
}
