import 'package:flutter/material.dart';

void main() {
  runApp(const MiAppTecnica());
}

class MiAppTecnica extends StatelessWidget {
  const MiAppTecnica({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Technical Stewardship',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Segoe UI', // O la fuente que prefieras
      ),
      home: const InicioSesion2(),
    );
  }
}

class InicioSesion2 extends StatelessWidget {
  const InicioSesion2({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para detectar el tamaño de la pantalla
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1D3E3B),
              Color(0xFF2D5A56),
              Color(0xFF5A8F89),
              Color(0xFF3B6B66),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- CABECERA ---
                  const Text(
                    'Administración Técnica',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    'EL CONSERVADOR DE PRECISIÓN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- TARJETA RESPONSIVA ---
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 450,
                    ), // Ancho máximo para escritorio
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardHeader(),
                          const SizedBox(height: 30),
                          _buildLabel("CORREO ELECTRÓNICO"),
                          const SizedBox(height: 8),
                          _buildTextField(Icons.blur_on, "TS-000-0000"),
                          const SizedBox(height: 25),
                          _buildLabelWithAction(
                            "CONTRASEÑA",
                            "¿Olvidó su contraseña?",
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            Icons.shield_outlined,
                            "••••••••",
                            obscure: true,
                          ),
                          const SizedBox(height: 35),
                          _buildLoginButton(),
                          const SizedBox(height: 35),
                          _buildVisitorLink(),
                          const SizedBox(height: 15),
                          _buildFooterLink(
                            "¿Nuevo operativo?",
                            "Solicitar Acceso",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                  _buildSystemStatus(),
                  const SizedBox(height: 20),
                  _buildBottomLegal(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE APOYO (Para limpiar el código principal) ---

  Widget _buildCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Terminal de Acceso',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFB2DFDB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_user, size: 14, color: Color(0xFF00695C)),
              SizedBox(width: 5),
              Text(
                'ACCESO SEGURO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00695C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildLabelWithAction(String label, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLabel(label),
        GestureDetector(
          onTap: () {},
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(IconData icon, String hint, {bool obscure = false}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF1F4F8),
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF004D40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Iniciar Sesión',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorLink() {
    return Center(
      child: InkWell(
        onTap: () {},
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 16, color: Color(0xFF004D40)),
            SizedBox(width: 6),
            Text(
              '¿Eres un visitante? Acceso Invitado',
              style: TextStyle(
                color: Color(0xFF004D40),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink(String normalText, String boldText) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: '$normalText ',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
          children: [
            TextSpan(
              text: boldText,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.sensors, size: 14, color: Colors.white54),
        SizedBox(width: 5),
        Text(
          'EOS-17 ESTABLE',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 25),
        Icon(Icons.dns, size: 14, color: Colors.white54),
        SizedBox(width: 5),
        Text(
          'NODO: LDN-04',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomLegal() {
    return Column(
      children: [
        const Text(
          '© 2026 ADMINISTRACIÓN TÉCNICA. MONITOREO AMBIENTAL DE PRECISIÓN.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legalText('POLÍTICA DE PRIVACIDAD'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('•', style: TextStyle(color: Colors.white38)),
            ),
            _legalText('ESTADO DEL SISTEMA'),
          ],
        ),
      ],
    );
  }

  Widget _legalText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
//API: AIzaSyAnhtlifpQiNlLGMmF9kEsgOmuZgrVI06I