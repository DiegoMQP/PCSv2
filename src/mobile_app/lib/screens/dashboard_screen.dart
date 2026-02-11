import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final isDesktop = MediaQuery.of(context).size.width > 700;
  
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 250,
                color: Theme.of(context).cardTheme.color,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Icon(Icons.shield, size: 50, color: Theme.of(context).colorScheme.primary),
                    SvgPicture.asset("assets/images/logo.svg", width: 80, height: 80, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                    const SizedBox(height: 40),
                    ListTile(leading: const Icon(Icons.home), title: const Text("Inicio"), selected: _currentIndex == 0, onTap: () {}),
                    ListTile(leading: const Icon(Icons.notifications), title: const Text("Alertas"), selected: _currentIndex == 1, onTap: () => Navigator.pushNamed(context, '/alerts')),
                    ListTile(leading: const Icon(Icons.person), title: const Text("Perfil"), selected: _currentIndex == 2, onTap: () => Navigator.pushNamed(context, '/profile')),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: SingleChildScrollView(
                   child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 30),
                      _buildStatsCard(context),
                      const SizedBox(height: 30),
                      Text("Acciones Rápidas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
                      const SizedBox(height: 20),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        children: _buildGridChildren(context),
                      )
                    ],
                   ),
                  ),
                ),
              )
            ],
          )
        : Center(
            child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: _buildHeader(context)
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildStatsCard(context),
                          const SizedBox(height: 20),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            children: _buildGridChildren(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isDesktop ? null : Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
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
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
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

  Widget _buildHeader(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: const Text("Bienvenido de nuevo,", 
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
              const SizedBox(height: 5),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: Consumer<UserProvider>(
                    builder: (context, user, child) {
                      String displayName = "Usuario";
                      if (user.name.isNotEmpty) {
                        String tempName = user.name;
                        if (tempName.contains('@')) {
                           tempName = tempName.split('@')[0];
                        }
                        displayName = tempName.split(' ').first; 
                        if (displayName.isNotEmpty) {
                           displayName = "${displayName[0].toUpperCase()}${displayName.substring(1)}";
                        }
                      }
                      return Text(
                        displayName,
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)
                      );
                    },
                ),
              ),
            ],
          ),
          FadeInDown(
             child: SvgPicture.asset("assets/images/logo.svg", width: 45, height: 45),
          )
        ],
      );
  }

  Widget _buildStatsCard(BuildContext context) {
     return FadeInUp(
        child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10))
            ]
        ),
        child: Column(
            children: [
            const Text("Visitas Activas", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text("0", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
            const Text("Total hoy", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
        ),
        ),
     );
  }

  List<Widget> _buildGridChildren(BuildContext context) {
      return [
        _buildActionBtn(
            icon: Icons.person_add, 
            label: "Nueva Visita", 
            color: Theme.of(context).colorScheme.primary,
            onTap: () => Navigator.pushNamed(context, '/guest'),
        ),
        _buildActionBtn(
            icon: Icons.history, 
            label: "Historial", 
            color: Colors.green, // Keep distinctive color
            onTap: () => Navigator.pushNamed(context, '/logs'),
        ),
        _buildActionBtn(
            icon: Icons.qr_code, 
            label: "Mis Códigos", 
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/codes'),
        ),
        _buildActionBtn(
            icon: Icons.settings, 
            label: "Ajustes", 
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/profile'), 
        ),
      ];
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
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
