import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Holds the pre-computed payload that is written to Android SharedPreferences
/// whenever accounts, transactions, or currency settings change.
///
/// Used with [ref.listen] in [AppShell] to trigger [WidgetSyncService.syncData].
class WidgetDataPayload {
  const WidgetDataPayload({
    required this.totalBalance,
    required this.currencySymbol,
    required this.transactions,
  });

  final double totalBalance;
  final String currencySymbol;
  final List<Map<String, dynamic>> transactions;
}

// ── MethodChannel bridge ───────────────────────────────────────────────────

/// Service that communicates with the native Android widget layer via a
/// [MethodChannel].  All calls are best-effort: failures are silently
/// swallowed so a widget-sync error never crashes the app.
class WidgetSyncService {
  static const MethodChannel _channel =
      MethodChannel('app.xpensa.finance/widget');

  // ── Outbound (Flutter → Android) ──────────────────────────────────

  /// Write the latest balance, transactions, and currency symbol to the
  /// Android SharedPreferences that the widget providers read from, then
  /// trigger a widget refresh.
  static Future<void> syncData(WidgetDataPayload payload) async {
    try {
      await _channel.invokeMethod<void>('syncWidgetData', {
        'totalBalance': payload.totalBalance,
        'currencySymbol': payload.currencySymbol,
        'transactions': jsonEncode(payload.transactions),
        'lastSynced': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e, st) {
      // Widget sync is best-effort; never let a failure crash the app.
      assert(() {
        dev.log('WidgetSyncService.syncData failed: $e', stackTrace: st);
        return true;
      }());
    }
  }

  // ── Inbound (Android → Flutter via polling) ────────────────────────

  /// Returns the widget action string set by the last widget button tap
  /// (e.g. `"add_expense"`, `"voice"`, `"scanner"`), or `null` if none.
  ///
  /// Consuming the value clears it on the Android side.
  static Future<String?> getPendingAction() async {
    try {
      return await _channel.invokeMethod<String>('getPendingAction');
    } catch (e, st) {
      assert(() {
        dev.log('WidgetSyncService.getPendingAction failed: $e', stackTrace: st);
        return true;
      }());
      return null;
    }
  }

  // ── Voice input ────────────────────────────────────────────────────

  /// Launches the Android system speech recogniser and returns the first
  /// recognised string, or `null` if cancelled / unavailable.
  static Future<String?> startVoiceInput() async {
    try {
      return await _channel.invokeMethod<String>('startVoiceInput');
    } catch (e, st) {
      assert(() {
        dev.log('WidgetSyncService.startVoiceInput failed: $e', stackTrace: st);
        return true;
      }());
      return null;
    }
  }
}
