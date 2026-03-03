import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  final GlobalKey _qrCardKey = GlobalKey();

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
                DropdownMenuItem(value: '1u',        child: Text('1 Solo Uso')),
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
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _qrCardKey,
              child: QrCardWidget(codeData: code, location: widget.location),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar PNG'),
                  onPressed: () => _downloadCardAsPng(code['code']?.toString() ?? ''),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF32D74B),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir link'),
                  onPressed: () => _shareCardToCloud(code),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
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

  Future<void> _downloadCardAsPng(String code) async {
    try {
      final boundary =
          _qrCardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'pcs_codigo_$code.png')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      _showSnack('Error al descargar imagen', false);
    }
  }

  Future<void> _shareCardToCloud(Map<String, dynamic> codeData) async {
    final codeStr = codeData['code']?.toString() ?? '';
    final name = Uri.encodeComponent(codeData['name']?.toString() ?? '');
    final loc = Uri.encodeComponent(widget.location.isNotEmpty ? widget.location : 'Residencial');
    final dur = codeData['duration']?.toString();
    final hasExpiry = codeData['expires_at'] != null;
    final type = dur == '1u' ? '1_SOLO_USO' : (hasExpiry ? 'TEMPORAL' : 'PERMANENTE');

    // Build shareable URL: /#/qr/CODE?name=...&loc=...&type=...
    final origin = html.window.location.origin;
    final shareUrl = '$origin/#/qr/$codeStr?name=$name&loc=$loc&type=$type';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.share, color: Color(0xFF0A84FF), size: 20),
          SizedBox(width: 8),
          Text('Compartir código',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Comparte este link — cualquier persona puede ver la tarjeta QR.',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: SelectableText(
              shareUrl,
              style: const TextStyle(color: Color(0xFF0A84FF), fontSize: 11),
            ),
          ),
        ]),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Ver tarjeta'),
            onPressed: () {
              Navigator.pop(context);
              html.window.open(shareUrl, '_blank');
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar link'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareUrl));
              Navigator.pop(context);
              _showSnack('Link copiado 📋', true);
            },
          ),
        ],
      ),
    );
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
    return LayoutBuilder(builder: (context, cst) {
      final isMobile = cst.maxWidth < 600;
      return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 28, vertical: isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Mis Códigos de Acceso',
                  style: TextStyle(fontSize: isMobile ? 17 : 22, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add, size: 18),
                label: Text(isMobile ? 'Nuevo' : 'Nuevo Código'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20, vertical: 14),
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
    });
  }
}

class _CodeCard extends StatefulWidget {
  final Map<String, dynamic> codeData;
  final VoidCallback onDelete;
  final VoidCallback onView;
  const _CodeCard({required this.codeData, required this.onDelete, required this.onView});

  @override
  State<_CodeCard> createState() => _CodeCardState();
}

class _CodeCardState extends State<_CodeCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    if (widget.codeData['expires_at'] != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(_updateRemaining);
      });
    }
  }

  void _updateRemaining() {
    final expiresAt = widget.codeData['expires_at'];
    if (expiresAt == null) return;
    final exp = DateTime.fromMillisecondsSinceEpoch((expiresAt as num).toInt());
    final now = DateTime.now();
    _remaining = exp.isAfter(now) ? exp.difference(now) : Duration.zero;
  }

  String _formatRemaining() {
    if (_remaining.inSeconds <= 0) return 'Expirado';
    if (_remaining.inDays > 0) {
      return '${_remaining.inDays}d ${_remaining.inHours.remainder(24)}h ${_remaining.inMinutes.remainder(60)}m';
    }
    if (_remaining.inHours > 0) {
      return '${_remaining.inHours}h ${_remaining.inMinutes.remainder(60)}m ${_remaining.inSeconds.remainder(60)}s';
    }
    if (_remaining.inMinutes > 0) return '${_remaining.inMinutes}m ${_remaining.inSeconds.remainder(60)}s';
    return '${_remaining.inSeconds}s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.codeData['code']?.toString() ?? '';
    final name = widget.codeData['name']?.toString() ?? 'Código';
    final expires = widget.codeData['expires_at'];
    final duration = widget.codeData['duration']?.toString();
    final isOneUse = duration == '1u';
    final typeLabel = isOneUse ? '1 Solo Uso' : expires != null ? 'Temporal' : 'Permanente';
    final typeColor = isOneUse
        ? const Color(0xFFBF5AF2)
        : expires != null
            ? Colors.orange
            : const Color(0xFF32D74B);
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
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.key, color: typeColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis),
                      Text(typeLabel,
                          style: TextStyle(fontSize: 11, color: typeColor)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: widget.onView,
              child: Center(
                child: code.isNotEmpty
                    ? QrImageView(
                        data: code,
                        version: QrVersions.auto,
                        size: 130,
                        backgroundColor: Colors.transparent,
                        eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0A84FF)),
                        dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.white),
                      )
                    : const Icon(Icons.qr_code_2, size: 80, color: Colors.white24),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Text(code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A84FF))),
                if (expires != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 12,
                          color: _remaining.inSeconds > 0 ? Colors.orange : Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        _formatRemaining(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _remaining.inSeconds > 0 ? Colors.orange : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: widget.onView,
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

// ─── QR Card Widget (dark elegant design) ─────────────────────
class QrCardWidget extends StatelessWidget {
  final Map<String, dynamic> codeData;
  final String location;
  const QrCardWidget({super.key, required this.codeData, required this.location});

  String _badgeLabel(String? dur, bool hasExpiry) {
    if (dur == '1u') return '1 SOLO USO';
    if (hasExpiry) return 'TEMPORAL';
    return 'PERMANENTE';
  }

  Color _badgeColor(String? dur, bool hasExpiry) {
    if (dur == '1u') return const Color(0xFFBF5AF2);
    if (hasExpiry) return const Color(0xFFFF9F0A);
    return const Color(0xFF32D74B);
  }

  @override
  Widget build(BuildContext context) {
    final code = codeData['code']?.toString() ?? '';
    final name = codeData['name']?.toString() ?? 'Código';
    final loc = location.isNotEmpty ? location : 'Residencial';
    final dur = codeData['duration']?.toString();
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final hasExpiry = codeData['expires_at'] != null;
    final badgeLbl = _badgeLabel(dur, hasExpiry);
    final badgeClr = _badgeColor(dur, hasExpiry);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1117), Color(0xFF161B22)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0A84FF).withOpacity(0.30),
              blurRadius: 32,
              offset: const Offset(0, 8)),
          const BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFF0A84FF).withOpacity(0.18), width: 1),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF0A0A1A), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(23), topRight: Radius.circular(23)),
          ),
          child: Column(children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF1A84FF), Color(0xFF0055CC)]),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF0A84FF).withOpacity(0.55),
                      blurRadius: 18,
                      spreadRadius: 2)
                ],
              ),
              alignment: Alignment.center,
              child: const Text('PCS',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ),
            const SizedBox(height: 10),
            const Text('PCS ACCESS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3)),
            const SizedBox(height: 2),
            const Text('Control de Acceso Residencial',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        // QR Code
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0A84FF).withOpacity(0.35),
                    blurRadius: 18,
                    spreadRadius: 2)
              ],
            ),
            child: code.isNotEmpty
                ? QrImageView(
                    data: code,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square, color: Color(0xFF0D1117)),
                    dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0D1117)),
                  )
                : const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                        child:
                            Icon(Icons.qr_code_2, size: 80, color: Colors.grey))),
          ),
        ),
        // Info
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(children: [
            _InfoRow(icon: Icons.home, label: loc, color: const Color(0xFF0A84FF)),
            const Divider(height: 12, color: Colors.white12),
            _InfoRow(icon: Icons.person, label: name),
            const Divider(height: 12, color: Colors.white12),
            _InfoRow(icon: Icons.calendar_today, label: dateStr),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badgeClr.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: badgeClr),
              ),
              child: Text(badgeLbl,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: badgeClr)),
            ),
          ]),
        ),
        // Code
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(code,
                style: const TextStyle(
                    fontSize: 36,
                    letterSpacing: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 4),
            const Text('CÓDIGO DE ACCESO',
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 3,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoRow({required this.icon, required this.label, this.color = Colors.white70});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70))),
      ]);
}
