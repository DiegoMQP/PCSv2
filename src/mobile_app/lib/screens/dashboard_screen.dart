import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        child: Text("Bienvenido de nuevo,", 
                          style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      ),
                      const SizedBox(height: 5),
                      FadeInDown(
                        delay: const Duration(milliseconds: 100),
                        child: Consumer<UserProvider>(
                           builder: (context, user, child) => Text(
                              user.username.isNotEmpty ? user.username : "Usuario",
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)
                           ),
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFFE5E5EA),
                    child: Icon(Icons.person, color: Colors.grey),
                  )
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Stats Card
                    FadeInUp(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Column(
                          children: [
                            const Text("Visitas Activas", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                            Text("0", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Theme.of(context).primaryColor)),
                            const Text("Total hoy", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Grid Actions
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildActionBtn(
                          icon: FontAwesomeIcons.userPlus, 
                          label: "Nueva Visita", 
                          color: Theme.of(context).primaryColor,
                          onTap: () => Navigator.pushNamed(context, '/guest'),
                        ),
                        _buildActionBtn(
                          icon: FontAwesomeIcons.clockRotateLeft, 
                          label: "Historial", 
                          color: const Color(0xFF34C759),
                          onTap: () => Navigator.pushNamed(context, '/logs'),
                        ),
                        _buildActionBtn(
                          icon: FontAwesomeIcons.qrcode, 
                          label: "Mis Códigos", 
                          color: const Color(0xFFFF9500),
                          onTap: () => Navigator.pushNamed(context, '/codes'),
                        ),
                        _buildActionBtn(
                          icon: FontAwesomeIcons.gear, 
                          label: "Ajustes", 
                          color: const Color(0xFFAF52DE),
                          onTap: () {}, // TODO
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: const Border(top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
             setState(() => _currentIndex = index);
             if (index == 1) Navigator.pushNamed(context, '/alerts');
             if (index == 2) Navigator.pushNamed(context, '/profile');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: const Color(0xFF8E8E93),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)), label: "Inicio"),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.notifications)), label: "Alertas"),
            BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)), label: "Perfil"),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))
            ]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 15),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
