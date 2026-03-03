import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'codes_screen.dart';
import 'guests_screen.dart';
import 'logs_screen.dart';
import 'admin_users_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selected = 0;

  List<_NavItem> _navItemsFor(UserProvider user) {
    return [
      const _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'home'),
      const _NavItem(Icons.qr_code_2_outlined, Icons.qr_code_2, 'codes'),
      const _NavItem(Icons.people_outline, Icons.people, 'guests'),
      const _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'logs'),
      if (user.isMainAdmin)
        const _NavItem(Icons.manage_accounts_outlined, Icons.manage_accounts, 'manageUsers'),
      const _NavItem(Icons.notifications_outlined, Icons.notifications, 'alerts'),
      const _NavItem(Icons.person_outline, Icons.person, 'profile'),
    ];
  }

  Widget _buildPage(UserProvider user) {
    final navItems = _navItemsFor(user);
    final key = (_selected < navItems.length) ? navItems[_selected].labelKey : 'home';
    switch (key) {
      case 'codes':       return CodesScreen(username: user.username, location: user.location);
      case 'guests':      return GuestsScreen(username: user.username);
      case 'logs':        return LogsScreen(username: user.username);
      case 'manageUsers': return const AdminUsersScreen();
      case 'alerts':      return const AlertsScreen();
      case 'profile':     return const ProfileScreen();
      default:            return _HomeOverview(user: user, onNavigate: (i) => setState(() => _selected = i));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user     = Provider.of<UserProvider>(context);
    final lang     = Provider.of<LanguageProvider>(context);
    final navItems = _navItemsFor(user);
    final isWide   = MediaQuery.of(context).size.width >= 720;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              selected: _selected,
              items: navItems,
              user: user,
              onSelect: (i) => setState(() => _selected = i),
              onLogout: () => _logout(context, user),
            ),
            Expanded(
              child: Scaffold(
                appBar: _buildAppBar(context, user, lang, navItems),
                body: _buildPage(user),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, user, lang, navItems),
      drawer: Drawer(
        child: _Sidebar(
          selected: _selected,
          items: navItems,
          user: user,
          onSelect: (i) {
            Navigator.pop(context);
            setState(() => _selected = i);
          },
          onLogout: () => _logout(context, user),
        ),
      ),
      body: _buildPage(user),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected < navItems.length ? _selected : 0,
        onTap: (i) => setState(() => _selected = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0A84FF),
        unselectedItemColor: Colors.white38,
        items: navItems.map((n) => BottomNavigationBarItem(
          icon: Icon(n.icon),
          activeIcon: Icon(n.activeIcon),
          label: L.of(lang, n.labelKey),
        )).toList(),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, UserProvider user, LanguageProvider lang, List<_NavItem> navItems) {
    return AppBar(
      title: Text(_selected < navItems.length ? L.of(lang, navItems[_selected].labelKey) : ''),
      surfaceTintColor: Colors.transparent,
      actions: [
        // Language toggle
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: lang.toggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 16, color: Color(0xFF0A84FF)),
                  const SizedBox(width: 6),
                  Text(
                    lang.isEnglish ? 'EN' : 'ES',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_horiz_rounded, size: 15, color: Colors.white38),
                ],
              ),
            ),
          ),
        ),
        // User avatar
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF0A84FF).withOpacity(0.2),
            child: Text(
              user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
              style: const TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _logout(BuildContext context, UserProvider user) {
    user.clearUser();
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  const _NavItem(this.icon, this.activeIcon, this.labelKey);
}

// ─────────────── Sidebar ─────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selected;
  final List<_NavItem> items;
  final UserProvider user;
  final void Function(int) onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.selected, required this.items, required this.user,
    required this.onSelect, required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      width: 240,
      color: const Color(0xFF1C1C1E),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // App title (without circular logo)
          const Text('PCS Access',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(L.of(lang, 'sidebarSub'),
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          const SizedBox(height: 32),
          // User chip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1A73E8).withOpacity(0.3),
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                      Text(user.location.isNotEmpty ? user.location : user.username,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final isSelected = i == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      isSelected ? items[i].activeIcon : items[i].icon,
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                    title: Text(L.of(lang, items[i].labelKey),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 14,
                      )),
                    tileColor: isSelected ? const Color(0xFF0A84FF) : Colors.transparent,
                    onTap: () => onSelect(i),
                  ),
                );
              },
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Icon(Icons.logout, color: Colors.white.withOpacity(0.5), size: 20),
              title: Text(L.of(lang, 'logout'), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Home Overview ───────────────────────────
class _HomeOverview extends StatefulWidget {
  final UserProvider user;
  final void Function(int) onNavigate;
  const _HomeOverview({required this.user, required this.onNavigate});
  @override
  State<_HomeOverview> createState() => _HomeOverviewState();
}

class _HomeOverviewState extends State<_HomeOverview> {
  int _codesCount = 0;
  int _logsCount = 0;
  bool _loading = true;
  bool _serverOnline = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final api = ApiService();
    final results = await Future.wait([
      api.getCodes(widget.user.username),
      api.getLogs(widget.user.username),
      api.checkHealth(),
    ]);
    if (mounted) {
      setState(() {
        _codesCount = (results[0] as List).length;
        _logsCount = (results[1] as List).length;
        _serverOnline = results[2] as bool;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    final statusColor = _loading ? Colors.grey : _serverOnline ? Colors.green : Colors.red;
    final statusLabel = _loading
        ? L.of(lang, 'checking')
        : _serverOnline
            ? L.of(lang, 'serverOnline')
            : L.of(lang, 'serverOffline');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text('${L.of(lang, 'greeting')} ${widget.user.name}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(L.of(lang, 'welcomeText'),
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
          const SizedBox(height: 28),

          // Server status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                    ),
                    const SizedBox(width: 6),
                    Text(statusLabel,
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Stats cards
          LayoutBuilder(builder: (_, cst) {
            final cols = cst.maxWidth > 700 ? 4 : cst.maxWidth > 400 ? 2 : 1;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cols,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: [
                _StatCard(L.of(lang, 'activeCodes'), _loading ? '...' : '$_codesCount',
                    Icons.qr_code_2, const Color(0xFF0A84FF)),
                _StatCard(L.of(lang, 'logs'), _loading ? '...' : '$_logsCount',
                    Icons.receipt_long, const Color(0xFF32D74B)),
                _StatCard(L.of(lang, 'myHome'),
                    widget.user.location.isNotEmpty ? widget.user.location : '-',
                    Icons.home, const Color(0xFFFFD60A)),
                _StatCard(L.of(lang, 'myRole'), widget.user.role,
                    Icons.verified_user_outlined, const Color(0xFFFF453A)),
              ],
            );
          }),
          const SizedBox(height: 32),

          Text(L.of(lang, 'quickActions'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickAction(L.of(lang, 'newCode'),
                  Icons.add_circle_outline, const Color(0xFF0A84FF),
                  () => widget.onNavigate(1)),
              _QuickAction(L.of(lang, 'inviteGuest'),
                  Icons.person_add_outlined, const Color(0xFF32D74B),
                  () => widget.onNavigate(2)),
              _QuickAction(L.of(lang, 'viewLogs'),
                  Icons.list_alt_outlined, const Color(0xFFFFD60A),
                  () => widget.onNavigate(3)),
              if (widget.user.isMainAdmin)
                _QuickAction(L.of(lang, 'manageUsers'),
                    Icons.manage_accounts_outlined, const Color(0xFFFF453A),
                    () => widget.onNavigate(4)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45))),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
