import 'package:flutter_test/flutter_test.dart';
import 'package:xpensa/features/expense/data/models/expense_model.dart';

void main() {
  group('ExpenseModel Validations', () {
    final DateTime testDate = DateTime.now();

    test('should construct successfully with valid arguments', () {
      final expense = ExpenseModel(
        id: '123',
        amount: 10.0,
        category: 'Food',
        date: testDate,
        note: 'Lunch',
      );

      expect(expense.id, '123');
      expect(expense.amount, 10.0);
      expect(expense.category, 'Food');
      expect(expense.date, testDate.toUtc());
      expect(expense.note, 'Lunch');
      expect(expense.type, TransactionType.expense); // Default
    });

    test('should throw ArgumentError when id is empty', () {
      expect(
        () => ExpenseModel(
          id: '',
          amount: 10.0,
          category: 'Food',
          date: testDate,
          note: 'Lunch',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Expense id cannot be empty.',
          ),
        ),
      );
    });

    test('should throw ArgumentError when amount is zero', () {
      expect(
        () => ExpenseModel(
          id: '123',
          amount: 0.0,
          category: 'Food',
          date: testDate,
          note: 'Lunch',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Expense amount must be positive.',
          ),
        ),
      );
    });

    test('should throw ArgumentError when amount is negative', () {
      expect(
        () => ExpenseModel(
          id: '123',
          amount: -10.0,
          category: 'Food',
          date: testDate,
          note: 'Lunch',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Expense amount must be positive.',
          ),
        ),
      );
    });

    test('should throw ArgumentError when category is empty', () {
      expect(
        () => ExpenseModel(
          id: '123',
          amount: 10.0,
          category: '',
          date: testDate,
          note: 'Lunch',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Expense category cannot be empty.',
          ),
        ),
      );
    });

    test('should throw ArgumentError when category contains only whitespace', () {
      expect(
        () => ExpenseModel(
          id: '123',
          amount: 10.0,
          category: '   ',
          date: testDate,
          note: 'Lunch',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Expense category cannot be empty.',
          ),
        ),
      );
    });
  });

  group('ExpenseModel Factory & Methods', () {
    final DateTime testDate = DateTime.now();

    test('factory create generates an id and correctly populates fields', () {
      final expense = ExpenseModel.create(
        amount: 50.0,
        category: '  Transport  ', // Should be trimmed
        date: testDate,
        note: '  Taxi  ', // Should be trimmed
        accountId: '  acc123  ', // Should be trimmed
      );

      expect(expense.id.isNotEmpty, true); // UUID generated
      expect(expense.amount, 50.0);
      expect(expense.category, 'Transport'); // Trimmed
      expect(expense.date, testDate.toUtc());
      expect(expense.note, 'Taxi'); // Trimmed
      expect(expense.accountId, 'acc123'); // Trimmed
    });

    test('factory create handles empty accountId correctly', () {
      final expense = ExpenseModel.create(
        amount: 50.0,
        category: 'Transport',
        date: testDate,
        accountId: '   ', // Blank string should map to null
      );

      expect(expense.accountId, isNull);
    });

    test('getters isIncome and signedAmount return correct values for expense', () {
      final expense = ExpenseModel.create(
        amount: 100.0,
        category: 'Food',
        date: testDate,
        type: TransactionType.expense,
      );

      expect(expense.isIncome, false);
      expect(expense.signedAmount, -100.0);
    });

    test('getters isIncome and signedAmount return correct values for income', () {
      final income = ExpenseModel.create(
        amount: 1000.0,
        category: 'Salary',
        date: testDate,
        type: TransactionType.income,
      );

      expect(income.isIncome, true);
      expect(income.signedAmount, 1000.0);
    });

    test('copyWith correctly updates properties', () {
      final original = ExpenseModel.create(
        amount: 10.0,
        category: 'Food',
        date: testDate,
        accountId: 'acc1',
      );

      final newDate = testDate.add(const Duration(days: 1));

      final updated = original.copyWith(
        amount: 20.0,
        category: 'Dining',
        date: newDate,
        note: 'Dinner',
        accountId: 'acc2',
        type: TransactionType.income,
      );

      expect(updated.id, original.id); // Stays the same
      expect(updated.amount, 20.0);
      expect(updated.category, 'Dining');
      expect(updated.date, newDate.toUtc());
      expect(updated.note, 'Dinner');
      expect(updated.accountId, 'acc2');
      expect(updated.type, TransactionType.income);
    });

    test('copyWith clearAccountId correctly nullifies accountId', () {
      final original = ExpenseModel.create(
        amount: 10.0,
        category: 'Food',
        date: testDate,
        accountId: 'acc1',
      );

      final cleared = original.copyWith(clearAccountId: true);

      expect(cleared.accountId, isNull);
    });
  });
}
