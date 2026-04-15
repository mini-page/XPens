import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../provider/expense_providers.dart';
import '../provider/preferences_providers.dart';
import 'stats/stats_widgets.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _selectedTab = 0;
  String _selectedRange = 'This Month';

  static const _tabLabels = <String>['Flow', 'Spend', 'Habit'];

  static const _rangeOptions = <String>[
    'This Week',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'This Year',
  ];

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(analyticsSnapshotProvider);
    final privacyModeEnabled = ref.watch(privacyModeEnabledProvider);
    final currencyFormat = ref.watch(currencyFormatProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            const Text(
              'ANALYTICS',
              style: TextStyle(
                color: AppColors.primaryBlue,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Financial Insights',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                  ),
                ),
                Tooltip(
                  message: 'Export coming soon',
                  child: Opacity(
                    opacity: 0.5,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        color: AppColors.surfaceAccent,
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Tab selector
            AnalyticsPillTabs(
              tabs: _tabLabels,
              selected: _selectedTab,
              onChanged: (index) => setState(() => _selectedTab = index),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Glass card
            AnalyticsGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Tab title
                  Text(
                    _tabLabels[_selectedTab],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Range picker
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    onTap: _showRangePicker,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _selectedRange,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Tab content with animated crossfade
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _buildTabContent(
                      snapshot: snapshot,
                      currencyFormat: currencyFormat,
                      privacyModeEnabled: privacyModeEnabled,
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

  Widget _buildTabContent({
    required AnalyticsSnapshot snapshot,
    required NumberFormat currencyFormat,
    required bool privacyModeEnabled,
  }) {
    switch (_selectedTab) {
      case 0:
        return FlowTabContent(
          key: const ValueKey<int>(0),
          snapshot: snapshot,
          currencyFormat: currencyFormat,
          privacyModeEnabled: privacyModeEnabled,
        );
      case 1:
        return SpendTabContent(
          key: const ValueKey<int>(1),
          snapshot: snapshot,
          currencyFormat: currencyFormat,
          privacyModeEnabled: privacyModeEnabled,
        );
      case 2:
        return HabitTabContent(
          key: const ValueKey<int>(2),
          snapshot: snapshot,
          currencyFormat: currencyFormat,
          privacyModeEnabled: privacyModeEnabled,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _showRangePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.xxl),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _rangeOptions.map((option) {
              final active = option == _selectedRange;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                tileColor: active
                    ? AppColors.surfaceAccent
                    : Colors.transparent,
                title: Text(
                  option,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppColors.primaryBlue
                        : AppColors.textDark,
                  ),
                ),
                trailing: active
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryBlue,
                      )
                    : null,
                onTap: () => Navigator.pop(context, option),
              );
            }).toList(growable: false),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() => _selectedRange = selected);
    }
  }
}
