import 'package:supabase_flutter/supabase_flutter.dart';

class MetodosReciboBasuron {
  final supabase = Supabase.instance.client;

  /// Crear recibo
  Future<void> crearRecibo({
    required String tipoDesecho,
    required DateTime fechaRecibo,
    required int cantidadKg,
    required String reciboUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw "No hay usuario autenticado";

    await supabase.from('recibo_basuron').insert({
      'id_usuario': user.id,
      'tipo_desecho': tipoDesecho,
      'fecha_recibo': fechaRecibo.toIso8601String(),
      'cantidad_kg': cantidadKg,
      'recibo': reciboUrl,
    });
  }

  /// Editar
  Future<void> editarRecibo(
    int id, {
    required String tipoDesecho,
    required DateTime fechaRecibo,
    required int cantidadKg,
    required String reciboUrl,
  }) async {
    await supabase
        .from('recibo_basuron')
        .update({
          'tipo_desecho': tipoDesecho,
          'fecha_recibo': fechaRecibo.toIso8601String(),
          'cantidad_kg': cantidadKg,
          'recibo': reciboUrl,
        })
        .eq('id', id);
  }

  /// Eliminar
  Future<void> eliminarRecibo(int id) async {
    await supabase.from('recibo_basuron').delete().eq('id', id);
  }
}
