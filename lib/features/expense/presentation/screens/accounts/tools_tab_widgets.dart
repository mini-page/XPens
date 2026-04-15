import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../routes/app_routes.dart';
import '../../../data/models/expense_model.dart';
import '../../provider/expense_providers.dart';
import '../../provider/preferences_providers.dart';
import '../../widgets/recurring_tool_view.dart';
import '../../widgets/split_bill_tool_view.dart';

const _maxDisplayedFutureTransactions = 6;

/// Renders the Tools workspace tab bar with Split, Recurring, and Future tabs.
///
/// Tabs are non-scrollable and fill the full width so all three are always
/// visible at a glance.
class ToolsTabBar extends StatelessWidget {
  const ToolsTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        tabs: const <Tab>[
          Tab(text: 'Split'),
          Tab(text: 'Recurring'),
          Tab(text: 'Future'),
        ],
      ),
    );
  }
}

/// Renders the tab views that correspond to [ToolsTabBar].
/// Each tab hosts one tool section.
/// Must be used under a [DefaultTabController] with length 3.
class ToolsTabView extends StatelessWidget {
  const ToolsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: <Widget>[
        _ToolsTabPane(child: SplitBillToolView()),
        _ToolsTabPane(child: RecurringToolView()),
        _ToolsTabPane(child: FutureTransactionsToolView()),
      ],
    );
  }
}

/// Scroll wrapper used by each tool tab to prevent overflow.
class _ToolsTabPane extends StatelessWidget {
  const _ToolsTabPane({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: child);
  }
}

/// Upcoming transactions that are dated after today.
class FutureTransactionsToolView extends ConsumerWidget {
  const FutureTransactionsToolView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider).value ?? const <ExpenseModel>[];
    final currency = ref.watch(currencyFormatProvider);
    final today = DateUtils.dateOnly(DateTime.now());

    final futureTransactions = expenses
        .where(
          (expense) => DateUtils.dateOnly(expense.date.toLocal()).isAfter(today),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final hasMore = futureTransactions.length > _maxDisplayedFutureTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Header row — title + add button (mirrors RecurringToolView pattern)
        Row(
          children: <Widget>[
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Future Transactions',
                    style: AppTextStyles.sectionHeading,
                  ),
                  Text(
                    'Review and plan upcoming entries',
                    style: AppTextStyles.sectionSubtitle,
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: () => AppRoutes.pushAddExpense(
                context,
                initialDate: today.add(const Duration(days: 1)),
              ),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add future transaction',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Empty state — icon + message (no separate floating CTA)
        if (futureTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.event_note_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'No upcoming transactions',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Add a transaction with a future date to plan ahead.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else ...<Widget>[
          ...futureTransactions.take(_maxDisplayedFutureTransactions).map((expense) {
            final signedAmount =
                expense.isIncome ? expense.amount : -expense.amount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            expense.note.isEmpty ? expense.category : expense.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEE, d MMM').format(expense.date.toLocal()),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currency.format(signedAmount),
                      style: TextStyle(
                        color: expense.isIncome
                            ? AppColors.success
                            : AppColors.primaryBlue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // "View all (N)" escape when the list is capped
          if (hasMore)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => AppRoutes.pushRecordsHistory(context),
                child: Text(
                  'View all (${futureTransactions.length})',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
