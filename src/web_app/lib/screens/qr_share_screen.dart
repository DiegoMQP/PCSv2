// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Public shareable QR card — accessible without login.
/// URL: /qr/CODE?name=Dileo&loc=Atemajac+2172&type=PERMANENTE
class QrShareScreen extends StatelessWidget {
  final String code;
  final String name;
  final String location;
  final String type; // PERMANENTE | TEMPORAL | 1_SOLO_USO

  const QrShareScreen({
    super.key,
    required this.code,
    required this.name,
    required this.location,
    required this.type,
  });

  // ── Badge ────────────────────────────────────────────────
  String get _badgeLabel {
    if (type == '1u' || type == '1_SOLO_USO') return '1 SOLO USO';
    if (type == 'TEMPORAL' || type == 'temporal') return 'TEMPORAL';
    return 'PERMANENTE';
  }

  Color get _badgeColor {
    if (type == '1u' || type == '1_SOLO_USO') return const Color(0xFFBF5AF2);
    if (type == 'TEMPORAL' || type == 'temporal') return const Color(0xFFFF9F0A);
    return const Color(0xFF32D74B);
  }

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top bar ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [Color(0xFF1A84FF), Color(0xFF0055CC)]),
                        ),
                        alignment: Alignment.center,
                        child: const Text('PCS',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                      ),
                      const SizedBox(width: 8),
                      const Text('PCS Access',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Card ────────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0D1117), Color(0xFF161B22)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF0A84FF).withOpacity(0.25),
                            blurRadius: 40, offset: const Offset(0, 10)),
                        const BoxShadow(
                            color: Colors.black54,
                            blurRadius: 24, offset: Offset(0, 6)),
                      ],
                      border: Border.all(
                          color: const Color(0xFF0A84FF).withOpacity(0.2),
                          width: 1),
                    ),
                    child: Column(children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Color(0xFF0A0A1A), Color(0xFF0D47A1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(27),
                              topRight: Radius.circular(27)),
                        ),
                        child: Column(children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [
                                Color(0xFF1A84FF), Color(0xFF0055CC)
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF0A84FF).withOpacity(0.55),
                                    blurRadius: 18, spreadRadius: 2)
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
                          const SizedBox(height: 12),
                          const Text('PCS ACCESS',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3)),
                          const SizedBox(height: 2),
                          const Text('Control de Acceso Residencial',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ]),
                      ),

                      // QR
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF0A84FF).withOpacity(0.3),
                                  blurRadius: 20, spreadRadius: 2)
                            ],
                          ),
                          child: code.isNotEmpty
                              ? QrImageView(
                                  data: code,
                                  version: QrVersions.auto,
                                  size: 220,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFF0D1117)),
                                  dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Color(0xFF0D1117)),
                                )
                              : const SizedBox(width: 220, height: 220),
                        ),
                      ),

                      // Info block
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF21262D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.07)),
                        ),
                        child: Column(children: [
                          _InfoRow(Icons.home, location.isNotEmpty ? location : 'Residencial',
                              const Color(0xFF0A84FF)),
                          const Divider(height: 14, color: Colors.white12),
                          _InfoRow(Icons.person, name.isNotEmpty ? name : '—', Colors.white70),
                          const Divider(height: 14, color: Colors.white12),
                          _InfoRow(Icons.calendar_today, _today, Colors.white70),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: _badgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _badgeColor),
                            ),
                            child: Text(_badgeLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: _badgeColor)),
                          ),
                        ]),
                      ),

                      // Code
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(children: [
                          Text(code,
                              style: const TextStyle(
                                  fontSize: 40,
                                  letterSpacing: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          const Text('CÓDIGO DE ACCESO',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: Colors.white38)),
                        ]),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // ── Action buttons ───────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionBtn(
                        icon: Icons.copy,
                        label: 'Copiar código',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Código $code copiado'),
                              backgroundColor: const Color(0xFF32D74B),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _ActionBtn(
                        icon: Icons.share,
                        label: 'Compartir URL',
                        onTap: () {
                          final url = html.window.location.href;
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Link copiado 📋'),
                              backgroundColor: const Color(0xFF0A84FF),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text('pcssec-c4bf5.web.app',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 11,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF21262D),
        foregroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onTap,
    );
  }
}
