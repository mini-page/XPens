import 'package:flutter_test/flutter_test.dart';
import 'package:xpensa/features/expense/data/models/account_model.dart';

void main() {
  group('AccountModel', () {
    test('throws ArgumentError when id is empty', () {
      expect(
        () => AccountModel(
          id: '',
          name: 'Main Account',
          iconKey: 'wallet',
          balance: 100.0,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Account id cannot be empty.',
          ),
        ),
      );
    });

    test('throws ArgumentError when name is empty', () {
      expect(
        () => AccountModel(
          id: 'account-1',
          name: '',
          iconKey: 'wallet',
          balance: 100.0,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Account name cannot be empty.',
          ),
        ),
      );
    });

    test('throws ArgumentError when name contains only whitespace', () {
      expect(
        () => AccountModel(
          id: 'account-1',
          name: '   ',
          iconKey: 'wallet',
          balance: 100.0,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Account name cannot be empty.',
          ),
        ),
      );
    });

    test('creates successfully with valid parameters', () {
      final account = AccountModel(
        id: 'account-1',
        name: 'Main Account',
        iconKey: 'wallet',
        balance: 100.0,
      );

      expect(account.id, 'account-1');
      expect(account.name, 'Main Account');
      expect(account.iconKey, 'wallet');
      expect(account.balance, 100.0);
    });

    group('create factory', () {
      test('generates valid v4 UUID and trims name', () {
        final account = AccountModel.create(
          name: '  Savings Account  ',
          iconKey: 'bank',
          balance: 500.0,
        );

        expect(account.id, isNotEmpty);
        // Validates a UUID v4 string
        expect(
            RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
                .hasMatch(account.id),
            isTrue);
        expect(account.name, 'Savings Account'); // Should be trimmed
        expect(account.iconKey, 'bank');
        expect(account.balance, 500.0);
      });
    });

    group('copyWith', () {
      final baseAccount = AccountModel(
        id: 'base-id',
        name: 'Base Account',
        iconKey: 'wallet',
        balance: 0.0,
      );

      test('updates specified fields', () {
        final updatedAccount = baseAccount.copyWith(
          name: 'Updated Account',
          balance: 150.0,
        );

        expect(updatedAccount.id, 'base-id'); // Unchanged
        expect(updatedAccount.iconKey, 'wallet'); // Unchanged
        expect(updatedAccount.name, 'Updated Account'); // Changed
        expect(updatedAccount.balance, 150.0); // Changed
      });

      test('throws ArgumentError if updated name is empty', () {
        expect(
          () => baseAccount.copyWith(name: '  '),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
