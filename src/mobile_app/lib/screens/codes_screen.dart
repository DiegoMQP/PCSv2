import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../widgets/qr_card_widget.dart';
import '../l10n/app_localizations.dart';

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
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 8),
          Text(ctx.tr('delete_code')),
        ]),
        content: Text(ctx.tr('delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await ApiService().deleteCode(code);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? context.trStatic('code_deleted') : context.trStatic('delete_error')),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) _refreshCodes();
    }
  }

  void _showEditDurationDialog(String code, String currentDuration) {
    String selected = currentDuration;
    final options = [
      _DurationOption('permanent', ctx.tr('dur_permanent'), Icons.all_inclusive, Colors.green),
      _DurationOption('30m', ctx.tr('dur_30m'), Icons.timer, Colors.blue),
      _DurationOption('4h', ctx.tr('dur_4h'), Icons.access_time, Colors.orange),
      _DurationOption('24h', ctx.tr('dur_24h'), Icons.today, Colors.deepOrange),
      _DurationOption('1w', ctx.tr('dur_1w'), Icons.date_range, Colors.purple),
    ];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDS) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.schedule, color: Color(0xFF1A73E8)),
            const SizedBox(width: 8),
            Text(ctx.tr('edit_duration')),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(ctx.tr('select_duration'),
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await ApiService().updateCodeDuration(code, selected);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res ? context.trStatic('duration_updated') : context.trStatic('update_error')),
                    backgroundColor: res ? Colors.green : Colors.red,
                  ));
                  if (res) _refreshCodes();
                }
              },
              child: Text(ctx.tr('save'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ── Add Personal Code ────────────────────────────────────────────────
  void _showAddCodeDialog() {
    final nameCtrl = TextEditingController();
    String duration = 'permanent';
    showDialog(
      context: context,
      builder: (ctx) {
        final options = [
          _DurationOption('permanent', ctx.tr('dur_permanent'), Icons.all_inclusive, Colors.green),
          _DurationOption('1u',        ctx.tr('dur_1u'),         Icons.looks_one,     const Color(0xFFBF5AF2)),
          _DurationOption('30m', ctx.tr('dur_30m'), Icons.timer, Colors.blue),
          _DurationOption('4h',  ctx.tr('dur_4h'),  Icons.access_time, Colors.orange),
          _DurationOption('24h', ctx.tr('dur_24h'), Icons.today, Colors.deepOrange),
          _DurationOption('1w',  ctx.tr('dur_1w'),  Icons.date_range, Colors.purple),
        ];
        return StatefulBuilder(builder: (ctx, setDS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(children: [
            const Icon(Icons.add_box_rounded, color: Color(0xFF0A84FF)),
            const SizedBox(width: 8),
            Text(ctx.tr('new_personal_code')),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: ctx.tr('code_name'),
                  prefixIcon: const Icon(Icons.label_outline),
                  hintText: ctx.tr('code_name_hint'),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(ctx.tr('duration_label'), style: TextStyle(
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
            child: Text(ctx.tr('cancel')),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(ctx.tr('create_code')),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ctx.trStatic('enter_code_name')),
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
                _showQrCardDialog({
                  'code': code,
                  'name': nameCtrl.text.trim(),
                  'duration': duration,
                  'status': 'ACTIVE',
                  'host_username': user.username,
                }, user);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res['message']?.toString() ?? context.trStatic('error')),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
          ),
        ],
      ));
    });
  }

  void _showQrCardDialog(Map<String, dynamic> codeData, UserProvider user) {
    final code = codeData['code']?.toString() ?? '';
    final cardKey = GlobalKey();
    showDialog(
      context: context,
      builder: (ctx) {
        final screenH = MediaQuery.of(ctx).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── QR card con zoom ──────────────────────────────
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenH * 0.62),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    clipBehavior: Clip.none,
                    child: RepaintBoundary(
                      key: cardKey,
                      child: QrCardWidget(codeData: codeData, user: user),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Zoom hint
              Text(
                ctx.tr('pinch_zoom'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              // ── Code display ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 7,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Action buttons bar ────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.60),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _QrActionBtn(
                          icon: Icons.copy_rounded,
                          label: ctx.tr('copy'),
                          color: Colors.white,
                          onTap: () => copyCode(code, ctx),
                        ),
                        _QrActionDivider(),
                        _QrActionBtn(
                          icon: Icons.ios_share_rounded,
                          label: ctx.tr('share'),
                          color: const Color(0xFF0A84FF),
                          onTap: () => captureAndShare(cardKey, code, ctx),
                        ),
                        if (codeData['qr_url'] != null) ...[
                          _QrActionDivider(),
                          _QrActionBtn(
                            icon: Icons.link_rounded,
                            label: ctx.tr('link'),
                            color: Colors.tealAccent,
                            onTap: () async {
                              final url = codeData['qr_url'].toString();
                              try {
                                await Share.share(
                                  '${ctx.trStatic('share_qr_text')}$url',
                                  subject: ctx.trStatic('share_qr_subject'),
                                );
                              } catch (_) {
                                await Clipboard.setData(ClipboardData(text: url));
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text(ctx.trStatic('link')),
                                    backgroundColor: Colors.teal,
                                  ));
                                }
                              }
                            },
                          ),
                        ],
                        _QrActionDivider(),
                        _QrActionBtn(
                          icon: Icons.close_rounded,
                          label: ctx.tr('close'),
                          color: Colors.white70,
                          onTap: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('my_codes')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.tr('refresh'),
            onPressed: _refreshCodes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCodeDialog,
        backgroundColor: const Color(0xFF0A84FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.tr('new_code'), style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  Text(context.tr('no_codes'),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(context.tr('no_codes_hint'),
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
                    label: Text(context.tr('new_code')),
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

class _CodeCard extends StatefulWidget {
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
    final exp =
        DateTime.fromMillisecondsSinceEpoch((expiresAt as num).toInt());
    final now = DateTime.now();
    _remaining = exp.isAfter(now) ? exp.difference(now) : Duration.zero;
  }

  String _formatRemaining(BuildContext context) {
    if (_remaining.inSeconds <= 0) return context.trStatic('expired');
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
    final name = widget.codeData['name']?.toString() ?? 'Codigo';
    final expiresAt = widget.codeData['expires_at'];
    final dur = widget.codeData['duration']?.toString();
    final isOneUse = dur == '1u';
    final isPermanent = expiresAt == null && !isOneUse;
    final primary = Theme.of(context).colorScheme.primary;
    final typeColor = isOneUse
        ? const Color(0xFFBF5AF2)
        : isPermanent
            ? Colors.green
            : Colors.orange.shade600;

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
                    ? Row(children: [
                        const Icon(Icons.all_inclusive, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(context.tr('permanent'),
                            style: const TextStyle(fontSize: 11, color: Colors.green)),
                      ])
                    : isOneUse
                        ? Row(children: [
                            Icon(Icons.looks_one, size: 12, color: typeColor),
                            const SizedBox(width: 4),
                            Text(context.tr('one_use'),
                                style: TextStyle(fontSize: 11, color: typeColor)),
                          ])
                        : Row(children: [
                            Icon(Icons.schedule, size: 12, color: Colors.orange.shade600),
                            const SizedBox(width: 4),
                            Text(
                              _formatRemaining(context),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _remaining.inSeconds > 0
                                      ? Colors.orange.shade600
                                      : Colors.red),
                            ),
                          ]),
              ]),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: primary, size: 20),
              tooltip: context.tr('edit_duration_tooltip'),
              onPressed: widget.onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              tooltip: 'Eliminar',
              onPressed: widget.onDelete,
            ),
          ]),
        ),
        // QR preview
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: GestureDetector(
            onTap: widget.onShowCard,
            child: QrImageView(
              data: code.isNotEmpty ? code : '000000',
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
              onPressed: widget.onShowCard,
              icon: const Icon(Icons.qr_code, size: 15),
              label: Text(context.tr('see_share'), style: const TextStyle(fontSize: 12)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── QR Dialog Action Button ──────────────────────────────────
class _QrActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QrActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.35), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── QR Dialog Action Divider ─────────────────────────────────
class _QrActionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
