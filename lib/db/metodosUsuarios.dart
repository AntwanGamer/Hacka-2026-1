import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class MetodosUsuarios {
  final supabase = Supabase.instance.client;

  // CREDENCIALES
  final String _supabaseUrl = 'https://awqtmhqspbiouwheekqv.supabase.co';
  final String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3cXRtaHFzcGJpb3V3aGVla3F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NjM4MDEsImV4cCI6MjA3ODUzOTgwMX0.Q_ElSxgAPlXbg5ZRQQhsZtVjWw7-tbqifbeMqWVGWek';

Stream<List<Map<String, dynamic>>> streamUsuarios() {
    return supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        // .eq('activo', true)  <--- 1. BORRA ESTO (Filtro de servidor)
        .order('id', ascending: true)
        .map((rows) => rows
            // 2. AGREGA ESTO (Filtro local en Dart)
            .where((user) => user['activo'] == true) 
            .toList());
  }
  Future<String?> crearUsuarioCompleto({
    required String nombre,
    required String role,
    required String contacto,
    required String email,
    required String password,
  }) async {
    try {
      print("1. Creando Auth...");
      final url = Uri.parse('$_supabaseUrl/auth/v1/signup');
      final response = await http.post(
        url,
        headers: {
          'apikey': _supabaseKey,
          'Authorization': 'Bearer $_supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        return "Error Auth: ${error['msg'] ?? error.toString()}";
      }

      final authData = jsonDecode(response.body);
      final String? newUserId = authData['user']?['id']; 

      if (newUserId == null) return "Error: No se obtuvo ID";

      print("2. Insertando Perfil...");
      await supabase.from('profiles').insert({
        'id': newUserId,
        'email': email,
        'nombre': nombre,
        'rol': role,
        'contacto': contacto,
        'activo': true,
      });

      return null;
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String?> actualizarUsuario(
    String id, {
    required String nombre,
    required String role,
    required String contacto,
    required String email,
  }) async {
    try {
      await supabase.from('profiles').update({
        'nombre': nombre,
        'rol': role,
        'contacto': contacto,
        'email': email,
      }).eq('id', id);
      return null;
    } catch (e) {
      return "Error al actualizar: $e";
    }
  }

  Future<String?> eliminarUsuarioInteligente(String id) async {
    try {
      // Consultamos si tiene manifiestos
      final List<dynamic> manifiestos = await supabase
          .from('manifiestos')
          .select('id_manifiesto')
          .eq('id_usuario', id)
          .limit(1);
      

      if (manifiestos.isNotEmpty) {

        await supabase
            .from('profiles')
            .update({'activo': false})
            .eq('id', id);
        return "Usuario eliminado";
        
      } else {
        print("Usuario limpio. Borrando de Auth y Profiles...");
        
        await supabase.rpc('eliminar_cuenta_total', params: {
          'user_id': id
        });
        return "Usuario eliminado";
      }
    } catch (e) {
      return "Error al procesar: $e";
    }
  }
}