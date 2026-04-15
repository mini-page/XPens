import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../provider/account_providers.dart';
import '../provider/preferences_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Preferences state
  String _selectedLocale = 'en_IN';
  String _selectedCurrency = '₹';
  String _selectedThemeKey = 'light';
  bool _smartReminders = true;
  String _accountName = 'Main Account';
  double _initialBalance = 0.0;
  String _displayName = '';

  // Step definitions
  static const int _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: List.generate(_pageCount, (index) {
                  final isActive = index <= _currentPage;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < _pageCount - 1 ? 6 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryBlue
                            : AppColors.surfaceAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(
                    displayName: _displayName,
                    onNameChanged: (v) => _displayName = v,
                  ),
                  _LocalePage(
                    selectedLocale: _selectedLocale,
                    selectedCurrency: _selectedCurrency,
                    onLocaleChanged: (v) =>
                        setState(() => _selectedLocale = v),
                    onCurrencyChanged: (v) =>
                        setState(() => _selectedCurrency = v),
                  ),
                  _AccountPage(
                    accountName: _accountName,
                    initialBalance: _initialBalance,
                    onNameChanged: (v) => _accountName = v,
                    onBalanceChanged: (v) =>
                        _initialBalance = double.tryParse(v) ?? 0,
                  ),
                  _PreferencesPage(
                    themeKey: _selectedThemeKey,
                    smartReminders: _smartReminders,
                    onThemeChanged: (v) =>
                        setState(() => _selectedThemeKey = v),
                    onRemindersChanged: (v) =>
                        setState(() => _smartReminders = v),
                  ),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: AppColors.primaryBlue),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: AppButton(
                      label: _currentPage == _pageCount - 1
                          ? 'Get Started 🚀'
                          : 'Continue',
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final name = _displayName.trim();
    final accountName = _accountName.trim().isEmpty ? 'Main Account' : _accountName;

    await ref.read(accountControllerProvider).saveAccount(
          name: accountName,
          iconKey: 'wallet',
          balance: _initialBalance,
        );

    await ref.read(appPreferencesControllerProvider).updateAll(
          themeModeKey: _selectedThemeKey,
          locale: _selectedLocale,
          currencySymbol: _selectedCurrency,
          smartRemindersEnabled: _smartReminders,
          isOnboardingCompleted: true,
        );

    if (name.isNotEmpty) {
      await ref.read(appPreferencesControllerProvider).setDisplayName(name);
    }
  }
}

// ---------------------------------------------------------------------------
// Page 1: Welcome
// ---------------------------------------------------------------------------
class _WelcomePage extends StatefulWidget {
  const _WelcomePage({
    required this.displayName,
    required this.onNameChanged,
  });

  final String displayName;
  final ValueChanged<String> onNameChanged;

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(AppAssets.logo, width: 96, height: 96),
          ),
          const SizedBox(height: 28),
          Text(
            'Welcome to XPensa',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your smart offline expense tracker.\nLet\'s set you up in a minute.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSubtle,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _nameController,
            onChanged: widget.onNameChanged,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: 'What should we call you? (optional)',
              hintText: 'Your name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
          ),
          const Spacer(flex: 2),
          Text(
            'Version ${AppConstants.version}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 2: Language & Currency
// ---------------------------------------------------------------------------
class _LocalePage extends StatelessWidget {
  const _LocalePage({
    required this.selectedLocale,
    required this.selectedCurrency,
    required this.onLocaleChanged,
    required this.onCurrencyChanged,
  });

  final String selectedLocale;
  final String selectedCurrency;
  final ValueChanged<String> onLocaleChanged;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _OnboardingStepHeader(
            icon: Icons.language_rounded,
            title: 'Language & Currency',
            subtitle: 'Choose your region and preferred currency',
          ),
          const SizedBox(height: 28),
          _SectionLabel(label: 'Language'),
          const SizedBox(height: 10),
          _OptionGrid<String>(
            options: AppConstants.locales
                .map((l) => _OptionItem(label: l.label, value: l.locale))
                .toList(),
            selected: selectedLocale,
            onSelected: onLocaleChanged,
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'Currency'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppConstants.currencies.map((c) {
              final isSelected = selectedCurrency == c.symbol;
              return ChoiceChip(
                label: Text(c.label),
                selected: isSelected,
                onSelected: (_) => onCurrencyChanged(c.symbol),
                selectedColor: AppColors.primaryBlue,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 3: First Account
// ---------------------------------------------------------------------------
class _AccountPage extends StatelessWidget {
  const _AccountPage({
    required this.accountName,
    required this.initialBalance,
    required this.onNameChanged,
    required this.onBalanceChanged,
  });

  final String accountName;
  final double initialBalance;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onBalanceChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _OnboardingStepHeader(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Your First Account',
            subtitle: 'This is where your transactions will be recorded',
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                TextFormField(
                  initialValue: accountName,
                  onChanged: onNameChanged,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g. Cash, HDFC, SBI',
                    prefixIcon: const Icon(Icons.wallet_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: initialBalance > 0
                      ? initialBalance.toStringAsFixed(0)
                      : '',
                  onChanged: onBalanceChanged,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Opening Balance (optional)',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'You can add more accounts later from the Tools page.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page 4: Theme & Preferences
// ---------------------------------------------------------------------------
class _PreferencesPage extends StatelessWidget {
  const _PreferencesPage({
    required this.themeKey,
    required this.smartReminders,
    required this.onThemeChanged,
    required this.onRemindersChanged,
  });

  final String themeKey;
  final bool smartReminders;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<bool> onRemindersChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _OnboardingStepHeader(
            icon: Icons.tune_rounded,
            title: 'Preferences',
            subtitle: 'Customise how XPensa looks and behaves',
          ),
          const SizedBox(height: 28),
          _SectionLabel(label: 'Theme'),
          const SizedBox(height: 10),
          Row(
            children: [
              _ThemeOption(
                  label: 'Light',
                  key: 'light',
                  icon: Icons.light_mode_outlined,
                  selected: themeKey,
                  onTap: onThemeChanged),
              const SizedBox(width: 10),
              _ThemeOption(
                  label: 'Dark',
                  key: 'dark',
                  icon: Icons.dark_mode_outlined,
                  selected: themeKey,
                  onTap: onThemeChanged),
              const SizedBox(width: 10),
              _ThemeOption(
                  label: 'System',
                  key: 'system',
                  icon: Icons.brightness_auto_outlined,
                  selected: themeKey,
                  onTap: onThemeChanged),
            ],
          ),
          const SizedBox(height: 28),
          _SectionLabel(label: 'Notifications'),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Smart Reminders',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: const Text(
                'Get notified for pending bills & recurring transactions',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              value: smartReminders,
              activeColor: AppColors.primaryBlue,
              onChanged: onRemindersChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _OnboardingStepHeader extends StatelessWidget {
  const _OnboardingStepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _OptionItem<T> {
  const _OptionItem({required this.label, required this.value});
  final String label;
  final T value;
}

class _OptionGrid<T> extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_OptionItem<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = opt.value == selected;
        return GestureDetector(
          onTap: () => onSelected(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue
                  : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.surfaceAccent,
                width: 1.5,
              ),
            ),
            child: Text(
              opt.label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String key;
  final IconData icon;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.surfaceAccent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color:
                    isSelected ? AppColors.primaryBlue : AppColors.textSubtle,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
