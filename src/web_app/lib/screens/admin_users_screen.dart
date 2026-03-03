import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<dynamic>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() { _future = ApiService().getUsers(); });

  void _showAddUser() {
    final usernameCtrl   = TextEditingController();
    final passwordCtrl   = TextEditingController();
    final nameCtrl       = TextEditingController();
    final locationCtrl   = TextEditingController();
    String role          = 'user';
    bool obscure         = true;
    final formKey        = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setDS) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.person_add, color: Color(0xFF0A84FF)),
          SizedBox(width: 10),
          Text('Nuevo Usuario'),
        ]),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre Completo *', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'Usuario (email o identificador) *', prefixIcon: Icon(Icons.alternate_email)),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDS(() => obscure = !obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección / Casa (Ej: C 053)',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'user',  child: Text('Usuario')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (v) => setDS(() => role = v!),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Crear Usuario'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final res = await ApiService().createUser(
                username: usernameCtrl.text.trim(),
                password: passwordCtrl.text,
                name: nameCtrl.text.trim(),
                location: locationCtrl.text.trim(),
                role: role,
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res['success'] == true ? 'Usuario creado exitosamente' : res['message']?.toString() ?? 'Error'),
                backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
              ));
              if (res['success'] == true) _load();
            },
          ),
        ],
      )),
    );
  }

  void _showEditUser(Map u) {
    final usernameCtrl = TextEditingController(text: u['username']?.toString() ?? '');
    final nameCtrl     = TextEditingController(text: u['name']?.toString() ?? '');
    final locationCtrl = TextEditingController(text: u['location']?.toString() ?? '');
    final passwordCtrl = TextEditingController();
    String role        = u['role']?.toString() ?? 'user';
    bool obscure       = true;
    final formKey      = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setDS) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.edit_outlined, color: Color(0xFF0A84FF)),
          SizedBox(width: 10),
          Text('Editar Usuario'),
        ]),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.badge_outlined)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Usuario / Email',
                  prefixIcon: Icon(Icons.alternate_email),
                  helperText: 'Cambiar esto invalidará la sesión del usuario',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña (dejar vacío para no cambiar)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDS(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección / Casa',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'user',  child: Text('Usuario')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (v) => setDS(() => role = v!),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Guardar Cambios'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final original = u['username']?.toString() ?? '';
              final res = await ApiService().updateUser(
                username:    original,
                newUsername: usernameCtrl.text.trim() != original ? usernameCtrl.text.trim() : null,
                password:    passwordCtrl.text.isNotEmpty ? passwordCtrl.text : null,
                name:        nameCtrl.text.trim(),
                location:    locationCtrl.text.trim(),
                role:        role,
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res['success'] == true ? 'Usuario actualizado' : res['message']?.toString() ?? 'Error'),
                backgroundColor: res['success'] == true ? Colors.green : Colors.red,
                behavior: SnackBarBehavior.floating,
              ));
              if (res['success'] == true) _load();
            },
          ),
        ],
      )),
    );
  }

  Future<void> _deleteUser(String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de que deseas eliminar al usuario "$username"?\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ApiService().deleteUser(username);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Usuario eliminado' : 'Error al eliminar'),
        backgroundColor: ok ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      if (ok) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gestión de Usuarios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('Agrega y administra usuarios del sistema para pruebas.',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddUser,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Nuevo Usuario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar usuarios...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white12)),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
          const SizedBox(height: 20),

          // List
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Error al cargar usuarios', style: TextStyle(color: Colors.red.shade400)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
                  ]));
                }
                final all = snap.data ?? [];
                final users = all.where((u) {
                  if (_search.isEmpty) return true;
                  final username = u['username']?.toString().toLowerCase() ?? '';
                  final name     = u['name']?.toString().toLowerCase() ?? '';
                  final location = u['location']?.toString().toLowerCase() ?? '';
                  return username.contains(_search) || name.contains(_search) || location.contains(_search);
                }).toList();

                if (users.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      _search.isNotEmpty ? 'No se encontraron usuarios' : 'No hay usuarios registrados',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    if (_search.isEmpty) ...[          
                      const SizedBox(height: 8),
                      Text('Presiona "Nuevo Usuario" para agregar uno', style: TextStyle(color: Colors.white24, fontSize: 13)),
                    ],
                  ]));
                }

                // Stats bar
                return Column(
                  children: [
                    // Stats
                    Row(children: [
                      _CountBadge('${all.length} usuarios totales', const Color(0xFF0A84FF)),
                      const SizedBox(width: 8),
                      _CountBadge('${all.where((u) => u['role'] == 'admin').length} admins', const Color(0xFFFF453A)),
                      const SizedBox(width: 8),
                      _CountBadge('${all.where((u) => u['role'] != 'admin').length} usuarios', const Color(0xFF32D74B)),
                    ]),
                    const SizedBox(height: 16),
                    Expanded(
                      child: LayoutBuilder(builder: (_, cst) {
                        final cols = cst.maxWidth > 900 ? 3 : cst.maxWidth > 550 ? 2 : 1;
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.2,
                          ),
                          itemCount: users.length,
                          itemBuilder: (_, i) {
                            final u = users[i] as Map;
                            final username = u['username']?.toString() ?? '-';
                            final name     = u['name']?.toString() ?? username;
                            final location = u['location']?.toString() ?? '';
                            final role     = u['role']?.toString() ?? 'user';
                            final isAdmin  = role == 'admin';
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isAdmin ? const Color(0xFF0A84FF).withOpacity(0.3) : Colors.white.withOpacity(0.07)),
                              ),
                              child: Row(children: [
                                // Avatar
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: (isAdmin ? const Color(0xFF0A84FF) : const Color(0xFF32D74B)).withOpacity(0.15),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin ? const Color(0xFF0A84FF) : const Color(0xFF32D74B),
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white), overflow: TextOverflow.ellipsis),
                                    Text(username, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)), overflow: TextOverflow.ellipsis),
                                    if (location.isNotEmpty)
                                      Row(children: [
                                        Icon(Icons.home_outlined, size: 11, color: Colors.white38),
                                        const SizedBox(width: 3),
                                        Text(location, style: TextStyle(fontSize: 11, color: Colors.white38), overflow: TextOverflow.ellipsis),
                                      ]),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (isAdmin ? const Color(0xFF0A84FF) : const Color(0xFF32D74B)).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isAdmin ? 'Admin' : 'Usuario',
                                        style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.w600,
                                          color: isAdmin ? const Color(0xFF0A84FF) : const Color(0xFF32D74B),
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF0A84FF), size: 20),
                                  onPressed: () => _showEditUser(users[i] as Map),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => _deleteUser(username),
                                  tooltip: 'Eliminar',
                                ),
                              ]),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _CountBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  );
}
