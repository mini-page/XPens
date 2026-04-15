import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/tag_parser.dart';
import '../../../../routes/app_routes.dart';
import '../../data/models/account_model.dart';
import '../../data/models/expense_model.dart';
import '../provider/account_providers.dart';
import '../provider/expense_providers.dart';
import '../provider/preferences_providers.dart';
import '../widgets/ui_feedback.dart';
import 'records_history/records_cards.dart';
import 'records_history/records_expense_list.dart';
import 'records_history/records_filter.dart';
import 'records_history/records_filter_bar.dart';

export 'records_history/records_filter.dart';

enum _SortOrder { newest, oldest, amountDesc, amountAsc }

class RecordsHistoryScreen extends ConsumerStatefulWidget {
  const RecordsHistoryScreen({super.key, this.initialTagFilter});

  final String? initialTagFilter;

  @override
  ConsumerState<RecordsHistoryScreen> createState() =>
      _RecordsHistoryScreenState();
}

class _RecordsHistoryScreenState extends ConsumerState<RecordsHistoryScreen> {
  static const String _allAccountsKey = '__all_accounts__';
  static const String _allCategoriesKey = '__all_categories__';

  RecordsFilter _selectedFilter = RecordsFilter.all;
  String _selectedAccountFilter = _allAccountsKey;
  String _selectedCategoryFilter = _allCategoriesKey;
  String _tagFilter = '';
  _SortOrder _sortOrder = _SortOrder.newest;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    if (widget.initialTagFilter != null) {
      _tagFilter = widget.initialTagFilter!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseListProvider);
    final accountState = ref.watch(accountListProvider);
    final privacyModeEnabled = ref.watch(privacyModeEnabledProvider);
    final expenses = expenseState.value ?? const <ExpenseModel>[];
    final accounts = accountState.value ?? const <AccountModel>[];
    final accountMap = {for (final a in accounts) a.id: a};
    final currency = ref.watch(currencyFormatProvider);
    final locale = ref.watch(localeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    // Collect unique categories for filter
    final allCategories = expenses
        .map((e) => e.category)
        .toSet()
        .toList(growable: false)
      ..sort();

    final filteredExpenses = _filterExpenses(expenses);
    final groupedExpenses = _groupExpenses(filteredExpenses);
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
        actions: [
          // Sort button
          PopupMenuButton<_SortOrder>(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textDark),
            tooltip: 'Sort',
            onSelected: (order) => setState(() => _sortOrder = order),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _SortOrder.newest,
                child: Text('Newest first'),
              ),
              PopupMenuItem(
                value: _SortOrder.oldest,
                child: Text('Oldest first'),
              ),
              PopupMenuItem(
                value: _SortOrder.amountDesc,
                child: Text('Amount ↓'),
              ),
              PopupMenuItem(
                value: _SortOrder.amountAsc,
                child: Text('Amount ↑'),
              ),
            ],
          ),
          // CSV export
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.textDark),
            tooltip: 'Export CSV',
            onPressed: () =>
                _exportCsv(context, filteredExpenses, locale, currencySymbol),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RecordsSummaryCard(
                filteredTotal: filteredTotal,
                transactionCount: filteredExpenses.length,
                currency: currency,
                privacyModeEnabled: privacyModeEnabled,
              ),
              const SizedBox(height: 18),
              // Date / type filter chips
              RecordsFilterChips(
                selectedFilter: _selectedFilter,
                onFilterSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                    if (filter != RecordsFilter.custom) {
                      _customDateRange = null;
                    }
                  });
                },
                labelForFilter: _labelForFilter,
                onCustomDateRange: () => _pickCustomDateRange(context),
                customDateRange: _customDateRange,
              ),
              const SizedBox(height: 10),
              // Account + Category + Tag row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    RecordsAccountDropdown(
                      accounts: accounts,
                      onAccountSelected: (value) {
                        setState(() => _selectedAccountFilter = value);
                      },
                      allAccountsKey: _allAccountsKey,
                      accountFilterLabel: _accountFilterLabel(accountMap),
                    ),
                    const SizedBox(width: 10),
                    // Category filter chip
                    _CategoryFilterChip(
                      categories: allCategories,
                      selectedCategory: _selectedCategoryFilter,
                      allCategoriesKey: _allCategoriesKey,
                      onChanged: (v) =>
                          setState(() => _selectedCategoryFilter = v),
                    ),
                    if (_tagFilter.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Chip(
                        label: Text('#$_tagFilter'),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _tagFilter = ''),
                        backgroundColor: AppColors.primaryBlue
                            .withValues(alpha: 0.1),
                        labelStyle: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: expenseState.hasError
                    ? const RecordsStateCard(
                        title: 'Unable to load records',
                        message:
                            'The transaction history is not available right now.',
                      )
                    : expenseState.isLoading && expenses.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : filteredExpenses.isEmpty
                            ? const RecordsStateCard(
                                title: 'No matching transactions',
                                message:
                                    'Try another filter or add a new expense.',
                              )
                            : RecordsExpenseList(
                                groupedExpenses: groupedExpenses,
                                accounts: accounts,
                                privacyModeEnabled: privacyModeEnabled,
                                groupLabel: _groupLabel,
                                accountLabelFor: _accountLabelFor,
                                onEdit: (expense) =>
                                    _openEditExpenseScreen(context, expense),
                                onDelete: (expense) => _confirmDeleteExpense(
                                    context, ref, expense),
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

    final filtered = expenses.where((expense) {
      final localDate = expense.date.toLocal();
      final dateOnly = DateUtils.dateOnly(localDate);

      final matchesAccount = _selectedAccountFilter == _allAccountsKey ||
          expense.accountId == _selectedAccountFilter;
      if (!matchesAccount) return false;

      final matchesCategory = _selectedCategoryFilter == _allCategoriesKey ||
          expense.category == _selectedCategoryFilter;
      if (!matchesCategory) return false;

      if (_tagFilter.isNotEmpty) {
        final tags = TagParser.extractTags(expense.note);
        if (!tags.contains(_tagFilter.toLowerCase())) return false;
      }

      switch (_selectedFilter) {
        case RecordsFilter.today:
          return DateUtils.isSameDay(dateOnly, today);
        case RecordsFilter.week:
          return !dateOnly.isBefore(weekStart) && !dateOnly.isAfter(today);
        case RecordsFilter.month:
          return dateOnly.year == today.year && dateOnly.month == today.month;
        case RecordsFilter.future:
          return dateOnly.isAfter(today);
        case RecordsFilter.custom:
          if (_customDateRange == null) return true;
          return !dateOnly.isBefore(_customDateRange!.start) &&
              !dateOnly.isAfter(_customDateRange!.end);
        case RecordsFilter.all:
          return true;
      }
    }).toList(growable: false);

    switch (_sortOrder) {
      case _SortOrder.newest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortOrder.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SortOrder.amountDesc:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case _SortOrder.amountAsc:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return filtered;
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
      case RecordsFilter.custom:
        if (_customDateRange != null) {
          final fmt = DateFormat('d MMM');
          return '${fmt.format(_customDateRange!.start)}–${fmt.format(_customDateRange!.end)}';
        }
        return 'Custom';
      case RecordsFilter.all:
        return 'All';
    }
  }

  String _accountFilterLabel(Map<String, AccountModel> accountMap) {
    if (_selectedAccountFilter == _allAccountsKey) {
      return 'All accounts';
    }
    return accountMap[_selectedAccountFilter]?.name ?? 'Archived account';
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
    for (final a in accounts) {
      if (a.id == expense.accountId) {
        return a.name;
      }
    }
    return 'Archived Account';
  }

  Future<void> _openEditExpenseScreen(
    BuildContext context,
    ExpenseModel expense,
  ) {
    return AppRoutes.pushEditExpense(
      context,
      expenseId: expense.id,
      initialAmount: expense.amount,
      initialCategory: expense.category,
      initialDate: expense.date.toLocal(),
      initialNote: expense.note,
      initialAccountId: expense.accountId,
      initialToAccountId: expense.toAccountId,
      initialType: expense.type,
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

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _customDateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        _customDateRange = range;
        _selectedFilter = RecordsFilter.custom;
      });
    }
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<ExpenseModel> expenses,
    String locale,
    String currencySymbol,
  ) async {
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export.')),
      );
      return;
    }

    final dateFmt = DateFormat('yyyy-MM-dd HH:mm', locale);
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Note,Amount,Tags');

    for (final e in expenses) {
      final date = dateFmt.format(e.date.toLocal());
      final type = e.type.name;
      final category = _csvEscape(e.category);
      final note = _csvEscape(TagParser.stripTags(e.note));
      final amount =
          e.isIncome ? e.amount.toStringAsFixed(2) : (-e.amount).toStringAsFixed(2);
      final tags = TagParser.extractTags(e.note).map((t) => '#$t').join(' ');
      buffer.writeln('$date,$type,$category,$note,$amount,$tags');
    }

    await Share.share(
      buffer.toString(),
      subject: 'XPensa Transactions Export',
    );
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

/// Category filter chip/dropdown for records screen.
class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.categories,
    required this.selectedCategory,
    required this.allCategoriesKey,
    required this.onChanged,
  });

  final List<String> categories;
  final String selectedCategory;
  final String allCategoriesKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedCategory != allCategoriesKey;
    return PopupMenuButton<String>(
      color: Colors.white,
      onSelected: onChanged,
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: allCategoriesKey,
          child: const Text('All categories'),
        ),
        ...categories.map(
          (cat) => PopupMenuItem(value: cat, child: Text(cat)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isFiltered
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
          border: isFiltered
              ? Border.all(color: AppColors.primaryBlue, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.category_outlined,
              size: 18,
              color:
                  isFiltered ? AppColors.primaryBlue : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              isFiltered ? selectedCategory : 'Category',
              style: TextStyle(
                color: isFiltered ? AppColors.primaryBlue : AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isFiltered ? AppColors.primaryBlue : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}


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
    final accountMap = {for (final a in accounts) a.id: a};
    final filteredExpenses = _filterExpenses(expenses);
    final groupedExpenses = _groupExpenses(filteredExpenses);

    final currency = ref.watch(currencyFormatProvider);
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
              RecordsSummaryCard(
                filteredTotal: filteredTotal,
                transactionCount: filteredExpenses.length,
                currency: currency,
                privacyModeEnabled: privacyModeEnabled,
              ),
              const SizedBox(height: 18),
              RecordsFilterChips(
                selectedFilter: _selectedFilter,
                onFilterSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                labelForFilter: _labelForFilter,
              ),
              const SizedBox(height: 14),
              RecordsAccountDropdown(
                accounts: accounts,
                onAccountSelected: (value) {
                  setState(() {
                    _selectedAccountFilter = value;
                  });
                },
                allAccountsKey: _allAccountsKey,
                accountFilterLabel: _accountFilterLabel(accountMap),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: expenseState.hasError
                    ? const RecordsStateCard(
                        title: 'Unable to load records',
                        message:
                            'The transaction history is not available right now.',
                      )
                    : expenseState.isLoading && expenses.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : filteredExpenses.isEmpty
                            ? const RecordsStateCard(
                                title: 'No matching transactions',
                                message:
                                    'Try another filter or add a new expense.',
                              )
                            : RecordsExpenseList(
                                groupedExpenses: groupedExpenses,
                                accounts: accounts,
                                privacyModeEnabled: privacyModeEnabled,
                                groupLabel: _groupLabel,
                                accountLabelFor: _accountLabelFor,
                                onEdit: (expense) =>
                                    _openEditExpenseScreen(context, expense),
                                onDelete: (expense) => _confirmDeleteExpense(
                                    context, ref, expense),
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

    return expenses.where((expense) {
      final localDate = expense.date.toLocal();
      final dateOnly = DateUtils.dateOnly(localDate);
      final matchesAccount = _selectedAccountFilter == _allAccountsKey ||
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
          return dateOnly.year == today.year && dateOnly.month == today.month;
        case RecordsFilter.future:
          return dateOnly.isAfter(today);
        case RecordsFilter.all:
          return true;
      }
    }).toList(growable: false)
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

  String _accountFilterLabel(Map<String, AccountModel> accountMap) {
    if (_selectedAccountFilter == _allAccountsKey) {
      return 'All accounts';
    }
    return accountMap[_selectedAccountFilter]?.name ?? 'Archived account';
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
    for (final a in accounts) {
      if (a.id == expense.accountId) {
        return a.name;
      }
    }
    return 'Archived Account';
  }

  Future<void> _openEditExpenseScreen(
    BuildContext context,
    ExpenseModel expense,
  ) {
    return AppRoutes.pushEditExpense(
      context,
      expenseId: expense.id,
      initialAmount: expense.amount,
      initialCategory: expense.category,
      initialDate: expense.date.toLocal(),
      initialNote: expense.note,
      initialAccountId: expense.accountId,
      initialToAccountId: expense.toAccountId,
      initialType: expense.type,
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
