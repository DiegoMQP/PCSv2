import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alertas"), actions: [
        TextButton(onPressed: (){}, child: const Text("Leído")),
      ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("NUEVAS", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
          
          _buildAlert(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.red,
            title: "Intento de Acceso",
            time: "Hace 5m",
            msg: "Código #9921 ingresado incorrectamente 3 veces.",
            isUnread: true,
          ),
          _buildAlert(
            icon: Icons.campaign,
            iconColor: Colors.blue,
            title: "Mantenimiento",
            time: "Hace 1h",
            msg: "El portón principal estará en mantenimiento hoy de 3pm a 5pm.",
            isUnread: true,
            isLast: true,
          ),

          const SizedBox(height: 20),
          const Text("ESTA SEMANA", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 10),
           _buildAlert(
            icon: Icons.shield,
            iconColor: Colors.grey,
            title: "Sistema Actualizado",
            time: "Ayer",
            msg: "La validación de códigos QR ha sido mejorada.",
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAlert({
    required IconData icon, required Color iconColor, required String title,
    required String time, required String msg, bool isUnread = false, bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast ? null : const Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
        borderRadius: BorderRadius.circular(isLast ? 12 : 0) // Simplified radius logic
      ),
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(msg, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          if(isUnread)
             Container(
               margin: const EdgeInsets.only(left: 10, top: 5),
               width: 10, height: 10,
               decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
             )
        ],
      ),
    );
  }
}
