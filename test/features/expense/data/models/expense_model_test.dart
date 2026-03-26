import 'package:flutter_test/flutter_test.dart';
import 'package:xpensa/features/expense/data/models/expense_model.dart';

void main() {
  group('ExpenseModel', () {
    final validDate = DateTime(2023, 10, 15);

    test('can be instantiated with valid values', () {
      final expense = ExpenseModel(
        id: '123e4567-e89b-12d3-a456-426614174000',
        amount: 100.50,
        category: 'Food',
        date: validDate,
        note: 'Lunch',
      );

      expect(expense.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(expense.amount, 100.50);
      expect(expense.category, 'Food');
      expect(expense.date, validDate.toUtc());
      expect(expense.note, 'Lunch');
      expect(expense.type, TransactionType.expense);
    });

    test('throws ArgumentError if id is empty', () {
      expect(
        () => ExpenseModel(
          id: '',
          amount: 10.0,
          category: 'Food',
          date: validDate,
          note: '',
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

    group('amount validation', () {
      test('throws ArgumentError if amount is zero', () {
        expect(
          () => ExpenseModel(
            id: 'valid-id',
            amount: 0.0,
            category: 'Food',
            date: validDate,
            note: '',
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

      test('throws ArgumentError if amount is negative', () {
        expect(
          () => ExpenseModel(
            id: 'valid-id',
            amount: -50.0,
            category: 'Food',
            date: validDate,
            note: '',
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
    });

    group('category validation', () {
      test('throws ArgumentError if category is empty', () {
        expect(
          () => ExpenseModel(
            id: 'valid-id',
            amount: 10.0,
            category: '',
            date: validDate,
            note: '',
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

      test('throws ArgumentError if category is only whitespace', () {
        expect(
          () => ExpenseModel(
            id: 'valid-id',
            amount: 10.0,
            category: '   ',
            date: validDate,
            note: '',
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

    test('ExpenseModel.create factory generates valid model', () {
      final expense = ExpenseModel.create(
        amount: 25.0,
        category: ' Transport ',
        date: validDate,
        note: ' Bus ',
      );

      expect(expense.id, isNotEmpty);
      expect(expense.amount, 25.0);
      expect(expense.category, 'Transport'); // Should be trimmed
      expect(expense.note, 'Bus'); // Should be trimmed
      expect(expense.date, validDate.toUtc());
      expect(expense.type, TransactionType.expense);
    });
  });
}
