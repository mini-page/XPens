import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../provider/preferences_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appPreferencesControllerProvider);
    final smartReminders = ref.watch(smartRemindersEnabledProvider);
    final privacyMode = ref.watch(privacyModeEnabledProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(localeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Drawer(
      backgroundColor: AppColors.backgroundLight,
      child: Column(
        children: [
          // Profile Header
          _buildHeader(context),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const _SectionHeader(title: 'Settings'),
                _buildThemeTile(context, ref, themeMode, controller),
                _buildLanguageTile(context, locale, controller),
                _buildCurrencyTile(context, currencySymbol, controller),
                _buildToggleTile(
                  icon: Icons.security_outlined,
                  title: 'Privacy Mode',
                  subtitle: 'Mask balances',
                  value: privacyMode,
                  onChanged: controller.setPrivacyMode,
                ),
                _buildToggleTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Smart Reminders',
                  subtitle: 'Gentle nudges',
                  value: smartReminders,
                  onChanged: controller.setSmartReminders,
                ),

                const Divider(height: 32, indent: 20, endIndent: 20),

                const _SectionHeader(title: 'Utility'),
                _buildDrawerTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About XPensa',
                  onTap: () {
                    // Show about dialog or navigate
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Support',
                  onTap: () {
                    // Handle support
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.more_horiz_rounded,
                  title: 'Miscellaneous',
                  onTap: () {
                    // Handle misc
                  },
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, Color(0xFF3E90FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(32),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white24,
            child: Text(
              'P',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'XPensa User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Keep spending simple.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
    AppPreferencesController controller,
  ) {
    return ListTile(
      leading: const _TileIcon(icon: Icons.palette_outlined),
      title: const Text(
        'Appearance',
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: DropdownButton<String>(
        value: currentMode.name,
        underline: const SizedBox(),
        onChanged: (value) {
          if (value != null) {
            controller.setThemeMode(value);
          }
        },
        items: const [
          DropdownMenuItem(value: 'light', child: Text('Light')),
          DropdownMenuItem(value: 'dark', child: Text('Dark')),
          DropdownMenuItem(value: 'system', child: Text('System')),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String currentLocale,
    AppPreferencesController controller,
  ) {
    return ListTile(
      leading: const _TileIcon(icon: Icons.language_rounded),
      title: const Text(
        'Language',
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: DropdownButton<String>(
        value: currentLocale,
        underline: const SizedBox(),
        onChanged: (value) {
          if (value != null) {
            controller.setLocale(value);
          }
        },
        items: [
          const DropdownMenuItem(value: 'en_IN', child: Text('English (IN)')),
          const DropdownMenuItem(value: 'en_US', child: Text('English (US)')),
          const DropdownMenuItem(value: 'hi_IN', child: Text('हिन्दी')),
        ],
      ),
    );
  }

  Widget _buildCurrencyTile(
    BuildContext context,
    String currentCurrency,
    AppPreferencesController controller,
  ) {
    return ListTile(
      leading: const _TileIcon(icon: Icons.payments_outlined),
      title: const Text(
        'Currency',
        style: TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: DropdownButton<String>(
        value: currentCurrency,
        underline: const SizedBox(),
        onChanged: (value) {
          if (value != null) {
            controller.setCurrencySymbol(value);
          }
        },
        items: [
          const DropdownMenuItem(value: '\u20B9', child: Text('Rupee (\u20B9)')),
          const DropdownMenuItem(value: '\$', child: Text('Dollar (\$)')),
          const DropdownMenuItem(value: '\u20AC', child: Text('Euro (\u20AC)')),
          const DropdownMenuItem(value: '\u00A3', child: Text('Pound (\u00A3)')),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: _TileIcon(icon: icon),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    void Function()? onTap,
  }) {
    return ListTile(
      leading: _TileIcon(icon: icon),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  const _TileIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.lightBlueBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primaryBlue, size: 20),
    );
  }
}
