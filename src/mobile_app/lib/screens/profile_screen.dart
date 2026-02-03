import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                   Container(
                     width: 60, height: 60,
                     decoration: const BoxDecoration(color: Color(0xFFE5E5EA), shape: BoxShape.circle),
                     child: const Icon(Icons.person, size: 30, color: Colors.grey),
                   ),
                   const SizedBox(width: 15),
                   const Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text("Diego", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                       Text("diego@example.com", style: TextStyle(color: Colors.grey)),
                     ],
                   ),
                   const Spacer(),
                   const Text("Editar", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            _buildSettingsGroup([
              _buildSettingItem(Icons.security, Colors.blue, "Contraseña y Seguridad"),
              _buildSettingItem(Icons.notifications, Colors.pink, "Notificaciones"),
              _buildSettingItem(Icons.nightlight_round, Colors.indigo, "Modo Oscuro", widget: Switch(value: false, onChanged: (v){})),
            ]),

            const SizedBox(height: 25),

            _buildSettingsGroup([
              _buildSettingItem(Icons.help, Colors.grey, "Ayuda y Soporte"),
            ]),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text("Cerrar Sesión", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("PCS Versión 1.0.2", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(IconData icon, Color color, String label, {Widget? widget}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
              if (widget != null) widget else const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
            ],
          ),
        ),
        const Divider(height: 1, indent: 60),
      ],
    );
  }
}
