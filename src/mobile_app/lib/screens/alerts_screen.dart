import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<dynamic>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _notificationsFuture = ApiService().getNotifications(userProvider.username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Alertas")),
      body: FutureBuilder<List<dynamic>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
              }
              final alerts = snapshot.data ?? [];
              if (alerts.isEmpty) {
                  return const Center(child: Text("No hay notificaciones nuevas"));
              }
              return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                      final alert = alerts[index];
                      final isExpiration = alert['type'] == 'EXPIRATION';
                      return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                              leading: Icon(
                                isExpiration ? FontAwesomeIcons.clock : FontAwesomeIcons.triangleExclamation, 
                                color: isExpiration ? Colors.red : Colors.orange
                              ),
                              title: Text(isExpiration ? 'Código Expirado' : (alert['title'] ?? 'Alerta')),
                              subtitle: Text(alert['message'] ?? ''),
                          ),
                      );
                  }
              );
          }
      ),
    );
  }
}

