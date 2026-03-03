import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _input = StringBuffer();
  bool _loading = false;
  _VerifyResult? _result;

  static const _maxLen = 6;

  void _onKey(String digit) {
    if (_loading) return;
    if (_input.length >= _maxLen) return;
    setState(() {
      _input.write(digit);
      _result = null;
    });
    if (_input.length == _maxLen) _verify();
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

  Future<void> _verify() async {
    final code = _input.toString();
    if (code.length < _maxLen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa los 6 dígitos del código')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _result = null;
    });
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
    final code = _input.toString();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.qr_code_scanner,
                            color: primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Verificar Código',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text('Ingresa el código de acceso de 6 dígitos',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Code display ─────────────────────────────────────────
                  _CodeDisplay(code: code, maxLen: _maxLen, primary: primary),
                  const SizedBox(height: 24),

                  // ── Result card ──────────────────────────────────────────
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    )
                  else if (_result != null)
                    _ResultCard(result: _result!),

                  const SizedBox(height: 16),

                  // ── Numpad ───────────────────────────────────────────────
                  _NumPad(
                    onDigit: _onKey,
                    onDelete: _onDelete,
                    onClear: _onClear,
                  ),
                  const SizedBox(height: 20),

                  // ── Verify button ────────────────────────────────────────
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
                      onPressed: _loading ? null : _verify,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Code display dots ────────────────────────────────────────────────────────
class _CodeDisplay extends StatelessWidget {
  final String code;
  final int maxLen;
  final Color primary;
  const _CodeDisplay(
      {required this.code, required this.maxLen, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxLen, (i) {
          final filled = i < code.length;
          return Container(
            width: 48,
            height: 58,
            margin: const EdgeInsets.symmetric(horizontal: 6),
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
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primary),
                  )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400, shape: BoxShape.circle),
                  ),
          );
        }),
      ),
    );
  }
}

// ─── Result card ──────────────────────────────────────────────────────────────
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
        key: ValueKey(result),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 52),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          if (result.name != null) ...[
            const SizedBox(height: 12),
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
                style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
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
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );
}

// ─── Numpad ───────────────────────────────────────────────────────────────────
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
              padding: const EdgeInsets.all(7),
              child: SizedBox(
                width: 88,
                height: 68,
                child: Material(
                  color: isSpecial
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface,
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
                                fontSize: 26,
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
