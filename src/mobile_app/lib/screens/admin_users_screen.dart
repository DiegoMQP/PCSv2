import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl     = TextEditingController();
    final locationCtrl = TextEditingController();
    String role        = 'user';
    bool obscure       = true;
    final formKey      = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setDS) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.person_add, color: Color(0xFF0A84FF)),
          const SizedBox(width: 10),
          Text(ctx.tr('new_user')),
        ]),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: ctx.tr('full_name_label'), prefixIcon: const Icon(Icons.badge_outlined)),
                  validator: (v) => (v == null || v.isEmpty) ? ctx.tr('required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usernameCtrl,
                  decoration: InputDecoration(labelText: ctx.tr('user_email'), prefixIcon: const Icon(Icons.alternate_email)),
                  validator: (v) => (v == null || v.isEmpty) ? ctx.tr('required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: ctx.tr('password_admin'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDS(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 4) ? ctx.tr('min_chars') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    labelText: ctx.tr('location_admin'),
                    prefixIcon: const Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: InputDecoration(labelText: ctx.tr('role'), border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'user',  child: Text(ctx.tr('user_role'))),
                    DropdownMenuItem(value: 'admin', child: Text(ctx.tr('admin_role'))),
                  ],
                  onChanged: (v) => setDS(() => role = v!),
                ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel'))),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(ctx.tr('create')),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A84FF), foregroundColor: Colors.white),
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
                content: Text(res['success'] == true ? context.trStatic('user_created') : res['message']?.toString() ?? context.trStatic('error')),
                backgroundColor: res['success'] == true ? Colors.green : Colors.red,
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
        title: Row(children: [
          const Icon(Icons.edit_outlined, color: Color(0xFF0A84FF)),
          const SizedBox(width: 10),
          Text(ctx.tr('edit_user')),
        ]),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(labelText: ctx.tr('full_name_label'), prefixIcon: const Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usernameCtrl,
                  decoration: InputDecoration(
                    labelText: ctx.tr('user_email'),
                    prefixIcon: const Icon(Icons.alternate_email),
                    helperText: ctx.tr('user_change_warning'),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? ctx.tr('required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: ctx.tr('new_password_hint'),
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
                  decoration: InputDecoration(
                    labelText: ctx.tr('house_address'),
                    prefixIcon: const Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: InputDecoration(labelText: ctx.tr('role'), border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'user',  child: Text(ctx.tr('user_role'))),
                    DropdownMenuItem(value: 'admin', child: Text(ctx.tr('admin_role'))),
                  ],
                  onChanged: (v) => setDS(() => role = v!),
                ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel'))),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(ctx.tr('save')),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A84FF), foregroundColor: Colors.white),
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
                content: Text(res['success'] == true ? context.trStatic('user_updated') : res['message']?.toString() ?? context.trStatic('error')),
                backgroundColor: res['success'] == true ? Colors.green : Colors.red,
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
        title: Text(context.tr('delete_user')),
        content: Text(context.tr('delete_user_confirm').replaceFirst('{name}', username)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ApiService().deleteUser(username);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? context.trStatic('user_deleted') : context.trStatic('error_deleting_user')),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manage_users')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: context.tr('refresh')),
          IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: _showAddUser, tooltip: context.tr('add')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: context.tr('search_user'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(context.tr('error_load_users')),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _load, child: Text(context.tr('retry'))),
                  ]));
                }
                final all = snap.data ?? [];
                final users = all.where((u) {
                  if (_search.isEmpty) return true;
                  final username = u['username']?.toString().toLowerCase() ?? '';
                  final name     = u['name']?.toString().toLowerCase() ?? '';
                  return username.contains(_search) || name.contains(_search);
                }).toList();

                if (users.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(_search.isNotEmpty ? context.tr('no_results') : context.tr('no_users'),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                    if (_search.isEmpty) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddUser,
                        icon: const Icon(Icons.person_add_outlined),
                        label: Text(context.tr('add_user')),
                      ),
                    ]
                  ]));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        _Badge('${all.length} totales', const Color(0xFF0A84FF)),
                        const SizedBox(width: 8),
                        _Badge('${all.where((u) => u['role'] == 'admin').length} admins', Colors.red),
                        const SizedBox(width: 8),
                        _Badge('${all.where((u) => u['role'] != 'admin').length} usuarios', Colors.green),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    ...users.map((u) {
                      final user     = u as Map;
                      final username = user['username']?.toString() ?? '-';
                      final name     = user['name']?.toString() ?? username;
                      final location = user['location']?.toString() ?? '';
                      final isAdmin  = user['role']?.toString() == 'admin';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAdmin
                                ? const Color(0xFF0A84FF).withOpacity(0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: (isAdmin ? const Color(0xFF0A84FF) : Colors.green).withOpacity(0.15),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isAdmin ? const Color(0xFF0A84FF) : Colors.green,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis),
                              Text(username, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                              if (location.isNotEmpty)
                                Row(children: [
                                  Icon(Icons.home_outlined, size: 11, color: Colors.grey.shade400),
                                  const SizedBox(width: 3),
                                  Text(location, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                ]),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isAdmin ? const Color(0xFF0A84FF) : Colors.green).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAdmin ? context.tr('admin_role') : context.tr('user_role'),
                                  style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w600,
                                    color: isAdmin ? const Color(0xFF0A84FF) : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          )),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0A84FF), size: 20),
                            onPressed: () => _showEditUser(user),
                            tooltip: context.tr('edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _deleteUser(username),
                            tooltip: context.tr('delete'),
                          ),
                        ]),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUser,
        icon: const Icon(Icons.person_add_outlined),
        label: Text(context.tr('new_user')),
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  );
}
