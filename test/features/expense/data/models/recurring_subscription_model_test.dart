import 'package:flutter_test/flutter_test.dart';
import 'package:xpensa/features/expense/data/models/recurring_subscription_model.dart';

void main() {
  group('RecurringSubscriptionModel', () {
    final nextBillDate = DateTime(2023, 10, 10);
    const iconKey = 'netflix';
    const amount = 15.99;
    const name = 'Netflix';

    test('should create a valid RecurringSubscriptionModel', () {
      final model = RecurringSubscriptionModel(
        id: 'uuid-1',
        name: name,
        amount: amount,
        nextBillDate: nextBillDate,
        iconKey: iconKey,
      );

      expect(model.id, 'uuid-1');
      expect(model.name, name);
      expect(model.amount, amount);
      expect(model.nextBillDate, nextBillDate);
      expect(model.iconKey, iconKey);
    });

    test('should throw ArgumentError when id is empty', () {
      expect(
        () => RecurringSubscriptionModel(
          id: '',
          name: name,
          amount: amount,
          nextBillDate: nextBillDate,
          iconKey: iconKey,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Subscription id cannot be empty.',
        )),
      );
    });

    test('should throw ArgumentError when name is empty', () {
      expect(
        () => RecurringSubscriptionModel(
          id: 'uuid-1',
          name: '',
          amount: amount,
          nextBillDate: nextBillDate,
          iconKey: iconKey,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Subscription name cannot be empty.',
        )),
      );
    });

    test('should throw ArgumentError when name is only whitespace', () {
      expect(
        () => RecurringSubscriptionModel(
          id: 'uuid-1',
          name: '   ',
          amount: amount,
          nextBillDate: nextBillDate,
          iconKey: iconKey,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Subscription name cannot be empty.',
        )),
      );
    });

    test('should throw ArgumentError when amount is zero', () {
      expect(
        () => RecurringSubscriptionModel(
          id: 'uuid-1',
          name: name,
          amount: 0.0,
          nextBillDate: nextBillDate,
          iconKey: iconKey,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Subscription amount must be positive.',
        )),
      );
    });

    test('should throw ArgumentError when amount is negative', () {
      expect(
        () => RecurringSubscriptionModel(
          id: 'uuid-1',
          name: name,
          amount: -1.0,
          nextBillDate: nextBillDate,
          iconKey: iconKey,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Subscription amount must be positive.',
        )),
      );
    });

    test('factory RecurringSubscriptionModel.create should generate a valid model', () {
      final model = RecurringSubscriptionModel.create(
        name: name,
        amount: amount,
        nextBillDate: nextBillDate,
        iconKey: iconKey,
      );

      expect(model.id, isNotEmpty);
      expect(model.name, name);
      expect(model.amount, amount);
      expect(model.nextBillDate, nextBillDate);
      expect(model.iconKey, iconKey);
    });

    test('copyWith should return a new object with updated fields', () {
      final model = RecurringSubscriptionModel(
        id: 'uuid-1',
        name: name,
        amount: amount,
        nextBillDate: nextBillDate,
        iconKey: iconKey,
      );

      final updatedModel = model.copyWith(name: 'Disney+');

      expect(updatedModel.id, 'uuid-1');
      expect(updatedModel.name, 'Disney+');
      expect(updatedModel.amount, amount);
      expect(updatedModel.nextBillDate, nextBillDate);
      expect(updatedModel.iconKey, iconKey);
    });
  });
}
