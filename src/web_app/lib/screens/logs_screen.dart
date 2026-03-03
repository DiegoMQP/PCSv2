import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  final String username;
  const LogsScreen({super.key, required this.username});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() { _future = ApiService().getLogs(widget.username); });

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
              const Text('Registro de Actividad', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final logs = snap.data ?? [];
                if (logs.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.receipt_long, size: 80, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text('No hay registros aún', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18, fontWeight: FontWeight.w600)),
                  ]));
                }
                return ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final log = logs[i] as Map;
                    final type = log['event_type']?.toString() ?? log['type']?.toString() ?? 'EVENT';
                    final ts = log['created_at'] ?? log['timestamp'];
                    String timeStr = '';
                    if (ts != null) {
                      try {
                        final dt = DateTime.fromMillisecondsSinceEpoch((ts as num).toInt()).toLocal();
                        timeStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      } catch (_) {}
                    }
                    final iconData = _iconForType(type);
                    final color = _colorForType(type);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: Icon(iconData, color: color, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['message']?.toString() ?? type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                            if (log['code'] != null)
                              Text('Código: ${log['code']}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                          ],
                        )),
                        if (timeStr.isNotEmpty)
                          Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.3))),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String t) {
    if (t.contains('ACCESS') || t.contains('GRANTED')) return Icons.check_circle_outline;
    if (t.contains('DENY') || t.contains('REJECT')) return Icons.cancel_outlined;
    if (t.contains('EXPIR')) return Icons.timer_off_outlined;
    if (t.contains('CREATE') || t.contains('NEW')) return Icons.add_circle_outline;
    if (t.contains('DELETE') || t.contains('REMOVE')) return Icons.delete_outline;
    return Icons.info_outline;
  }

  Color _colorForType(String t) {
    if (t.contains('ACCESS') || t.contains('GRANTED') || t.contains('CREATE')) return Colors.green;
    if (t.contains('DENY') || t.contains('REJECT') || t.contains('DELETE')) return Colors.red;
    if (t.contains('EXPIR')) return Colors.orange;
    return Colors.blue;
  }
}
