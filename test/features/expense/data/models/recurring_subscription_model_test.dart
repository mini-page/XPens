import 'package:flutter_test/flutter_test.dart';
import 'package:xpensa/features/expense/data/models/recurring_subscription_model.dart';

void main() {
  group('RecurringSubscriptionModel validation', () {
    test('should throw ArgumentError when name is empty', () {
      expect(
        () => RecurringSubscriptionModel(
          id: 'test-id',
          name: '',
          amount: 10.0,
          nextBillDate: DateTime(2023, 1, 1),
          iconKey: 'icon',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Subscription name cannot be empty.',
          ),
        ),
      );
    });

    test('should throw ArgumentError when name contains only whitespace', () {
      expect(
        () => RecurringSubscriptionModel(
          id: 'test-id',
          name: '   ',
          amount: 10.0,
          nextBillDate: DateTime(2023, 1, 1),
          iconKey: 'icon',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Subscription name cannot be empty.',
          ),
        ),
      );
    });

    test('should create model when name is valid', () {
      final model = RecurringSubscriptionModel(
        id: 'test-id',
        name: 'Valid Name',
        amount: 10.0,
        nextBillDate: DateTime(2023, 1, 1),
        iconKey: 'icon',
      );

      expect(model.name, 'Valid Name');
    });

    test('should throw ArgumentError when id is empty', () {
      expect(
        () => RecurringSubscriptionModel(
          id: '',
          name: 'Valid Name',
          amount: 10.0,
          nextBillDate: DateTime(2023, 1, 1),
          iconKey: 'icon',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Subscription id cannot be empty.',
          ),
        ),
      );
    });

    test('should throw ArgumentError when amount is zero or negative', () {
      expect(
        () => RecurringSubscriptionModel(
          id: 'test-id',
          name: 'Valid Name',
          amount: 0.0,
          nextBillDate: DateTime(2023, 1, 1),
          iconKey: 'icon',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Subscription amount must be positive.',
          ),
        ),
      );

      expect(
        () => RecurringSubscriptionModel(
          id: 'test-id',
          name: 'Valid Name',
          amount: -10.0,
          nextBillDate: DateTime(2023, 1, 1),
          iconKey: 'icon',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Subscription amount must be positive.',
          ),
        ),
      );
    });
  });

  group('RecurringSubscriptionModel.create validation', () {
    test('should create model when name is valid, trims whitespace', () {
      final model = RecurringSubscriptionModel.create(
        name: '  Valid Name  ',
        amount: 10.0,
        nextBillDate: DateTime(2023, 1, 1),
        iconKey: 'icon',
      );

      expect(model.name, 'Valid Name');
      expect(model.id, isNotEmpty);
    });

    test('should throw ArgumentError when name is empty', () {
      expect(
        () => RecurringSubscriptionModel.create(
          name: '',
          amount: 10.0,
          nextBillDate: DateTime(2023, 1, 1),
          iconKey: 'icon',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Subscription name cannot be empty.',
          ),
        ),
      );
    });
  });
}
