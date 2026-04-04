import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/account_model.dart';
import '../../data/models/expense_model.dart';
import '../provider/account_providers.dart';
import '../provider/expense_providers.dart';
import '../provider/preferences_providers.dart';
import '../widgets/amount_visibility.dart';
import '../widgets/transaction_card.dart';
import '../widgets/ui_feedback.dart';
import 'add_expense_screen.dart';

enum RecordsFilter { all, today, week, month, future }

class RecordsHistoryScreen extends ConsumerStatefulWidget {
  const RecordsHistoryScreen({super.key});

  @override
  ConsumerState<RecordsHistoryScreen> createState() =>
      _RecordsHistoryScreenState();
}

class _RecordsHistoryScreenState extends ConsumerState<RecordsHistoryScreen> {
  static const String _allAccountsKey = '__all_accounts__';
  RecordsFilter _selectedFilter = RecordsFilter.all;
  String _selectedAccountFilter = _allAccountsKey;

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseListProvider);
    final accountState = ref.watch(accountListProvider);
    final privacyModeEnabled = ref.watch(privacyModeEnabledProvider);
    final expenses = expenseState.value ?? const <ExpenseModel>[];
    final accounts = accountState.value ?? const <AccountModel>[];
    final filteredExpenses = _filterExpenses(expenses);
    final groupedExpenses = _groupExpenses(filteredExpenses);

    final locale = ref.watch(localeProvider);
    final symbol = ref.watch(currencySymbolProvider);

    final currency = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    );
    final filteredTotal = filteredExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.signedAmount,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Records',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SummaryCard(
                filteredTotal: filteredTotal,
                transactionCount: filteredExpenses.length,
                currency: currency,
                privacyModeEnabled: privacyModeEnabled,
              ),
              const SizedBox(height: 18),
              _FilterChips(
                selectedFilter: _selectedFilter,
                onFilterSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                labelForFilter: _labelForFilter,
              ),
              const SizedBox(height: 14),
              _AccountDropdown(
                accounts: accounts,
                onAccountSelected: (value) {
                  setState(() {
                    _selectedAccountFilter = value;
                  });
                },
                allAccountsKey: _allAccountsKey,
                accountFilterLabel: _accountFilterLabel(accounts),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: expenseState.hasError
                    ? const _StateCard(
                        title: 'Unable to load records',
                        message:
                            'The transaction history is not available right now.',
                      )
                    : expenseState.isLoading && expenses.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredExpenses.isEmpty
                    ? const _StateCard(
                        title: 'No matching transactions',
                        message: 'Try another filter or add a new expense.',
                      )
                    : _ExpenseList(
                        groupedExpenses: groupedExpenses,
                        accounts: accounts,
                        privacyModeEnabled: privacyModeEnabled,
                        groupLabel: _groupLabel,
                        accountLabelFor: _accountLabelFor,
                        onEdit: (expense) =>
                            _openEditExpenseScreen(context, expense),
                        onDelete: (expense) =>
                            _confirmDeleteExpense(context, ref, expense),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ExpenseModel> _filterExpenses(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    return expenses
        .where((expense) {
          final localDate = expense.date.toLocal();
          final dateOnly = DateUtils.dateOnly(localDate);
          final matchesAccount =
              _selectedAccountFilter == _allAccountsKey ||
              expense.accountId == _selectedAccountFilter;

          if (!matchesAccount) {
            return false;
          }

          switch (_selectedFilter) {
            case RecordsFilter.today:
              return DateUtils.isSameDay(dateOnly, today);
            case RecordsFilter.week:
              return !dateOnly.isBefore(weekStart) && !dateOnly.isAfter(today);
            case RecordsFilter.month:
              return dateOnly.year == today.year &&
                  dateOnly.month == today.month;
            case RecordsFilter.future:
              return dateOnly.isAfter(today);
            case RecordsFilter.all:
              return true;
          }
        })
        .toList(growable: false)
      ..sort((left, right) => right.date.compareTo(left.date));
  }

  SplayTreeMap<DateTime, List<ExpenseModel>> _groupExpenses(
    List<ExpenseModel> expenses,
  ) {
    final grouped = SplayTreeMap<DateTime, List<ExpenseModel>>(
      (left, right) => right.compareTo(left),
    );

    for (final expense in expenses) {
      final key = DateUtils.dateOnly(expense.date.toLocal());
      grouped.putIfAbsent(key, () => <ExpenseModel>[]).add(expense);
    }

    return grouped;
  }

  String _labelForFilter(RecordsFilter filter) {
    switch (filter) {
      case RecordsFilter.today:
        return 'Today';
      case RecordsFilter.week:
        return 'This Week';
      case RecordsFilter.month:
        return 'This Month';
      case RecordsFilter.future:
        return 'Future';
      case RecordsFilter.all:
        return 'All';
    }
  }

  String _accountFilterLabel(List<AccountModel> accounts) {
    if (_selectedAccountFilter == _allAccountsKey) {
      return 'All accounts';
    }

    for (final account in accounts) {
      if (account.id == _selectedAccountFilter) {
        return account.name;
      }
    }

    return 'Archived account';
  }

  String _groupLabel(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(date, today)) {
      return 'Today';
    }
    if (DateUtils.isSameDay(date, yesterday)) {
      return 'Yesterday';
    }
    return DateFormat('EEE, d MMM yyyy').format(date);
  }

  String? _accountLabelFor(ExpenseModel expense, List<AccountModel> accounts) {
    if (expense.accountId == null) {
      return null;
    }

    for (final account in accounts) {
      if (account.id == expense.accountId) {
        return account.name;
      }
    }

    return 'Archived Account';
  }

  Future<void> _openEditExpenseScreen(
    BuildContext context,
    ExpenseModel expense,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddExpenseScreen(
          expenseId: expense.id,
          initialAmount: expense.amount,
          initialCategory: expense.category,
          initialDate: expense.date.toLocal(),
          initialNote: expense.note,
          initialAccountId: expense.accountId,
          initialType: expense.type,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteExpense(
    BuildContext context,
    WidgetRef ref,
    ExpenseModel expense,
  ) async {
    final label = expense.note.isEmpty ? expense.category : expense.note;
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete transaction?',
      message: 'Remove "$label" from your records? This cannot be undone.',
      confirmLabel: 'Delete txn',
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    await ref.read(expenseControllerProvider).deleteExpense(expense.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction removed.')));
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.groupedExpenses,
    required this.accounts,
    required this.privacyModeEnabled,
    required this.groupLabel,
    required this.accountLabelFor,
    required this.onEdit,
    required this.onDelete,
  });

  final SplayTreeMap<DateTime, List<ExpenseModel>> groupedExpenses;
  final List<AccountModel> accounts;
  final bool privacyModeEnabled;
  final String Function(DateTime) groupLabel;
  final String? Function(ExpenseModel, List<AccountModel>) accountLabelFor;
  final void Function(ExpenseModel) onEdit;
  final void Function(ExpenseModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: groupedExpenses.entries
          .map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      groupLabel(entry.key),
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ...entry.value.map((expense) {
                    return TransactionCard(
                      expense: expense,
                      accountLabel: accountLabelFor(expense, accounts),
                      maskAmounts: privacyModeEnabled,
                      onEdit: () => onEdit(expense),
                      onDelete: () => onDelete(expense),
                    );
                  }),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.accounts,
    required this.onAccountSelected,
    required this.allAccountsKey,
    required this.accountFilterLabel,
  });

  final List<AccountModel> accounts;
  final ValueChanged<String> onAccountSelected;
  final String allAccountsKey;
  final String accountFilterLabel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        color: Colors.white,
        onSelected: onAccountSelected,
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: allAccountsKey,
            child: const Text('All accounts'),
          ),
          ...accounts.map((account) {
            return PopupMenuItem<String>(
              value: account.id,
              child: Text(account.name),
            );
          }),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                accountFilterLabel,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.labelForFilter,
  });

  final RecordsFilter selectedFilter;
  final ValueChanged<RecordsFilter> onFilterSelected;
  final String Function(RecordsFilter) labelForFilter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: RecordsFilter.values
            .map((filter) {
              final isSelected = selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(labelForFilter(filter)),
                  selected: isSelected,
                  onSelected: (_) => onFilterSelected(filter),
                  selectedColor: AppColors.primaryBlue,
                  backgroundColor: AppColors.lightBlueBg,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF48607E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.filteredTotal,
    required this.transactionCount,
    required this.currency,
    required this.privacyModeEnabled,
  });

  final double filteredTotal;
  final int transactionCount;
  final NumberFormat currency;
  final bool privacyModeEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1209386D),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Filtered Net',
                  style: TextStyle(
                    color: Color(0xFF0A6BE8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatSignedAmount(
                      filteredTotal,
                      currency,
                      masked: privacyModeEnabled,
                    ),
                    style: TextStyle(
                      color: filteredTotal >= 0
                          ? const Color(0xFF1DAA63)
                          : const Color(0xFFFF446D),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: <Widget>[
                const Text(
                  'TXNS',
                  style: TextStyle(
                    color: Color(0xFF7A8BA8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$transactionCount',
                  style: const TextStyle(
                    color: Color(0xFF0A6BE8),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1209386D),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
