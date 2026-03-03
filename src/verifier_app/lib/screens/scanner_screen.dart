// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

// ─── Result Model ────────────────────────────────────────
class _ScanResult {
  final bool valid;
  final String? name;
  final String? host;
  final String? type;
  final String? message;
  const _ScanResult({
    required this.valid,
    this.name,
    this.host,
    this.type,
    this.message,
  });
}

// ─── Scanner Screen ──────────────────────────────────────
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  // Camera
  final MobileScannerController _camCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // State
  bool _loading = false;
  bool _cameraPaused = false;
  bool _showKeypad = false;
  bool _torch = false;
  _ScanResult? _result;

  // Keypad
  final _codeBuffer = StringBuffer();
  static const _maxDigits = 6;

  // Online status
  bool _online = true;

  // Animation
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _checkOnline();
  }

  Future<void> _checkOnline() async {
    final ok = await ApiService().checkHealth();
    if (mounted) setState(() => _online = ok);
  }

  @override
  void dispose() {
    _camCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── QR Detected ──────────────────────────────────────────
  void _onQrDetected(BarcodeCapture capture) {
    if (_loading || _cameraPaused) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final code = raw.length == _maxDigits ? raw : _extractCode(raw);
    if (code == null || code.length != _maxDigits) return;

    _verify(code);
  }

  String? _extractCode(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final q = uri.queryParameters['code'];
      if (q != null && q.length == _maxDigits) return q;
    }
    final match = RegExp(r'\b(\d{6})\b').firstMatch(raw);
    return match?.group(1);
  }

  // ── Keypad Input ─────────────────────────────────────────
  void _onDigit(String d) {
    if (_loading || _codeBuffer.length >= _maxDigits) return;
    HapticFeedback.selectionClick();
    setState(() {
      _codeBuffer.write(d);
      _result = null;
    });
    if (_codeBuffer.length == _maxDigits) {
      _verify(_codeBuffer.toString());
    }
  }

  void _onDelete() {
    if (_loading || _codeBuffer.isEmpty) return;
    HapticFeedback.selectionClick();
    final s = _codeBuffer.toString();
    setState(() {
      _codeBuffer.clear();
      _codeBuffer.write(s.substring(0, s.length - 1));
      _result = null;
    });
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _codeBuffer.clear();
      _result = null;
    });
  }

  // ── Verify ───────────────────────────────────────────────
  Future<void> _verify(String code) async {
    if (code.length < _maxDigits) return;
    setState(() {
      _loading = true;
      _result = null;
      _cameraPaused = true;
    });
    _camCtrl.stop();

    final res = await ApiService().verifyCode(code);

    if (!mounted) return;
    HapticFeedback.heavyImpact();

    setState(() {
      _loading = false;
      _result = _ScanResult(
        valid: res['valid'] == true,
        name: res['name']?.toString() ?? res['visitor_name']?.toString(),
        host: res['host_username']?.toString(),
        type: res['access_type']?.toString(),
        message: res['message']?.toString(),
      );
    });

    // Auto-dismiss after 4 seconds & resume cam
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _result = null;
          _cameraPaused = false;
          _codeBuffer.clear();
        });
        _camCtrl.start();
      }
    });
  }

  void _resetAndResume() {
    setState(() {
      _result = null;
      _cameraPaused = false;
      _codeBuffer.clear();
      _loading = false;
    });
    _camCtrl.start();
  }

  void _toggleKeypad() {
    HapticFeedback.selectionClick();
    setState(() {
      _showKeypad = !_showKeypad;
      if (!_showKeypad) {
        _codeBuffer.clear();
        _result = null;
      }
    });
  }

  void _toggleTorch() {
    _torch = !_torch;
    _camCtrl.toggleTorch();
    setState(() {});
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: Stack(
        children: [
          // ── Camera ────────────────────────────────────────
          if (!_showKeypad)
            Positioned.fill(
              child: MobileScanner(
                controller: _camCtrl,
                onDetect: _onQrDetected,
              ),
            ),

          // ── Dark overlay when keypad shown ────────────────
          if (_showKeypad)
            Positioned.fill(
              child: Container(color: const Color(0xFF1C1C1E)),
            ),

          // ── Scan frame / overlay ─────────────────────────
          if (!_showKeypad && !_cameraPaused && _result == null)
            Positioned.fill(child: _buildScanOverlay()),

          // ── Result Banner ─────────────────────────────────
          if (_result != null)
            Positioned.fill(child: _buildResultOverlay(_result!)),

          // ── Loading Spinner ───────────────────────────────
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0A84FF),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),

          // ── Top Bar ───────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // ── Bottom Controls ───────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────
  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(_showKeypad ? 0.0 : 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _online
                    ? const Color(0xFF32D74B).withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _online
                      ? const Color(0xFF32D74B).withOpacity(0.5)
                      : Colors.red.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _online ? const Color(0xFF32D74B) : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _online ? 'En línea' : 'Sin conexión',
                    style: TextStyle(
                      fontSize: 12,
                      color: _online ? const Color(0xFF32D74B) : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Text(
              'PCS Verificador',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            // Torch button (only in camera mode)
            if (!_showKeypad)
              GestureDetector(
                onTap: _toggleTorch,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _torch
                        ? const Color(0xFFFFD60A).withOpacity(0.25)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _torch ? Icons.flashlight_on : Icons.flashlight_off,
                    color: _torch ? const Color(0xFFFFD60A) : Colors.white70,
                    size: 20,
                  ),
                ),
              )
            else
              const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }

  // ── Scan Overlay ─────────────────────────────────────────
  Widget _buildScanOverlay() {
    return CustomPaint(
      painter: _ScanOverlayPainter(_pulseAnim.value),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => CustomPaint(
          painter: _ScanOverlayPainter(_pulseAnim.value),
        ),
      ),
    );
  }

  // ── Result Overlay ───────────────────────────────────────
  Widget _buildResultOverlay(_ScanResult res) {
    final isValid = res.valid;
    final color = isValid ? const Color(0xFF32D74B) : const Color(0xFFFF453A);
    final bgColor = isValid
        ? const Color(0xFF32D74B).withOpacity(0.12)
        : const Color(0xFFFF453A).withOpacity(0.12);

    return GestureDetector(
      onTap: _resetAndResume,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.4), width: 2),
                  ),
                  child: Icon(
                    isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: color,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isValid ? 'ACCESO PERMITIDO' : 'ACCESO DENEGADO',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                if (res.name != null && res.name!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          icon: Icons.person_rounded,
                          label: 'Nombre',
                          value: res.name!,
                        ),
                        if (res.host != null && res.host!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.home_rounded,
                            label: 'Residente',
                            value: res.host!,
                          ),
                        ],
                        if (res.type != null && res.type!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.category_rounded,
                            label: 'Tipo',
                            value: res.type == 'personal'
                                ? 'Código Personal'
                                : 'Código de Visita',
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (res.message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    res.message!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Toca para continuar',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Controls ──────────────────────────────────────
  Widget _buildBottomControls() {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Keypad (expandable)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildKeypad(),
            crossFadeState: _showKeypad
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
          ),
          // Toggle Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Keypad toggle
                GestureDetector(
                  onTap: _toggleKeypad,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: _showKeypad
                          ? const Color(0xFF0A84FF)
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _showKeypad
                            ? const Color(0xFF0A84FF)
                            : Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showKeypad
                              ? Icons.camera_alt_rounded
                              : Icons.keyboard_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showKeypad ? 'Usar Cámara' : 'Ingresar Código',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Keypad ───────────────────────────────────────────────
  Widget _buildKeypad() {
    final code = _codeBuffer.toString();
    return Container(
      color: const Color(0xFF1C1C1E),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Code display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_maxDigits, (i) {
                final filled = i < code.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 36,
                  height: 44,
                  decoration: BoxDecoration(
                    color: filled
                        ? const Color(0xFF0A84FF).withOpacity(0.15)
                        : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: filled
                          ? const Color(0xFF0A84FF).withOpacity(0.6)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      filled ? code[i] : '•',
                      style: TextStyle(
                        color: filled ? Colors.white : Colors.white30,
                        fontSize: filled ? 22 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          // Number grid
          ...['1 2 3', '4 5 6', '7 8 9', '← 0 ✕'].map((row) {
            final keys = row.split(' ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: keys.map((k) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _KeyButton(
                        label: k,
                        onTap: () {
                          if (k == '←') {
                            _onDelete();
                          } else if (k == '✕') {
                            _clearAll();
                          } else {
                            _onDigit(k);
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Key Button ──────────────────────────────────────────
class _KeyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _KeyButton({required this.label, required this.onTap});

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isAction = widget.label == '←' || widget.label == '✕';
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 52,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withOpacity(0.15)
              : isAction
                  ? const Color(0xFF0A84FF).withOpacity(0.12)
                  : const Color(0xFF3A3A3C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              color: isAction ? const Color(0xFF0A84FF) : Colors.white,
              fontSize: widget.label == '←' ? 20 : 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Scan Overlay Painter ────────────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  final double pulse;
  _ScanOverlayPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = 220.0;
    const cornerLen = 28.0;
    const cornerRadius = 8.0;
    const strokeW = 3.0;

    final cx = size.width / 2;
    final cy = size.height / 2 - 40;

    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: frameSize,
      height: frameSize,
    );

    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final fullPath = Path()..addRect(Offset.zero & size);
    final clearPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, clearPath),
      overlayPaint,
    );

    // Corner strokes
    final cornerColor = Color.lerp(
      const Color(0xFF0A84FF),
      Colors.white,
      pulse * 0.5,
    )!;
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    // TL
    canvas.drawLine(
      Offset(rect.left + cornerRadius, rect.top),
      Offset(rect.left + cornerLen, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerRadius),
      Offset(rect.left, rect.top + cornerLen),
      cornerPaint,
    );
    // TR
    canvas.drawLine(
      Offset(rect.right - cornerLen, rect.top),
      Offset(rect.right - cornerRadius, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + cornerRadius),
      Offset(rect.right, rect.top + cornerLen),
      cornerPaint,
    );
    // BL
    canvas.drawLine(
      Offset(rect.left + cornerRadius, rect.bottom),
      Offset(rect.left + cornerLen, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerRadius),
      Offset(rect.left, rect.bottom - cornerLen),
      cornerPaint,
    );
    // BR
    canvas.drawLine(
      Offset(rect.right - cornerLen, rect.bottom),
      Offset(rect.right - cornerRadius, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerRadius),
      Offset(rect.right, rect.bottom - cornerLen),
      cornerPaint,
    );

    // Scan line
    final scanY = rect.top + (rect.height * pulse);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF0A84FF).withOpacity(0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(rect.left, scanY, rect.width, 2));
    canvas.drawLine(
      Offset(rect.left + 4, scanY),
      Offset(rect.right - 4, scanY),
      scanPaint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) => old.pulse != pulse;
}
