import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We already moved theme logic to main.dart system settings
    // But for "checkbox mode" requesting user, we should probably check if we can toggle ThemeMode
    // However, user said "checkbox doesn't work". Since we use system mode in main.dart, we need a ThemeProvider if we want manual toggle.
    // For now, let's just make sure containers use Theme colors (grey/card color) instead of white.
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Consumer<UserProvider>(
               builder: (context, user, _) {
                 return Column(
                  children: [
                    // ── Profile Card ──────────────────────────
                    _ProfileCard(user: user),
                    const SizedBox(height: 25),

                    // ── Appearance ────────────────────────────
                    _buildSettingsGroup(context, [
                      _buildSettingItem(context, Icons.security, Colors.blue, context.tr('security_label')),
                      _buildSettingItem(context, Icons.notifications, Colors.pink, context.tr('notifications')),
                      Consumer<ThemeProvider>(
                        builder: (ctx, themeProvider, _) => _buildSettingItem(
                          ctx,
                          themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          Colors.indigo,
                          ctx.tr('dark_mode'),
                          widget: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (v) => themeProvider.toggleTheme(v),
                            activeColor: const Color(0xFF0A84FF),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 25),

                    // ── Language ──────────────────────────────
                    _LanguageSection(),

                    const SizedBox(height: 25),

                    // ── Support ───────────────────────────────
                    _buildSettingsGroup(context, [
                      _buildSettingItem(context, Icons.help, Colors.grey, context.tr('help')),
                    ]),

                    const SizedBox(height: 30),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            Provider.of<UserProvider>(context, listen: false).clearUser();
                            Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(context).cardTheme.color,
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(context.tr('logout'), style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(context.tr('version'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            );
          }
         )
        ),
      ),
    ));
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color, // Theme color
          borderRadius: BorderRadius.circular(12)
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, Color color, String label, {Widget? widget}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyMedium?.color))),
              if (widget != null) widget else const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
        Divider(height: 1, indent: 50, color: Theme.of(context).dividerColor),
      ],
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final UserProvider user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 30, color: Colors.grey),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isNotEmpty ? user.name : context.tr('user'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                Text(
                  user.username.isNotEmpty ? user.username : 'usuario@email.com',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language Section ──────────────────────────────────────────
class _LanguageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.language, color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    context.tr('language_title'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ),
                Text(localeProvider.flagEmoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          Divider(height: 1, indent: 50, color: Theme.of(context).dividerColor),
          // Language chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Row(
              children: LocaleProvider.supportedLanguages.map((lang) {
                final isSelected = localeProvider.locale == lang['code'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => localeProvider.setLocale(lang['code']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primary.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? primary : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            lang['name']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: isSelected ? primary : Colors.grey,
                            ),
                          ),
                          if (isSelected) ...[const SizedBox(height: 2), Icon(Icons.check_circle_rounded, color: primary, size: 12)],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
