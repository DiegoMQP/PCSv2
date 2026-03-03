import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../l10n/app_localizations.dart';

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
                    const Text(
                      "PCS Security",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 40),
                    ListTile(leading: const Icon(Icons.home), title: Text(context.tr('home')), selected: _currentIndex == 0, onTap: () {}),
                    ListTile(leading: const Icon(Icons.notifications), title: Text(context.tr('alerts')), selected: _currentIndex == 1, onTap: () => Navigator.pushNamed(context, '/alerts')),
                    ListTile(leading: const Icon(Icons.person), title: Text(context.tr('profile')), selected: _currentIndex == 2, onTap: () => Navigator.pushNamed(context, '/profile')),
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
                      Text(context.tr('quick_actions'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
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
          items: [
            BottomNavigationBarItem(icon: Padding(padding: const EdgeInsets.only(bottom: 4), child: Icon(Icons.home)), label: context.tr('home')),
            BottomNavigationBarItem(icon: Padding(padding: const EdgeInsets.only(bottom: 4), child: Icon(Icons.notifications)), label: context.tr('alerts')),
            BottomNavigationBarItem(icon: Padding(padding: const EdgeInsets.only(bottom: 4), child: Icon(Icons.person)), label: context.tr('profile')),
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
                child: Text(context.tr('welcome_back'), 
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
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
            Text(context.tr('active_visits'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Text("0", style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
            Text(context.tr('total_today'), style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
        ),
        ),
     );
  }

  List<Widget> _buildGridChildren(BuildContext context) {
      final user = Provider.of<UserProvider>(context, listen: false);
      return [
        _buildActionBtn(
            icon: Icons.person_add, 
            label: context.tr('guest_access'), 
            color: Theme.of(context).colorScheme.primary,
            onTap: () => Navigator.pushNamed(context, '/guest'),
        ),
        _buildActionBtn(
            icon: Icons.history, 
            label: context.tr('history'), 
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, '/logs'),
        ),
        _buildActionBtn(
            icon: Icons.qr_code, 
            label: context.tr('my_codes'), 
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/codes'),
        ),
        _buildActionBtn(
            icon: Icons.settings, 
            label: context.tr('profile'), 
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/profile'), 
        ),
        if (user.isMainAdmin)
          _buildActionBtn(
            icon: Icons.manage_accounts,
            label: context.tr('admin'),
            color: const Color(0xFFFF3B30),
            onTap: () => Navigator.pushNamed(context, '/admin_users'),
          ),
      ];
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: _ActionButton(
        icon: icon,
        label: label,
        color: color,
        onTap: onTap,
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovering ? 0.15 : 0.05),
                blurRadius: _isHovering ? 20 : 15,
                offset: Offset(0, _isHovering ? 6 : 4),
              )
            ],
          ),
          transform: _isHovering ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(_isHovering ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(height: 15),
              Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
