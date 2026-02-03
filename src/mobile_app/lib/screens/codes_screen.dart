import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'dart:math';

class CodesScreen extends StatefulWidget {
  const CodesScreen({super.key});

  @override
  State<CodesScreen> createState() => _CodesScreenState();
}

class _CodesScreenState extends State<CodesScreen> {

  Future<void> _showAddCodeDialog() async {
    final nameController = TextEditingController();
    final visitorController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Código'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre / Motivo'),
            ),
            TextField(
              controller: visitorController,
              decoration: const InputDecoration(labelText: 'Visitante (Opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              
              final user = Provider.of<UserProvider>(context, listen: false);

              // Generate a random 4-digit code
              final code = (1000 + Random().nextInt(9000)).toString(); 
              
              // Show loading or just proceed (simple implementation)
              final api = ApiService();
              final result = await api.saveCode(
                name: nameController.text,
                code: code,
                username: user.username,
                visitors: visitorController.text.isNotEmpty ? [visitorController.text] : []
              );
              
              if (mounted) {
                 Navigator.pop(context);
                 if (result['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Código creado: $code')));
                 } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['message']}'), backgroundColor: Colors.red));
                 }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Códigos"), actions: [
        IconButton(onPressed: _showAddCodeDialog, icon: const Icon(Icons.add))
      ]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10, left: 5),
            child: Text("ACTIVOS AHORA", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          
          _buildCodeCard(
            context,
            title: "Familia Rodríguez",
            subtitle: "Visita General",
            code: "8842",
            expiry: "Expira en 3h 45m",
            status: "Activo",
            statusColor: Colors.green,
            expiryColor: Colors.black,
          ),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(bottom: 10, left: 5),
            child: Text("PRÓXIMOS A VENCER", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),

          _buildCodeCard(
            context,
            title: "Uber Eats",
            subtitle: "Entrega de Comida",
            code: "9021",
            expiry: "Expira en 12m 30s",
            status: "Expira pronto",
            statusColor: Colors.orange,
            expiryColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(BuildContext context, {
    required String title, required String subtitle, required String code, 
    required String expiry, required String status, required Color statusColor,
    required Color expiryColor
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Center(
              child: Text(code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 3, fontFamily: 'monospace')),
            ),
          ),
          const SizedBox(height: 10),
          Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.access_time, size: 14, color: expiryColor),
               const SizedBox(width: 5),
               Text(expiry, style: TextStyle(color: expiryColor, fontSize: 13, fontWeight: FontWeight.w500)),
             ],
           ),
           const SizedBox(height: 15),
           Row(
             children: [
               Expanded(
                 child: ElevatedButton.icon(
                   onPressed: (){},
                   icon: const Icon(Icons.ios_share, size: 16),
                   label: const Text("Compartir"),
                   style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white, elevation: 0),
                 ),
               ),
               const SizedBox(width: 10),
               Expanded(
                 child: ElevatedButton.icon(
                   onPressed: (){},
                   icon: const Icon(FontAwesomeIcons.ban, size: 16),
                   label: const Text("Revocar"),
                   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFE5E5), foregroundColor: Colors.red, elevation: 0),
                 ),
               ),
             ],
           )
        ],
      ),
    );
  }
}
