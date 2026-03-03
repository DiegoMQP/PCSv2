import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GuestsScreen extends StatefulWidget {
  final String username;
  const GuestsScreen({super.key, required this.username});
  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() { _future = ApiService().getGuests(widget.username); });

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    String duration = '4h';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setDS) => AlertDialog(
        title: const Text('Registrar Invitado'),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Visitante', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(controller: plateCtrl, decoration: const InputDecoration(labelText: 'Placa (opcional)', prefixIcon: Icon(Icons.directions_car_outlined))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: duration,
              decoration: const InputDecoration(labelText: 'Duración', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: '1h',  child: Text('1 Hora')),
                DropdownMenuItem(value: '4h',  child: Text('4 Horas')),
                DropdownMenuItem(value: '24h', child: Text('1 Día')),
                DropdownMenuItem(value: '1w',  child: Text('1 Semana')),
              ],
              onChanged: (v) => setDS(() => duration = v!),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A84FF), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final res = await ApiService().createGuest(
                visitorName: nameCtrl.text,
                hostUsername: widget.username,
                plate: plateCtrl.text.isNotEmpty ? plateCtrl.text : null,
                duration: duration,
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res['success'] == true ? 'Invitado registrado' : res['message']?.toString() ?? 'Error'),
                backgroundColor: res['success'] == true ? Colors.green : Colors.red,
              ));
              if (res['success'] == true) _load();
            },
            child: const Text('Registrar'),
          ),
        ],
      )),
    );
  }

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
              const Text('Invitados', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Nuevo Invitado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF), foregroundColor: Colors.white,
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
                final guests = snap.data ?? [];
                if (guests.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text('No hay invitados registrados', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18, fontWeight: FontWeight.w600)),
                  ]));
                }
                return ListView.separated(
                  itemCount: guests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final g = guests[i] as Map;
                    final status = g['status']?.toString() ?? 'ACTIVE';
                    final statusColor = status == 'ACTIVE' ? Colors.green : status == 'EXPIRED' ? Colors.red : Colors.grey;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFF32D74B).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.person, color: Color(0xFF32D74B), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(g['visitor_name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                          const SizedBox(height: 4),
                          Row(children: [
                            if (g['plate'] != null) ...[
                              Icon(Icons.directions_car_outlined, size: 13, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(g['plate'].toString(), style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                              const SizedBox(width: 12),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: statusColor.withOpacity(0.4)),
                              ),
                              child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ])),
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
}
