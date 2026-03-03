import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../widgets/qr_card_widget.dart';

class CodesScreen extends StatefulWidget {
  const CodesScreen({super.key});
  @override
  State<CodesScreen> createState() => _CodesScreenState();
}

class _CodesScreenState extends State<CodesScreen> {
  late Future<List<dynamic>> _codesFuture;
  String? _lastUsername;

  @override
  void initState() { super.initState(); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context, listen: false);
    if (user.username.isNotEmpty && user.username != _lastUsername) {
      _lastUsername = user.username;
      _refreshCodes();
    }
  }

  void _refreshCodes() {
    final user = Provider.of<UserProvider>(context, listen: false);
    if (user.username.isEmpty) {
      if (mounted) setState(() { _codesFuture = Future.value([]); });
      return;
    }
    setState(() { _codesFuture = ApiService().getCodes(user.username); });
  }

  Future<void> _deleteCode(String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Eliminar Codigo'),
        ]),
        content: const Text('¿Seguro que deseas eliminar este código? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await ApiService().deleteCode(code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Código eliminado' : 'Error al eliminar'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) _refreshCodes();
    }
  }

  void _showEditDurationDialog(String code, String currentDuration) {
    String selected = currentDuration;
    final options = [
      _DurationOption('permanent', 'Permanente', Icons.all_inclusive, Colors.green),
      _DurationOption('30m', '30 Minutos', Icons.timer, Colors.blue),
      _DurationOption('4h', '4 Horas', Icons.access_time, Colors.orange),
      _DurationOption('24h', '24 Horas', Icons.today, Colors.deepOrange),
      _DurationOption('1w', '1 Semana', Icons.date_range, Colors.purple),
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.schedule, color: Color(0xFF1A73E8)),
            SizedBox(width: 8),
            Text('Editar Duración'),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Selecciona la nueva duración del código:',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 14),
            ...options.map((opt) {
              final isSelected = selected == opt.value;
              return GestureDetector(
                onTap: () => setDS(() => selected = opt.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? opt.color.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? opt.color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(opt.icon, color: isSelected ? opt.color : Colors.grey, size: 20),
                    const SizedBox(width: 10),
                    Text(opt.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: isSelected ? opt.color : null,
                        )),
                    const Spacer(),
                    if (isSelected) Icon(Icons.check_circle, color: opt.color, size: 18),
                  ]),
                ),
              );
            }),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await ApiService().updateCodeDuration(code, selected);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res ? 'Duración actualizada' : 'Error al actualizar'),
                    backgroundColor: res ? Colors.green : Colors.red,
                  ));
                  if (res) _refreshCodes();
                }
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  // ── Add Personal Code ────────────────────────────────────────────────
  void _showAddCodeDialog() {
    final nameCtrl = TextEditingController();
    String duration = 'permanent';
    final options = [
      _DurationOption('permanent', 'Permanente', Icons.all_inclusive, Colors.green),
      _DurationOption('30m', '30 Minutos', Icons.timer, Colors.blue),
      _DurationOption('4h', '4 Horas', Icons.access_time, Colors.orange),
      _DurationOption('24h', '24 Horas', Icons.today, Colors.deepOrange),
      _DurationOption('1w', '1 Semana', Icons.date_range, Colors.purple),
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(children: [
          Icon(Icons.add_box_rounded, color: Color(0xFF0A84FF)),
          SizedBox(width: 8),
          Text('Nuevo Código Personal'),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del código',
                prefixIcon: Icon(Icons.label_outline),
                hintText: 'Ej: Mi casa, Oficina...',
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Duración:', style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(ctx).textTheme.bodySmall?.color,
              )),
            ),
            const SizedBox(height: 8),
            ...options.map((opt) {
              final sel = duration == opt.value;
              return GestureDetector(
                onTap: () => setDS(() => duration = opt.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? opt.color.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? opt.color : Colors.grey.shade600,
                      width: sel ? 1.8 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Icon(opt.icon, color: sel ? opt.color : Colors.grey, size: 18),
                    const SizedBox(width: 10),
                    Text(opt.label, style: TextStyle(
                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                      color: sel ? opt.color : null,
                    )),
                    const Spacer(),
                    if (sel) Icon(Icons.check_circle, color: opt.color, size: 16),
                  ]),
                ),
              );
            }),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Crear Código'),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Ingresa un nombre para el código'),
                ));
                return;
              }
              final user = Provider.of<UserProvider>(context, listen: false);
              final code = (100000 + Random().nextInt(900000)).toString();
              final res = await ApiService().saveCode(
                name: nameCtrl.text.trim(),
                code: code,
                username: user.username,
                duration: duration,
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) {
                _refreshCodes();
                // Show QR card immediately after creation
                _showQrCardDialog({
                  'code': code,
                  'name': nameCtrl.text.trim(),
                  'duration': duration,
                  'status': 'ACTIVE',
                  'host_username': user.username,
                }, user);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res['message']?.toString() ?? 'Error al crear el código'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
        ],
      )),
    );
  }

  void _showQrCardDialog(Map<String, dynamic> codeData, UserProvider user) {
    final code = codeData['code']?.toString() ?? '';
    final cardKey = GlobalKey();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          RepaintBoundary(
            key: cardKey,
            child: QrCardWidget(codeData: codeData, user: user),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar'),
                onPressed: () => copyCode(code, ctx),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Compartir'),
                onPressed: () => captureAndShare(cardKey, code, ctx),
              ),
              if (codeData['qr_url'] != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Compartir enlace'),
                  onPressed: () async {
                    final url = codeData['qr_url'].toString();
                    try {
                      await Share.share('Mi código QR PCS: $url', subject: 'Código QR PCS');
                    } catch (_) {
                      await Clipboard.setData(ClipboardData(text: url));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Enlace copiado'), backgroundColor: Colors.teal),
                        );
                      }
                    }
                  },
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cerrar'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Códigos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _refreshCodes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCodeDialog,
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Código', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _codesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final codes = snapshot.data ?? [];
          if (codes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.qr_code_2, size: 60, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  Text('Sin códigos activos',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Genera un código de acceso personal pulsando el botón +',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A84FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo Código'),
                    onPressed: _showAddCodeDialog,
                  ),
                ]),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refreshCodes(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              itemCount: codes.length,
              itemBuilder: (context, i) {
                final cd = Map<String, dynamic>.from(codes[i] as Map);
                return _CodeCard(
                  codeData: cd,
                  user: user,
                  onDelete: () => _deleteCode(cd['code']?.toString() ?? ''),
                  onEdit: () => _showEditDurationDialog(
                      cd['code']?.toString() ?? '',
                      cd['duration']?.toString() ?? 'permanent'),
                  onShowCard: () => _showQrCardDialog(cd, user),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DurationOption {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _DurationOption(this.value, this.label, this.icon, this.color);
}

class _CodeCard extends StatelessWidget {
  final Map<String, dynamic> codeData;
  final UserProvider user;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onShowCard;

  const _CodeCard({
    required this.codeData,
    required this.user,
    required this.onDelete,
    required this.onEdit,
    required this.onShowCard,
  });

  @override
  Widget build(BuildContext context) {
    final code = codeData['code']?.toString() ?? '';
    final name = codeData['name']?.toString() ?? 'Codigo';
    final expiresAt = codeData['expires_at'];
    final isPermanent = expiresAt == null;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.key, color: primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                isPermanent
                    ? Row(children: const [
                        Icon(Icons.all_inclusive, size: 12, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Permanente', style: TextStyle(fontSize: 11, color: Colors.green)),
                      ])
                    : Row(children: [
                        Icon(Icons.schedule, size: 12, color: Colors.orange.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Expira: ${DateTime.fromMillisecondsSinceEpoch((expiresAt as num).toInt()).toLocal().toString().substring(0, 16)}',
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
                        ),
                      ]),
              ]),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: primary, size: 20),
              tooltip: 'Editar duración',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              tooltip: 'Eliminar',
              onPressed: onDelete,
            ),
          ]),
        ),
        // QR preview
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: GestureDetector(
            onTap: onShowCard,
            child: QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 150.0,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        // Code + action bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.07),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                code,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26, letterSpacing: 6, fontWeight: FontWeight.w800, color: primary),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onShowCard,
              icon: const Icon(Icons.qr_code, size: 15),
              label: const Text('Ver / Compartir', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
      ]),
    );
  }
}
