import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, _) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Administra tu información personal', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
            const SizedBox(height: 28),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  children: [
                    // Avatar card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF0055CC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(36),
                            ),
                            child: Center(
                              child: Text(
                                (user.name.isNotEmpty ? user.name[0] : user.username.isNotEmpty ? user.username[0] : '?').toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name.isNotEmpty ? user.name : 'Usuario',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.username,
                                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4)),
                                ),
                                if (user.location.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(Icons.home_outlined, size: 13, color: Colors.white38),
                                    const SizedBox(width: 4),
                                    Text(user.location, style: TextStyle(fontSize: 12, color: Colors.white38)),
                                  ]),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (user.isMainAdmin ? const Color(0xFF0A84FF) : const Color(0xFF32D74B)).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user.isMainAdmin ? 'Administrador' : 'Usuario',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: user.isMainAdmin ? const Color(0xFF0A84FF) : const Color(0xFF32D74B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info section
                    _InfoTile(icon: Icons.alternate_email, label: 'Usuario / Email', value: user.username),
                    _InfoTile(icon: Icons.badge_outlined, label: 'Nombre completo', value: user.name.isNotEmpty ? user.name : '—'),
                    _InfoTile(icon: Icons.home_outlined, label: 'Dirección / Casa', value: user.location.isNotEmpty ? user.location : '—'),
                    _InfoTile(
                      icon: Icons.shield_outlined,
                      label: 'Rol',
                      value: user.isMainAdmin ? 'Administrador' : 'Usuario',
                      valueColor: user.isMainAdmin ? const Color(0xFF0A84FF) : const Color(0xFF32D74B),
                    ),
                    const SizedBox(height: 28),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          user.clearUser();
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                        },
                        icon: const Icon(Icons.logout, color: Color(0xFFFF453A)),
                        label: const Text('Cerrar Sesión', style: TextStyle(color: Color(0xFFFF453A))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF453A)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A84FF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0A84FF), size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor ?? Colors.white)),
          ]),
        ),
      ],
    ),
  );
}
