import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final username = Provider.of<UserProvider>(context, listen: false).username;
    setState(() => _future = ApiService().getNotifications(username));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Alertas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Notificaciones del sistema', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0A84FF)));
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Error al cargar alertas', style: TextStyle(color: Colors.red.shade400)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
                    ]),
                  );
                }
                final alerts = snap.data ?? [];
                if (alerts.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.notifications_none, size: 80, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text('Sin alertas', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('No tienes notificaciones nuevas', style: TextStyle(color: Colors.white24)),
                    ]),
                  );
                }
                return ListView.separated(
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final alert = alerts[i];
                    final isExpiration = alert['type'] == 'EXPIRATION';
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isExpiration ? const Color(0xFFFF453A) : const Color(0xFFFF9F0A)).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isExpiration ? const Color(0xFFFF453A) : const Color(0xFFFF9F0A)).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isExpiration ? Icons.timer_off_outlined : Icons.warning_amber_rounded,
                              color: isExpiration ? const Color(0xFFFF453A) : const Color(0xFFFF9F0A),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isExpiration ? 'Código Expirado' : (alert['title']?.toString() ?? 'Alerta'),
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                if ((alert['message']?.toString() ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    alert['message'].toString(),
                                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
}
