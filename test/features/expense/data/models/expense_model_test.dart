import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:xpensa/features/expense/data/models/expense_model.dart';

void main() {
  group('ExpenseModel', () {
    final validId = const Uuid().v4();
    final validAmount = 100.0;
    final validCategory = 'Food';
    final validDate = DateTime.now();

    test('should create a valid ExpenseModel', () {
      final expense = ExpenseModel(
        id: validId,
        amount: validAmount,
        category: validCategory,
        date: validDate,
        note: 'Lunch',
      );

      expect(expense.id, validId);
      expect(expense.amount, validAmount);
      expect(expense.category, validCategory);
      expect(expense.date, validDate.toUtc());
      expect(expense.note, 'Lunch');
      expect(expense.type, TransactionType.expense);
    });

    test('should throw ArgumentError when category is empty', () {
      expect(
        () => ExpenseModel(
          id: validId,
          amount: validAmount,
          category: '',
          date: validDate,
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

    test('should throw ArgumentError when category is whitespace', () {
      expect(
        () => ExpenseModel(
          id: validId,
          amount: validAmount,
          category: '   ',
          date: validDate,
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

    test('should throw ArgumentError when id is empty', () {
      expect(
        () => ExpenseModel(
          id: '',
          amount: validAmount,
          category: validCategory,
          date: validDate,
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
          id: validId,
          amount: 0.0,
          category: validCategory,
          date: validDate,
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
          id: validId,
          amount: -50.0,
          category: validCategory,
          date: validDate,
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

    group('factory create()', () {
      test('should trim category and note on create', () {
        final expense = ExpenseModel.create(
          amount: validAmount,
          category: '  Food  ',
          date: validDate,
          note: '  Lunch  ',
        );

        expect(expense.category, 'Food');
        expect(expense.note, 'Lunch');
      });
    });
  });
}
