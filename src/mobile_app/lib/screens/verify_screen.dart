import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _input = StringBuffer();
  bool _loading = false;
  _VerifyResult? _result;
  bool _cameraVerified = false;

  static const _maxLen = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kIsWeb ? 1 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onKey(String digit) {
    if (_loading) return;
    if (_input.length >= _maxLen) return;
    setState(() {
      _input.write(digit);
      _result = null;
    });
    if (_input.length == _maxLen) _verify(_input.toString());
  }

  void _onDelete() {
    if (_loading) return;
    if (_input.isEmpty) return;
    final s = _input.toString();
    setState(() {
      _input.clear();
      _input.write(s.substring(0, s.length - 1));
      _result = null;
    });
  }

  void _onClear() {
    if (_loading) return;
    setState(() {
      _input.clear();
      _result = null;
    });
  }

  // ── Camera QR detected ──────────────────────────────────────────────────────
  void _onQrDetected(BarcodeCapture capture) {
    if (_loading || _cameraVerified) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    final code = raw.length == 6 ? raw : _extractCode(raw);
    if (code == null || code.length != 6) return;
    setState(() => _cameraVerified = true);
    _verify(code).then((_) => setState(() => _cameraVerified = false));
  }

  String? _extractCode(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final q = uri.queryParameters['code'];
      if (q != null && q.length == 6) return q;
    }
    final match = RegExp(r'\b(\d{6})\b').firstMatch(raw);
    return match?.group(1);
  }

  Future<void> _verify(String code) async {
    if (code.length < _maxLen) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa los 6 dígitos del código')),
        );
      }
      return;
    }
    setState(() { _loading = true; _result = null; });
    final res = await ApiService().verifyCode(code);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = _VerifyResult(
        valid: res['valid'] == true,
        name: res['name']?.toString() ?? res['visitor_name']?.toString(),
        host: res['host_username']?.toString(),
        type: res['access_type']?.toString(),
        message: res['message']?.toString(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Código de Acceso'),
        bottom: kIsWeb
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.camera_alt_outlined), text: 'Cámara'),
                  Tab(icon: Icon(Icons.keyboard_outlined), text: 'Teclado'),
                ],
              ),
      ),
      body: kIsWeb
          ? _buildKeypad(primary)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCamera(primary),
                _buildKeypad(primary),
              ],
            ),
    );
  }

  Widget _buildCamera(Color primary) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              MobileScanner(onDetect: _onQrDetected),
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned(
                top: 16, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Apunta al código QR',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loading)
                  const CircularProgressIndicator()
                else if (_result != null)
                  _ResultCard(result: _result!)
                else
                  Text('Escanea un código QR para verificar acceso',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500)),
                if (_result != null) ...
                  [
                    const SizedBox(height: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Escanear otro'),
                      onPressed: () => setState(() => _result = null),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad(Color primary) {
    final code = _input.toString();
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _CodeDisplay(code: code, maxLen: _maxLen, primary: primary),
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  )
                else if (_result != null)
                  _ResultCard(result: _result!),
                const Spacer(),
                _NumPad(
                  onDigit: _onKey,
                  onDelete: _onDelete,
                  onClear: _onClear,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.verified_outlined),
                    label: const Text('Verificar Acceso',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed:
                        _loading ? null : () => _verify(_input.toString()),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Code display dots ───────────────────────────────────────────────────────
class _CodeDisplay extends StatelessWidget {
  final String code;
  final int maxLen;
  final Color primary;
  const _CodeDisplay(
      {required this.code, required this.maxLen, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxLen, (i) {
          final filled = i < code.length;
          return Container(
            width: 42,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: filled
                  ? primary.withOpacity(0.1)
                  : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: filled ? primary : Colors.grey.shade400,
                width: filled ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: filled
                ? Text(
                    code[i],
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primary),
                  )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle),
                  ),
          );
        }),
      ),
    );
  }
}

// ─── Result card ─────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final _VerifyResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.valid ? const Color(0xFF34C759) : Colors.red;
    final icon = result.valid ? Icons.check_circle : Icons.cancel;
    final label = result.valid ? 'ACCESO CONCEDIDO' : 'ACCESO DENEGADO';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(result.valid),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          if (result.name != null) ...[
            const SizedBox(height: 10),
            _InfoChip(Icons.person, result.name!),
          ],
          if (result.host != null) ...[
            const SizedBox(height: 6),
            _InfoChip(Icons.home, 'Residente: ${result.host!}'),
          ],
          if (result.type != null) ...[
            const SizedBox(height: 6),
            _InfoChip(Icons.access_time, _typeLabel(result.type!)),
          ],
          if (!result.valid && result.message != null) ...[
            const SizedBox(height: 8),
            Text(result.message!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.red.shade400, fontSize: 13)),
          ],
        ]),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'PERMANENT':
        return 'Acceso Permanente';
      case 'ONE_TIME':
        return 'Un solo uso';
      case 'TIME':
        return 'Acceso Temporal';
      case 'LIMIT':
        return 'Usos limitados';
      default:
        return type;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );
}

// ─── Numpad ──────────────────────────────────────────────────────────────────
class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  const _NumPad(
      {required this.onDigit, required this.onDelete, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            final isSpecial = k == '⌫' || k == 'C';
            return Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                width: 80,
                height: 64,
                child: Material(
                  color: isSpecial
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (k == '⌫') {
                        onDelete();
                      } else if (k == 'C') {
                        onClear();
                      } else {
                        onDigit(k);
                      }
                    },
                    child: Center(
                      child: k == '⌫'
                          ? Icon(Icons.backspace_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 22)
                          : Text(
                              k,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: isSpecial
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

// ─── Result model ─────────────────────────────────────────────────────────────
class _VerifyResult {
  final bool valid;
  final String? name;
  final String? host;
  final String? type;
  final String? message;
  const _VerifyResult(
      {required this.valid, this.name, this.host, this.type, this.message});
}
