import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/user_provider.dart';

// ─────────────────────────────────────────────
// Shared utility: capture widget as PNG & share
// ─────────────────────────────────────────────
Future<void> captureAndShare(
    GlobalKey key, String code, BuildContext context) async {
  try {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pcs_access_$code.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Mi código de acceso PCS: $code',
      subject: 'Código de Acceso PCS',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error al compartir la imagen'),
            backgroundColor: Colors.red),
      );
    }
  }
}

// ─────────────────────────────────────────────
// Shared utility: copy code to clipboard
// ─────────────────────────────────────────────
Future<void> copyCode(String code, BuildContext context) async {
  await Clipboard.setData(ClipboardData(text: code));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Código copiado al portapapeles'),
          backgroundColor: Colors.green),
    );
  }
}

// ─────────────────────────────────────────────
// QR Card Widget (shareable visual card)
// ─────────────────────────────────────────────
class QrCardWidget extends StatelessWidget {
  final Map<String, dynamic> codeData;
  final UserProvider user;
  const QrCardWidget(
      {super.key, required this.codeData, required this.user});

  @override
  Widget build(BuildContext context) {
    final code = codeData['code']?.toString() ?? '';
    final name = codeData['name']?.toString() ?? 'Codigo';
    final location =
        user.location.isNotEmpty ? user.location : 'Residencia';
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final dur = codeData['duration']?.toString();
    final isOneUse = dur == '1u';
    final isPermanent = codeData['expires_at'] == null && !isOneUse;
    final badgeLabel = isOneUse ? '1 SOLO USO' : isPermanent ? 'PERMANENTE' : 'TEMPORAL';
    final badgeColor = isOneUse
        ? const Color(0xFFBF5AF2)
        : isPermanent
            ? const Color(0xFF34C759)
            : Colors.orange;

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
              blurRadius: 30,
              offset: const Offset(0, 8)),
          const BoxShadow(
              color: Colors.black54, blurRadius: 20, offset: Offset(0, 4)),
        ],
        border:
            Border.all(color: const Color(0xFF0A84FF).withOpacity(0.18), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  topLeft: Radius.circular(23),
                  topRight: Radius.circular(23)),
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
              const SizedBox(height: 8),
              const Text('PCS ACCESS',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3)),
              const Text('Control de Acceso Residencial',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ),
          // QR Image
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF1A73E8).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2)
                ],
              ),
              child: QrImageView(
                data: code.isNotEmpty ? code : '000000',
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0D47A1)),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A1A2E)),
              ),
            ),
          ),
          // Info section
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Column(children: [
              _InfoRow(icon: Icons.home, label: location, color: const Color(0xFF0A84FF)),
              const Divider(height: 12, color: Colors.white12),
              _InfoRow(icon: Icons.person, label: name),
              const Divider(height: 12, color: Colors.white12),
              _InfoRow(icon: Icons.calendar_today, label: dateStr),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: badgeColor),
                ),
              ),
            ]),
          ),
          // Code display
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(
                code,
                style: const TextStyle(
                    fontSize: 36,
                    letterSpacing: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text('CODIGO DE ACCESO',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 3,
                      color: Colors.white38,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
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
