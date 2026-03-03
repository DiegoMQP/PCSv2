import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class CodesScreen extends StatefulWidget {
  final String username;
  final String location;
  const CodesScreen({super.key, required this.username, required this.location});

  @override
  State<CodesScreen> createState() => _CodesScreenState();
}

class _CodesScreenState extends State<CodesScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() { _future = ApiService().getCodes(widget.username); });

  Future<void> _delete(String code) async {
    final confirm = await _confirmDialog('¿Eliminar este código?');
    if (confirm != true) return;
    final ok = await ApiService().deleteCode(code);
    if (mounted) {
      _showSnack(ok ? 'Código eliminado' : 'Error al eliminar', ok);
      if (ok) _load();
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    String duration = 'permanent';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setDS) => AlertDialog(
        title: const Text('Nuevo Código de Acceso'),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.label_outline))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: duration,
              decoration: const InputDecoration(labelText: 'Duración', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'permanent', child: Text('Permanente')),
                DropdownMenuItem(value: '30m',       child: Text('30 Minutos')),
                DropdownMenuItem(value: '4h',        child: Text('4 Horas')),
                DropdownMenuItem(value: '24h',       child: Text('24 Horas')),
                DropdownMenuItem(value: '1w',        child: Text('1 Semana')),
              ],
              onChanged: (v) => setDS(() => duration = v!),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final code = (100000 + Random().nextInt(900000)).toString();
              final res = await ApiService().saveCode(name: nameCtrl.text, code: code, username: widget.username, duration: duration);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) {
                _load();
                _showQrCard({
                  'code': code,
                  'name': nameCtrl.text,
                  'duration': duration,
                  'status': 'ACTIVE',
                  'host_username': widget.username,
                });
              } else {
                _showSnack(res['message']?.toString() ?? 'Error al guardar', false);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      )),
    );
  }

  void _showQrCard(Map<String, dynamic> code) {
    final qrUrl = code['qr_url']?.toString();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrCardWidget(codeData: code, location: widget.location),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Imprimir'),
                  onPressed: () {}, // Browser handles printing
                ),
                const SizedBox(width: 12),
                if (qrUrl != null) ...
                  [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white),
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir enlace'),
                      onPressed: () => _shareQrUrl(qrUrl),
                    ),
                    const SizedBox(width: 12),
                  ],
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQrUrl(String url) async {
    try {
      await Share.share('Mi código QR de acceso PCS: $url', subject: 'Código QR PCS');
    } catch (_) {
      // Fallback: copy to clipboard
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enlace copiado al portapapeles'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green : Colors.red));
  }

  Future<bool?> _confirmDialog(String msg) => showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mis Códigos de Acceso', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Código'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final codes = snap.data ?? [];
                if (codes.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.qr_code_2, size: 80, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text('No tienes códigos aún', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Crea un código para empezar', style: TextStyle(color: Colors.white24)),
                    ]),
                  );
                }
                return LayoutBuilder(builder: (_, cst) {
                  final cols = cst.maxWidth > 900 ? 3 : cst.maxWidth > 500 ? 2 : 1;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
                    ),
                    itemCount: codes.length,
                    itemBuilder: (_, i) {
                      final cd = Map<String, dynamic>.from(codes[i] as Map);
                      return _CodeCard(
                        codeData: cd,
                        onDelete: () => _delete(cd['code']?.toString() ?? ''),
                        onView: () => _showQrCard(cd),
                      );
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final Map<String, dynamic> codeData;
  final VoidCallback onDelete;
  final VoidCallback onView;
  const _CodeCard({required this.codeData, required this.onDelete, required this.onView});

  @override
  Widget build(BuildContext context) {
    final code = codeData['code']?.toString() ?? '';
    final name = codeData['name']?.toString() ?? 'Código';
    final expires = codeData['expires_at'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.key, color: Color(0xFF0A84FF), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white), overflow: TextOverflow.ellipsis),
                    Text(expires != null ? 'Temporal' : 'Permanente',
                        style: TextStyle(fontSize: 11, color: expires != null ? Colors.orange : const Color(0xFF32D74B))),
                  ],
                )),
                if (codeData['qr_url'] != null)
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFF0A84FF), size: 18),
                    tooltip: 'Compartir enlace QR',
                    onPressed: () async {
                      final url = codeData['qr_url'].toString();
                      try {
                        await Share.share('Mi código QR de acceso PCS: $url', subject: 'Código QR PCS');
                      } catch (_) {
                        await Clipboard.setData(ClipboardData(text: url));
                      }
                    },
                  ),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: onDelete),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onView,
              child: Center(
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 130,
                  backgroundColor: Colors.transparent,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0A84FF)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Text(code, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.w900, color: Color(0xFF0A84FF))),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('Ver tarjeta', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QR Card Widget (same design for web display / print) ────
class QrCardWidget extends StatelessWidget {
  final Map<String, dynamic> codeData;
  final String location;
  const QrCardWidget({super.key, required this.codeData, required this.location});

  @override
  Widget build(BuildContext context) {
    final code = codeData['code']?.toString() ?? '';
    final name = codeData['name']?.toString() ?? 'Código';
    final loc = location.isNotEmpty ? location : 'Residencial';
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final isPermanent = codeData['expires_at'] == null;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E7), Color(0xFFFFECC8), Color(0xFFFFD59A)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)]),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.security, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 8),
            const Text('PCS ACCESS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3)),
            const Text('Control de Acceso Residencial', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
        // QR
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFF1A73E8).withOpacity(0.3), blurRadius: 12, spreadRadius: 2)],
            ),
            child: QrImageView(
              data: code, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0D47A1)),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1A2E)),
            ),
          ),
        ),
        // Info
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(children: [
            _InfoRow(icon: Icons.home, label: loc),
            const Divider(height: 12),
            _InfoRow(icon: Icons.person, label: name),
            const Divider(height: 12),
            _InfoRow(icon: Icons.calendar_today, label: dateStr),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (isPermanent ? Colors.green : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isPermanent ? Colors.green : Colors.orange),
              ),
              child: Text(
                isPermanent ? 'PERMANENTE' : 'TEMPORAL',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1,
                  color: isPermanent ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ]),
        ),
        // Code
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(code, style: const TextStyle(fontSize: 36, letterSpacing: 10, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
            const Text('CÓDIGO DE ACCESO', style: TextStyle(fontSize: 9, letterSpacing: 3, color: Color(0xFF666666), fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: const Color(0xFF1A73E8)),
    const SizedBox(width: 8),
    Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
  ]);
}
