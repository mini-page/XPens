import 'package:flutter/material.dart';

import '../../../../core/services/widget_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../../data/models/expense_model.dart';

// ── Public entry point ─────────────────────────────────────────────────────

/// Shows the [VoiceEntryScreen] as a modal bottom-sheet.
///
/// Callers should `await` this; when the sheet closes after a successful
/// voice command the user is already navigating to [AddExpenseScreen].
Future<void> showVoiceEntrySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const VoiceEntryScreen(),
  );
}

// ── Screen ─────────────────────────────────────────────────────────────────

/// A bottom-sheet that:
/// 1. Lets the user tap 🎤 to start Android speech recognition.
/// 2. Displays the recognised text.
/// 3. Parses it into a [_ParsedCommand] (amount / type / category).
/// 4. Navigates to [AddExpenseScreen] with pre-filled data on confirm.
class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen> {
  _VoiceState _state = _VoiceState.idle;
  String? _recognisedText;
  _ParsedCommand? _parsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE4F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title row
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Voice Entry',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Speak to log a transaction',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── State-driven body ──────────────────────────────────────
          if (_state == _VoiceState.idle) _buildIdleBody(),
          if (_state == _VoiceState.listening) _buildListeningBody(),
          if (_state == _VoiceState.result) _buildResultBody(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Idle (tap mic) ─────────────────────────────────────────────────

  Widget _buildIdleBody() {
    return Column(
      children: <Widget>[
        const Text(
          'Tap the microphone and say something like:\n'
          '  • "Add 250 food expense"\n'
          '  • "Add salary 25000 income"\n'
          '  • "Transfer 5000 from cash"',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.7,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 28),
        _MicButton(onTap: _startListening),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Listening (spinner) ────────────────────────────────────────────

  Widget _buildListeningBody() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: <Widget>[
          CircularProgressIndicator(color: AppColors.primaryBlue),
          SizedBox(height: 16),
          Text(
            'Listening…',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Result (preview + confirm) ─────────────────────────────────────

  Widget _buildResultBody() {
    final cmd = _parsed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Recognised text chip
        if (_recognisedText != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.record_voice_over_rounded,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"$_recognisedText"',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Parsed preview
        if (cmd != null) ...<Widget>[
          _ParsedPreview(command: cmd),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _confirmCommand,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Continue to Add Transaction',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ] else ...<Widget>[
          const Text(
            "Couldn't understand that. Please try again.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _state = _VoiceState.idle;
            _recognisedText = null;
            _parsed = null;
          }),
          child: const Text('Try again'),
        ),
      ],
    );
  }

  // ── Logic ──────────────────────────────────────────────────────────

  Future<void> _startListening() async {
    setState(() => _state = _VoiceState.listening);

    final text = await WidgetSyncService.startVoiceInput();

    if (!mounted) return;

    if (text == null || text.trim().isEmpty) {
      setState(() => _state = _VoiceState.idle);
      return;
    }

    final parsed = _VoiceCommandParser.parse(text);
    setState(() {
      _state = _VoiceState.result;
      _recognisedText = text;
      _parsed = parsed;
    });
  }

  void _confirmCommand() {
    final cmd = _parsed;
    if (cmd == null || !mounted) return;

    Navigator.of(context).pop();

    AppRoutes.pushAddExpense(
      context,
      initialAmount: cmd.amount,
      initialType: cmd.type,
      initialCategory: cmd.category,
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  const _MicButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _ParsedPreview extends StatelessWidget {
  const _ParsedPreview({required this.command});

  final _ParsedCommand command;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (command.type) {
      TransactionType.income => 'Income',
      TransactionType.transfer => 'Transfer',
      _ => 'Expense',
    };
    final typeColor = switch (command.type) {
      TransactionType.income => AppColors.success,
      TransactionType.transfer => AppColors.primaryBlue,
      _ => AppColors.danger,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE4F0)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              command.category,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            command.amount.toStringAsFixed(0),
            style: TextStyle(
              color: typeColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── State enum ─────────────────────────────────────────────────────────────

enum _VoiceState { idle, listening, result }

// ── Voice command parser ───────────────────────────────────────────────────

class _ParsedCommand {
  const _ParsedCommand({
    required this.amount,
    required this.type,
    required this.category,
  });

  final double amount;
  final TransactionType type;
  final String category;
}

/// Heuristic NLP parser that extracts transaction data from free-form voice
/// input strings.  It is intentionally permissive and prioritises recall over
/// precision.
abstract final class _VoiceCommandParser {
  static _ParsedCommand? parse(String rawText) {
    final text = rawText.toLowerCase().trim();

    // ── 1. Extract amount ────────────────────────────────────────────
    final amountRegex = RegExp(r'(\d+(?:[.,]\d{1,2})?)');
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll(',', '.');
    final amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) return null;

    // ── 2. Determine transaction type ────────────────────────────────
    final type = _detectType(text);

    // ── 3. Determine category ────────────────────────────────────────
    final category = _detectCategory(text, type);

    // ── 4. Note is always left empty here so the user can add it in AddExpenseScreen
    return _ParsedCommand(amount: amount, type: type, category: category);
  }

  static TransactionType _detectType(String text) {
    if (text.contains('transfer') ||
        text.contains('sent to') ||
        text.contains('move') ||
        text.contains('moved')) {
      return TransactionType.transfer;
    }
    if (text.contains('income') ||
        text.contains('salary') ||
        text.contains('sal ') ||
        text.contains('earning') ||
        text.contains('received') ||
        text.contains('got ') ||
        text.contains('award') ||
        text.contains('refund') ||
        text.contains('freelance') ||
        text.contains('business income') ||
        text.contains('grant') ||
        text.contains('coupon')) {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }

  static String _detectCategory(String text, TransactionType type) {
    if (type == TransactionType.income) {
      if (_any(text, ['salary', 'sal ', 'paycheck', 'pay slip'])) return 'Salary';
      if (_any(text, ['freelance', 'freelancing', 'gig'])) return 'Salary'; // maps to Salary bucket
      if (_any(text, ['award', 'prize', 'bonus'])) return 'Award';
      if (_any(text, ['refund', 'cashback', 'reimburs'])) return 'Refund';
      if (_any(text, ['coupon', 'voucher', 'discount'])) return 'Coupon';
      if (_any(text, ['grant', 'scholarship'])) return 'Grant';
      if (_any(text, ['lottery', 'lucky', 'jackpot'])) return 'Lottery';
      return 'Salary'; // default income category
    }

    if (type == TransactionType.transfer) {
      return 'Transfer'; // not a real category but used as placeholder
    }

    // Expense categories
    if (_any(text, ['food', 'eat', 'lunch', 'dinner', 'breakfast', 'restaurant', 'cafe', 'snack', 'meal', 'grocery', 'groceries', 'vegetable', 'fruit'])) {
      return 'Food & Dining';
    }
    if (_any(text, ['transport', 'bus', 'train', 'metro', 'taxi', 'cab', 'auto', 'uber', 'ola', 'petrol', 'fuel', 'commute', 'travel fare'])) {
      return 'Transportation';
    }
    if (_any(text, ['shop', 'shopping', 'cloth', 'dress', 'buy', 'purchase', 'amazon', 'flipkart', 'myntra', 'market'])) {
      return 'Shopping';
    }
    if (_any(text, ['bill', 'electricity', 'water', 'gas', 'internet', 'recharge', 'mobile', 'subscription', 'wifi', 'broadband', 'phone', 'utility'])) {
      return 'Other'; // no dedicated Bills category; use Other
    }
    if (_any(text, ['doctor', 'hospital', 'medicine', 'medical', 'health', 'pharma', 'clinic', 'surgery', 'lab'])) {
      return 'Other'; // no Medical category yet; use Other
    }
    if (_any(text, ['beauty', 'salon', 'spa', 'haircut', 'makeup', 'skincare', 'grooming'])) {
      return 'Beauty & Care';
    }
    if (_any(text, ['travel', 'flight', 'hotel', 'trip', 'holiday', 'vacation', 'tour', 'ticket'])) {
      return 'Travel';
    }
    if (_any(text, ['social', 'friend', 'party', 'event', 'outing', 'movie', 'game', 'entertainment', 'netflix', 'music', 'theatre', 'concert'])) {
      return 'Social';
    }

    return 'Other';
  }

  static bool _any(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}
