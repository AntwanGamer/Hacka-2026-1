import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart';

class MetodosManifiestos{
  final supabase = Supabase.instance.client;
  
  Future<void> insertarManifiesto({
    required int idEmbarcacion,
    //required bool sellado,
    required DateTime fechaManifiesto,
    required double aceiteUsadoLitros,
    required double basuraKg,
    required int filtrosAceite,
    required int filtrosDiesel,
    required int filtrosAire,
    required int idMotorista,
    required int idCocinero,
    String? linkManifiestoSellado,
    required String? idUsuario,
    String? observacion,
  }) async {
    await supabase.from('manifiestos').insert({
      'id_embarcacion': idEmbarcacion,
      'fecha_manifiesto': fechaManifiesto.toIso8601String(),
      'aceite_usado_l': aceiteUsadoLitros,
      'basura_kg': basuraKg,
      'filtro_aceite': filtrosAceite,
      'filtro_diesel': filtrosDiesel,
      'filtro_aire': filtrosAire,
      'id_motorista': idMotorista,
      'id_cocinero': idCocinero,
      'link_manifiestos_pdf': linkManifiestoSellado,
      'id_usuario': idUsuario,
      'observacion': observacion,
    });
  }

  Future<void> eliminarManifiesto(int idManifiesto, String nombreArchivo) async{
    await supabase.from('manifiestos').delete().eq('id_manifiesto', idManifiesto);
    await supabase.storage.from('manifiesto_pdf').remove([nombreArchivo]);
  }

/*
  Future<void> eliminarManifiestoConVerificacion(int id) async{
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

 Future<void> actualizarManifiesto(
    int idManifiesto, {
    required int idEmbarcacion,
    required DateTime fechaManifiesto,
    required double aceiteUsadoLitros,
    required double basuraKg,
    required int filtrosAceite,
    required int filtrosDiesel,
    required int filtrosAire,
    required int idMotorista,
    required int idCocinero,
    required String? linkManifiestoSellado,
    String? observacion,
    required String? idUsuario,
  }) async {
    await supabase.from('manifiestos').update({
      'id_manifiesto': idManifiesto,
      'id_embarcacion': idEmbarcacion,
      'fecha_manifiesto': fechaManifiesto.toIso8601String(),
      'aceite_usado_l': aceiteUsadoLitros,
      'basura_kg': basuraKg,
      'filtro_aceite': filtrosAceite,
      'filtro_diesel': filtrosDiesel,
      'filtro_aire': filtrosAire,
      'id_motorista': idMotorista,
      'id_cocinero': idCocinero,
      'link_manifiestos_pdf': linkManifiestoSellado,
      'observacion': observacion,
      'id_usuario': idUsuario,
    }).eq('id_manifiesto', idManifiesto);
  }

  Future<void> actualizarPDF(
    int idManifiesto, {
    required String nombreArchivoPDF,
    required PlatformFile linkManifiestoSellado,
  }) async {
    //print("Actualizando PDF en la base de datos... $linkManifiestoSellado"); // si lo descomentas te dara un cochinero de bytes pero funciona
    await uploadPDF(nombreArchivoPDF, linkManifiestoSellado);
    await supabase.from('manifiestos').update({
      'id_manifiesto': idManifiesto,
      'link_manifiestos_pdf': nombreArchivoPDF,
    }).eq('id_manifiesto', idManifiesto);
  }

  Stream<List<Map<String, dynamic>>> streamManifiestos() {
    return supabase
        .from('manifiestos')
        .stream(primaryKey: ['id_manifiesto'])
        .order('id_manifiesto')
        .map((rows) => rows.map((r) => r as Map<String, dynamic>).toList()); // cast de seguridad
  }


  // Stream OPTIMIZADO: usa JOIN para obtener nombres en UNA sola consulta
  Stream<List<Map<String, dynamic>>> streamManifiestosConNombreEmbarcaciones() async* {
    // Obtener todos los manifiestos con nombres de embarcaciones en UNA consulta con JOIN
    try {
      final manifestosConNombres = await supabase
          .from('manifiestos')
          .select('*, embarcacion!inner(nombre_embarcacion)')
          .order('id_manifiesto');
      
      // Mapear para aplanar la estructura
      List<Map<String, dynamic>> manifiestosMapeados = manifestosConNombres.map((m) {
        final Map<String, dynamic> manifiesto = Map.from(m);
        // Si embarcacion existe, extraer nombre_embarcacion al nivel superior
        if (manifiesto['embarcacion'] != null) {
          if (manifiesto['embarcacion'] is Map) {
            manifiesto['nombre_embarcacion'] = manifiesto['embarcacion']['nombre_embarcacion'];
          } else if (manifiesto['embarcacion'] is List && (manifiesto['embarcacion'] as List).isNotEmpty) {
            manifiesto['nombre_embarcacion'] = manifiesto['embarcacion'][0]['nombre_embarcacion'];
          }
        }
        manifiesto.remove('embarcacion'); // Limpiar el objeto anidado
        return manifiesto;
      }).toList();
      
      yield manifiestosMapeados;
      
      // Continuar escuchando cambios en tiempo real (sin JOIN para ser más rápido)
      await for (final cambios in supabase
          .from('manifiestos')
          .stream(primaryKey: ['id_manifiesto'])
          .order('id_manifiesto')) {
        
        // Obtener IDs únicos de embarcaciones que necesitamos
        final idsEmbarcaciones = cambios
            .where((m) => m['id_embarcacion'] != null)
            .map((m) => m['id_embarcacion'])
            .toSet()
            .toList();
        
        // Obtener TODOS los nombres de embarcaciones en una sola consulta
        Map<int, String> nombresCache = {};
        if (idsEmbarcaciones.isNotEmpty) {
          try {
            final embarcaciones = await supabase
                .from('embarcacion')
                .select('id_embarcacion, nombre_embarcacion')
                .inFilter('id_embarcacion', idsEmbarcaciones);
            
            for (final emb in embarcaciones) {
              nombresCache[emb['id_embarcacion']] = emb['nombre_embarcacion'];
            }
          } catch (e) {
            print('Error obteniendo nombres de embarcaciones en batch: $e');
          }
        }
        
        // Mapear los cambios con los nombres del cache
        final List<Map<String, dynamic>> actualizados = cambios.map((manifiesto) {
          final Map<String, dynamic> m = Map.from(manifiesto);
          if (m['id_embarcacion'] != null && nombresCache.containsKey(m['id_embarcacion'])) {
            m['nombre_embarcacion'] = nombresCache[m['id_embarcacion']];
          }
          return m;
        }).toList();
        
        yield actualizados;
      }
    } catch (e) {
      print('Error en streamManifiestosConNombreEmbarcaciones: $e');
      // En caso de error, fallback al stream normal
      await for (final manifiestos in supabase
          .from('manifiestos')
          .stream(primaryKey: ['id_manifiesto'])
          .order('id_manifiesto')) {
        yield manifiestos.map((r) => r as Map<String, dynamic>).toList();
      }
    }
  }

  String ArreglarNombreArchivo(String fileName) {
    fileName = fileName
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ñ', 'N');

    // Ajustes extras pero no se necesecitan ahora.
    /*
    fileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
    fileName = fileName.replaceAll(RegExp(r'_+'), '_');
    fileName.toLowerCase();*/

    return fileName;
  }

  Future<bool> verificarArchivoExiste(String nombreArchivo) async {
    try {
      final List<FileObject> files = await supabase.storage
          .from('manifiesto_pdf')
          .list(path: '');
      
      return files.any((file) => file.name == nombreArchivo);
    } catch (e) {
      print("Error al verificar archivo: $e");
      return false;
    }
  }

  Future<void> uploadPDF(String nombreArchivoPDF, PlatformFile linkManifiestoSellado_pc) async {
   try {
      nombreArchivoPDF = ArreglarNombreArchivo(nombreArchivoPDF);
      
      // Verificar si el archivo existe
      final existe = await verificarArchivoExiste(nombreArchivoPDF);
      if (existe) {
        throw Exception('El archivo "$nombreArchivoPDF" ya existe en el servidor.');
      }
      
      if (kIsWeb) {
        final Uint8List? bytes = linkManifiestoSellado_pc.bytes;
        if (bytes == null) {
          throw Exception('El archivo seleccionado no contiene bytes (web).');
        }
        await supabase.storage.from('manifiesto_pdf').uploadBinary( 
          nombreArchivoPDF,
          bytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
      } else {
        final String? path = linkManifiestoSellado_pc.path;
        if (path == null) {
          throw Exception('El archivo seleccionado no tiene ruta válida en plataforma no-web.');
        }
        final file = File(path);
        await supabase.storage.from('manifiesto_pdf').upload(
          nombreArchivoPDF,
          file,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
      }
    } catch (e) {
      print("Error al subir el PDF: $e");
      rethrow;
    }
  }

  /*Future<void> uploadPDF(String nombreArchivoPDF, PlatformFile linkManifiestoSellado_pc) async {
   try {
      nombreArchivoPDF = ArreglarNombreArchivo(nombreArchivoPDF);
      if (kIsWeb) {
        final Uint8List? bytes = linkManifiestoSellado_pc.bytes;
        if (bytes == null) {
          throw Exception('El archivo seleccionado no contiene bytes (web).');
        }
        await supabase.storage.from('manifiesto_pdf').uploadBinary(
          nombreArchivoPDF,
          bytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
      } else {
        final String? p = linkManifiestoSellado_pc.path;
        if (p == null) {
          throw Exception('El archivo seleccionado no tiene ruta válida en plataforma no-web.');
        }
        final file = File(p);
        await supabase.storage.from('manifiesto_pdf').upload(
          nombreArchivoPDF,
          file,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
      }
      
      //return true;
      //return supabase.storage.from('manifiesto_pdf').getPublicUrl(nombreArchivoPDF);
    } catch (e) {
      print("Error al subir el PDF: $e");
      // Re-throw so callers can handle the error appropriately
      rethrow;

      //throw Exception('Error al subir el PDF: $e');
    }
  }*/


  // Poder publicar repetidos con el mismo nombre pero cambiandolos al final (Desactivado)
  /*Future<String> uploadPDF(String nombreArchivoPDF, PlatformFile linkManifiestoSellado_pc) async {
    try {
      nombreArchivoPDF = ArreglarNombreArchivo(nombreArchivoPDF);
      
      // Add timestamp to make filename unique and avoid "already exists" errors
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileNameWithTimestamp = nombreArchivoPDF.replaceFirst(
        RegExp(r'\.pdf$'),
        '_$timestamp.pdf'
      );
      
      if (kIsWeb) {
        final Uint8List bytes = linkManifiestoSellado_pc.bytes!;
        await supabase.storage.from('manifiesto_pdf').uploadBinary( 
          fileNameWithTimestamp,
          bytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
      } else {
        final file = File(linkManifiestoSellado_pc.path!);
        await supabase.storage.from('manifiesto_pdf').upload(
          fileNameWithTimestamp,
          file,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
      }
      
      // Return the public URL with the unique filename
      return supabase.storage.from('manifiesto_pdf').getPublicUrl(fileNameWithTimestamp);
    } catch (e) {
      throw Exception('Error al subir el PDF: $e');
    }
  }*/

  Future<String?> obtenerUrlVisualizacion(String rutaArchivo) async {
    try {
      final String url = await supabase.storage
          .from("manifiesto_pdf")
          .createSignedUrl(rutaArchivo, 3600); // 1 hora de validez
      return url;
    } catch (e) {
      print("Error generando URL: $e");
      return null;
    }
  }

  Future<void> eliminarPDF(String rutaArchivo, int idManifiesto) async {
    try {
      // Establecer el link a null en la base de datos
      await supabase.from('manifiestos').update({
      'id_manifiesto': idManifiesto,
      'link_manifiestos_pdf': null,
    }).eq('id_manifiesto', idManifiesto);
      // Eliminar el archivo del almacenamiento
      await supabase.storage.from('manifiesto_pdf').remove([rutaArchivo]);
    } catch (e) {
      print("Error eliminando archivo: $e");
    }
  }
}