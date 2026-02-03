import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // Mock data for UI
  final List<Map<String, dynamic>> _logs = [
    {
       'type': 'entry', 'name': 'Juan Pérez', 'meta': 'Visita • Placa: ABC-123', 'time': '14:30', 'day': 'Hoy'
    },
    {
       'type': 'exit', 'name': 'Juan Pérez', 'meta': 'Salida', 'time': '12:15', 'day': 'Hoy'
    },
    {
       'type': 'denied', 'name': 'Desconocido', 'meta': 'Código inválido', 'time': '10:05', 'day': 'Hoy'
    },
    {
       'type': 'entry', 'name': 'Paquetería Amazon', 'meta': 'Servicio • Entrada', 'time': '16:45', 'day': 'Ayer'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text("Historial"),
        actions: [
          TextButton(onPressed: (){}, child: const Text("Filtrar")),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: "Buscar",
                filled: true,
                fillColor: const Color(0xFFE3E3E8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                // Should group by day, simplified here
                return Container(
                  margin: const EdgeInsets.only(bottom: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    // Simple logic to round corners for groups
                    borderRadius: BorderRadius.vertical(
                      top: index == 0 ? const Radius.circular(12) : Radius.zero,
                      bottom: index == _logs.length - 1 ? const Radius.circular(12) : Radius.zero,
                    ),
                  ),
                  child: ListTile(
                    leading: _buildIcon(log['type']),
                    title: Text(log['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(log['meta'], style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    trailing: Text(log['time'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;
    Color bg;

    switch(type) {
      case 'entry': 
        icon = FontAwesomeIcons.arrowRightToBracket; color = Colors.green; bg = Colors.green.withOpacity(0.15); break;
      case 'exit':
        icon = FontAwesomeIcons.arrowRightFromBracket; color = Colors.grey; bg = Colors.grey.withOpacity(0.15); break;
      case 'denied':
        icon = FontAwesomeIcons.ban; color = Colors.red; bg = Colors.red.withOpacity(0.15); break;
      default:
        icon = Icons.info; color = Colors.blue; bg = Colors.blue.withOpacity(0.1);
    }

    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
