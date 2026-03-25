import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zombie/main.dart'; // Contiene MyApp
import 'package:zombie/widgets/main_shell.dart';
import 'package:provider/provider.dart';
import 'package:zombie/Screens/asociacionesRecolectoras.dart';
import 'package:zombie/Screens/reciboBasuron.dart';
import 'package:zombie/db/reciboBasuronDatabase.dart';

// Agrega esta clase al final si la necesitas para el Provider, 
// aunque en esta solución usaremos el constructor directo.
class UserProvider extends ChangeNotifier {
  String _rol = '';
  String get rol => _rol;
  void setRol(String nuevoRol) {
    _rol = nuevoRol;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INICIALIZAR SUPABASE
  await Supabase.initialize(
    url: 'https://awqtmhqspbiouwheekqv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3cXRtaHFzcGJpb3V3aGVla3F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NjM4MDEsImV4cCI6MjA3ODUzOTgwMX0.Q_ElSxgAPlXbg5ZRQQhsZtVjWw7-tbqifbeMqWVGWek',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AsociacionesDatabase()),
        ChangeNotifierProvider(create: (context) => ReciboBasuronDatabase()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const LoginApp(),
    ),
  );
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DCK Conocimiento y Cultura',
      theme: ThemeData(
        useMaterial3: true,
        // Usamos un color semilla para que coincida con el verde DCK
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 113, 192, 105)),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Lógica de Inicio de Sesión
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user == null) throw "Error de autenticación";

      final data = await supabase
          .from('profiles')
          .select('rol')
          .eq('id', response.user!.id)
          .maybeSingle();

      String rol = data != null ? data['rol'] : 'usuario';

      if (!mounted) return;

      print("Login exitoso. Rol: $rol"); 
      
      // Opcional: Si quieres seguir usando el provider para otras cosas, déjalo,
      // pero para la navegación usaremos el paso directo abajo.
      try {
         Provider.of<UserProvider>(context, listen: false).setRol(rol);
      } catch (e) {
         print("Nota: Provider no encontrado, pero seguimos con navegación directa.");
      }

      // 2. MODIFICAR CONDICIÓN PARA DEJAR PASAR AL CAPTURISTA
      if (rol == 'Admin' || rol == 'Capturista') {
        Navigator.pushReplacement(
            context, 
            MaterialPageRoute(
              // --> AQUÍ PASAMOS EL ROL A MYAPP <--
              builder: (_) => MyApp(rolUsuario: rol) 
            )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes permisos para acceder'), backgroundColor: Colors.orange),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Bienvenido $rol'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // OBTENER EL TEMA ACTUAL
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background, 
      body: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          constraints: const BoxConstraints(maxWidth: 2000),
          child: Row(
            children: [
              // --- PARTE IZQUIERDA: FORMULARIO DE LOGIN ---
              const SizedBox(width: 300),
              SizedBox(
                width: 700,
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  bottom: 3,
                                  child: const CircleAvatar(
                                    radius: 8,
                                    backgroundColor: Color.fromARGB(255, 15, 139, 32),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  bottom: 3,
                                  child: CircleAvatar(
                                    radius: 8,
                                    backgroundColor: colorScheme.primary.withOpacity(0.7),
                                  ),
                                ),
                                Positioned(
                                  left: 30,
                                  top: 0,
                                  child: Text(
                                    'DCK',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25)
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Conocimiento y cultura',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Título
                      Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Campo Email
                      Text(
                        'Usuario o correo',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                      ),
                      TextField(
                        controller: _emailController,
                        style: TextStyle(color: colorScheme.onBackground),
                        decoration: InputDecoration(
                          hintText: 'correoejemplo@ejemplo.com',
                          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: colorScheme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Campo Contraseña
                      Text(
                        'Contraseña',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                      ),
                      Stack(
                        children: [
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: TextStyle(color: colorScheme.onBackground),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Botón Login
                      _isLoading
                          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                          : ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 50),
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 200),

              // --- PARTE DERECHA: FONDO VERDE/NATURAL ---
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    image: DecorationImage( 
                      image: const AssetImage('lib/assets/fondoInicioSesion.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.1), BlendMode.darken),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surface,
                          ),
                          child: Center(
                            child: Image.asset(
                              'lib/assets/DCKLogoSinFondo.png',
                              height: 250,
                              width: 200,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}