import 'package:flutter/material.dart';

// --- CONSTANTES DE COLOR GLOBALES (Para evitar errores de nombre no definido) ---
const Color kPrimaryColor = Color(0xFF004D40); // Verde oscuro
const Color kAccentColor = Color(0xFF00897B); // Teal
const Color kBgColor = Color(0xFFE0F2F1); // Fondo menta suave
const Color kInputColor = Color(0xFFE8F5E9); // Fondo de inputs

void main() {
  runApp(
    const MaterialApp(
      home: RegistroOrganizacion(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class RegistroOrganizacion extends StatelessWidget {
  const RegistroOrganizacion({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 900;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? width * 0.05 : 20,
            vertical: 30,
          ),
          child: Column(
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildSidebar()),
                    const SizedBox(width: 40),
                    Expanded(
                      flex: 2,
                      child: _buildFormContent(context, isDesktop),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildSidebar(),
                    const SizedBox(height: 30),
                    _buildFormContent(context, isDesktop),
                  ],
                ),
              const SizedBox(height: 50),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES DE LA INTERFAZ ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: const Row(
        children: [
          Text(
            'EcoMonitor',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(width: 30),
          Row(
            children: [
              _NavLabel('Dashboard'),
              _NavLabel('Ecosystems'),
              _NavLabel('Reports'),
              _NavLabel('Settings'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.headset_mic, size: 18, color: Colors.black54),
          label: const Text(
            'SUPPORT',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
        const Icon(Icons.notifications_none, color: Colors.black54),
        const SizedBox(width: 15),
        const CircleAvatar(
          radius: 15,
          backgroundColor: kPrimaryColor,
          child: Icon(Icons.person, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 15),
      ],
    );
  }

  Widget _buildSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registro de\nOrganización',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Ingrese los datos técnicos y operativos de su empresa para iniciar el monitoreo ambiental con precisión quirúrgica.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 30),
        _buildInfoCard(
          Icons.verified_user,
          'ESTÁNDAR ISO 14001',
          'Protocolos alineados con normativas internacionales de gestión ambiental.',
        ),
        const SizedBox(height: 15),
        _buildInfoCard(
          Icons.sensors,
          'MONITOREO INDUSTRIAL',
          'Integración directa con sensores de campo y telemetría avanzada.',
        ),
        const SizedBox(height: 30),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco, color: Colors.white, size: 50),
                Text(
                  'SAF ERUMIINA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(BuildContext context, bool isDesktop) {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Perfil Corporativo',
          icon: Icons.business,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'RAZÓN SOCIAL',
                      'Ej: Industria Petroquímica S.A.',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInput(
                      'NIT / IDENTIFICACIÓN FISCAL',
                      '900.000.000-1',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildInput(
                'SECTOR INDUSTRIAL',
                'Manufactura Pesada',
                isDropdown: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: 'Ubicación Operativa',
          icon: Icons.location_on,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildInput('DIRECCIÓN PRINCIPAL', 'Calle 100 # 15-20'),
                    const SizedBox(height: 15),
                    _buildInput('CIUDAD', 'Bogotá D.C.'),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildInput('LATITUD', '4.7110')),
                        const SizedBox(width: 15),
                        Expanded(child: _buildInput('LONGITUD', '-74.0721')),
                      ],
                    ),
                  ],
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://via.placeholder.com/300x200?text=Mapa+Ubicación',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: 'Contacto Técnico',
          icon: Icons.contact_mail,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'NOMBRE DEL RESPONSABLE',
                      'Ing. Carlos Mendoza',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInput('CARGO', 'Director de Sostenibilidad'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      'CORREO ELECTRÓNICO',
                      'carlos.m@empresa.com',
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(child: _buildInput('TELÉFONO', '+57 300 000 0000')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.bolt, color: Colors.white),
            label: const Text(
              'FINALIZAR REGISTRO Y ACTIVAR MONITOREO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kAccentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: kPrimaryColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          child,
        ],
      ),
    );
  }

  Widget _buildInput(String label, String hint, {bool isDropdown = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          readOnly: isDropdown,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.black26),
            filled: true,
            fillColor: kInputColor,
            suffixIcon: isDropdown
                ? const Icon(Icons.keyboard_arrow_down)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Divider(),
        SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 20,
          runSpacing: 10,
          children: [
            Text(
              '© 2026 PRECISION CONSERVATOR ECOSYSTEMS. ALL RIGHTS RESERVED.',
              style: TextStyle(fontSize: 10, color: Colors.black38),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FooterLink('PRIVACY POLICY'),
                SizedBox(width: 15),
                _FooterLink('TERMS OF SERVICE'),
                SizedBox(width: 15),
                _FooterLink('TECHNICAL DOCS'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// --- WIDGETS PRIVADOS ---

class _NavLabel extends StatelessWidget {
  final String label;
  const _NavLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Text(
        label,
        style: const TextStyle(color: Colors.black54, fontSize: 13),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: kAccentColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
