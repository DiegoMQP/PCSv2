import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late Future<List<dynamic>> _logsFuture;
  String? _lastUsername;

  Future<void> _refresh() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    if (user.username.isEmpty) return;
    setState(() {
      _logsFuture = ApiService().getLogs(user.username);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context, listen: false);
    if ((user.username.isNotEmpty) && user.username != _lastUsername) {
      _lastUsername = user.username;
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    if (user.username.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text(context.tr('history'))),
        body: Center(child: Text(context.tr('login_to_view'))),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('history')),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: context.tr('search'),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                   return Center(child: Text('${context.tr('error')}: ${snapshot.error}'));
                }
                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                   return Center(child: Text(context.tr('no_history')));
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final name = log['visitor_name'] ?? context.tr('unknown');
                    final status = log['status'] ?? 'SCHEDULED';
                    final timestamp = log['created_at'] ?? 0;
                    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                    final timeStr = DateFormat('HH:mm').format(date);
                    final dayStr = DateFormat('dd/MM').format(date);
                    
                    Color iconColor = Colors.blue;
                    IconData icon = FontAwesomeIcons.user;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Theme.of(context).cardTheme.color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            shape: BoxShape.circle
                          ),
                          child: Center(child: Icon(icon, color: iconColor, size: 18)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(status),
                        trailing: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           crossAxisAlignment: CrossAxisAlignment.end,
                           children: [
                               Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                               Text(dayStr, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                           ]
                        ),
                      ),
                    );
                  }
                );
              }
            )
          ),
        ],
      ),
    );
  }
}
