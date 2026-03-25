import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/reciboBasuronModelo.dart';
import 'dart:typed_data';

class ReciboBasuronDatabase extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<ReciboBasuronModelo> recibos = [];

  /// ===========================
  /// Cargar datos
  /// ===========================
  Future<void> cargarDatos() async {
    final data = await supabase
        .from('recibo_basuron')
        .select()
        .order('id', ascending: false);

    recibos = data
        .map<ReciboBasuronModelo>((e) => ReciboBasuronModelo.fromJson(e))
        .toList();

    notifyListeners();
  }

  /// ===========================
  /// Crear recibo
  /// ===========================
  Future<void> crearRecibo({
    required String tipoDesecho,
    required DateTime fechaRecibo,
    required int cantidadKg,
    required String idUsuario,
    required String recibo, // URL o nombre de archivo
  }) async {
    await supabase.from('recibo_basuron').insert({
      'tipo_desecho': tipoDesecho,
      'fecha_recibo': fechaRecibo.toIso8601String(),
      'cantidad_kg': cantidadKg,
      'id_usuario': idUsuario,
      'recibo': recibo,
    });

    await cargarDatos();
  }

  /// ===========================
  /// Editar recibo
  /// ===========================
  Future<void> editarRecibo(
    ReciboBasuronModelo r, {
    required String tipoDesecho,
    required DateTime fechaRecibo,
    required int cantidadKg,
    required String recibo,
  }) async {
    // Aseguramos que el id_usuario se actualice con el usuario activo
    final currentUserId = supabase.auth.currentUser?.id;
    await supabase
        .from('recibo_basuron')
        .update({
          'tipo_desecho': tipoDesecho,
          'fecha_recibo': fechaRecibo.toIso8601String(),
          'cantidad_kg': cantidadKg,
          'recibo': recibo,
          if (currentUserId != null) 'id_usuario': currentUserId,
        })
        .eq('id', r.id);

    await cargarDatos();
  }

  /// ===========================
  /// Eliminar recibo
  /// ===========================
Future<void> eliminarRecibo(ReciboBasuronModelo r) async {
    try {
      // 1. Intentar borrar la imagen del bucket si existe URL
      if (r.recibo.isNotEmpty) {
        // La URL pública suele ser algo así: 
        // .../storage/v1/object/public/recibo_Basuron/carpeta/archivo.jpg
        // Para borrar, Supabase necesita SOLO la ruta: 'carpeta/archivo.jpg'
        
        // Hacemos un split por el nombre del bucket
        final nombreBucket = 'recibo_Basuron'; 
        if (r.recibo.contains(nombreBucket)) {
          final partes = r.recibo.split('/$nombreBucket/');
          if (partes.length > 1) {
            final rutaArchivo = partes.last; // Esto toma lo que está después del bucket
            
            await supabase.storage
                .from(nombreBucket)
                .remove([rutaArchivo]); // Borra el archivo
          }
        }
      }

      // 2. Borrar el registro de la Base de Datos
      await supabase.from('recibo_basuron').delete().eq('id', r.id);
      
      // 3. Recargar la lista
      await cargarDatos();
      
    } catch (e) {
      debugPrint("Error al eliminar: $e");
      // Aquí podrías lanzar una excepción o manejar el error visualmente
    }
  }

  Future<String?> subirImagen(Uint8List bytes, String nombreArchivo) async {
    try {
      // 1. Creamos una ruta única: idUsuario/timestamp_nombre.jpg
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final ruta = '$userId/${DateTime.now().millisecondsSinceEpoch}_$nombreArchivo';

      // 2. Subimos el archivo al bucket 'recibos'
      await supabase.storage.from('recibo_Basuron').uploadBinary(
        ruta,
        bytes,
        //fileOptions: const FileOptions(contentType: 'image/png'), // Opcional: ajusta según tipo
      );

      // 3. Obtenemos la URL pública
      final urlPublica = supabase.storage.from('recibo_Basuron').getPublicUrl(ruta);
      
      return urlPublica;
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      return null;
    }
  }
}
