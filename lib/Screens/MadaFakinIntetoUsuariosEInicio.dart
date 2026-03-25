import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

await Supabase.initialize(
    url: 'https://awqtmhqspbiouwheekqv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3cXRtaHFzcGJpb3V3aGVla3F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NjM4MDEsImV4cCI6MjA3ODUzOTgwMX0.Q_ElSxgAPlXbg5ZRQQhsZtVjWw7-tbqifbeMqWVGWek', 
    );

  runApp(MaterialApp(home: LoginPage()));
}

// ---------------------- LOGIN ----------------------

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(), // trim() quita espacios accidentales
        password: passController.text.trim(),
      );

      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Iniciar Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passController, decoration: InputDecoration(labelText: 'Contraseña (mín 6 caracteres)'), obscureText: true),
            SizedBox(height: 20),
            isLoading 
              ? CircularProgressIndicator() 
              : ElevatedButton(onPressed: login, child: Text("Entrar")),
          ],
        ),
      ),
    );
  }
}

// ---------------------- HOME ----------------------

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  String rol = '';

  @override
  void initState() {
    super.initState();
    cargarRol();
  }

  Future<void> cargarRol() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
        return;
    }

    // Pequeña espera para dar tiempo al Trigger de ejecutarse si acabamos de registrarnos
    await Future.delayed(Duration(seconds: 1)); 

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle(); // maybeSingle evita crashes

      if (response == null) {
        // Si entra aquí, el trigger falló o fue muy lento
        print("Perfil no encontrado, recargando...");
        await Future.delayed(Duration(seconds: 2));
        cargarRol(); // Reintentar una vez más
        return;
      }

      setState(() => rol = response['rol'] ?? 'usuario');
    } catch (e) {
      print("Error cargando rol: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rol.isEmpty) return Scaffold(body: Center(child: CircularProgressIndicator()));
    return rol == 'admin' ? AdminPage() : CapturistaPage();
  }
}

// ---------------------- ADMIN ----------------------

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final supabase = Supabase.instance.client;
  bool isLoading = false; // Variable para controlar el círculo de carga

  Future<void> crearUsuario() async {
    // 1. Validación local
    if (password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() => isLoading = true); // Ahora sí funciona setState

    // DATOS DE TU PROYECTO (Asegúrate que sean los mismos de tu main)
    const supabaseUrl = 'https://awqtmhqspbiouwheekqv.supabase.co'; 
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3cXRtaHFzcGJpb3V3aGVla3F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NjM4MDEsImV4cCI6MjA3ODUzOTgwMX0.Q_ElSxgAPlXbg5ZRQQhsZtVjWw7-tbqifbeMqWVGWek';

    try {
      // 2. Petición HTTP "Fantasma" para no cerrar sesión
      final url = Uri.parse('$supabaseUrl/auth/v1/signup');
      
      final response = await http.post(
        url,
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey', 
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.text.trim(),
          'password': password.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Capturista creado exitosamente!')),
        );
        // Limpiar campos
        email.clear();
        password.clear();
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${errorData['msg'] ?? "No se pudo crear"}')),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    } finally {
      // Apagamos el círculo de carga
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout), 
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
            }
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Crear Nuevo Usuario (Sin cerrar sesión)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(controller: email, decoration: InputDecoration(labelText: 'Email nuevo')),
            TextField(controller: password, decoration: InputDecoration(labelText: 'Contraseña (mín 6)')),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: crearUsuario,
                    child: Text("Registrar"),
                  ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- CAPTURISTA ----------------------

class CapturistaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Capturista"),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: () async {
             await Supabase.instance.client.auth.signOut();
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
          })
        ],
      ),
      body: Center(child: Text("Bienvenido capturista", style: TextStyle(fontSize: 22))),
    );
  }
}