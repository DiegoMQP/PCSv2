import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We already moved theme logic to main.dart system settings
    // But for "checkbox mode" requesting user, we should probably check if we can toggle ThemeMode
    // However, user said "checkbox doesn't work". Since we use system mode in main.dart, we need a ThemeProvider if we want manual toggle.
    // For now, let's just make sure containers use Theme colors (grey/card color) instead of white.
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Perfil")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Consumer<UserProvider>(
               builder: (context, user, _) {
                 return Column(
                  children: [
                    // Profile Card
                    Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color, // Use theme card color (Grey in Dark mode)
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    children: [
                       Container(
                         width: 60, height: 60,
                         decoration: BoxDecoration(color: Theme.of(context).disabledColor.withOpacity(0.2), shape: BoxShape.circle),
                         child: const Icon(Icons.person, size: 30, color: Colors.grey),
                       ),
                       const SizedBox(width: 15),
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(user.name.isNotEmpty ? user.name : "Usuario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
                           Text(user.username.isNotEmpty ? user.username : "usuario@email.com", style: const TextStyle(color: Colors.grey)),
                         ],
                       ),
                       const Spacer(),
                       // Text("Editar", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                _buildSettingsGroup(context, [
                  _buildSettingItem(context, Icons.security, Colors.blue, "Contraseña y Seguridad"),
                  _buildSettingItem(context, Icons.notifications, Colors.pink, "Notificaciones"),
                  // Manual dark mode toggle requires global state manager for ThemeMode. 
                  // Assuming system theme is sufficient or user wants to force it.
                  // _buildSettingItem(context, Icons.nightlight_round, Colors.indigo, "Modo Oscuro", 
                  //  widget: Switch(value: Theme.of(context).brightness == Brightness.dark, onChanged: (v) {})
                  //),
                ]),

                const SizedBox(height: 25),

                _buildSettingsGroup(context, [
                  _buildSettingItem(context, Icons.help, Colors.grey, "Ayuda y Soporte"),
                ]),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                         Provider.of<UserProvider>(context, listen: false).clearUser();
                         Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).cardTheme.color,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("Cerrar Sesión", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("PCS Versión 1.0.3", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            );
          }
         )
        ),
      ),
    ));
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color, // Theme color
          borderRadius: BorderRadius.circular(12)
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, Color color, String label, {Widget? widget}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                 padding: const EdgeInsets.all(6),
                 decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                 child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyMedium?.color))),
              if (widget != null) widget else const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
            ],
          ),
        ),
        Divider(height: 1, indent: 50, color: Theme.of(context).dividerColor),
      ],
    );
  }
}
