# Phase UI — UI Review

**Audited:** 2026-03-26
**Baseline:** Abstract 6-pillar standards
**Screenshots:** Captured (Port 8080)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Clear, action-oriented labels and helpful empty/error states across all tools. |
| 2. Visuals | 4/4 | Strong focal points and proactive use of FittedBox to prevent overflows. |
| 3. Color | 3/4 | Consistent semantic palette but relies on repeated hex literals instead of theme constants. |
| 4. Typography | 4/4 | Modern, bold hierarchy that aligns well with fintech/expense tracking expectations. |
| 5. Spacing | 4/4 | Consistent spacing and padding values provide a balanced, breathable layout. |
| 6. Experience Design | 3/4 | Excellent state coverage, though minor interaction frictions exist in input fields. |

**Overall: 22/24**

---

## Top 3 Priority Fixes

1. **Hardcoded Color Literals** — `Color(0xFF0A6BE8)` and other hex codes are duplicated across multiple files (Home, Stats, Accounts). — This makes theming harder. — Centralize these into a `ThemeData` extension or a shared `AppColors` class.
2. **Input Friction in Split Bill** — `_amountController` is initialized with `'0'`, forcing users to delete it before entering a value. — Adds extra taps to a core tool flow. — Use an empty string for the initial value and provide a hint text instead.
3. **List Performance** — `AccountsScreen` uses `shrinkWrap: true` on its account list inside a `SingleChildScrollView`. — Can cause performance degradation if the list grows large. — Use `SliverList` or a dedicated scrollable section to avoid layout-time list expansion.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)
- Clear empty state messages in `RecurringToolView` (line 72) and `HomeScreen` (line 180) guide the user.
- Action-oriented CTAs like "Create Account", "Split Bill", and "Manage your monthly subscriptions".
- Error states in `HomeScreen` (line 167) and `RecurringToolView` (line 64) use non-technical, helpful language ("Storage unavailable", "Unable to load subscriptions").

### Pillar 2: Visuals (4/4)
- Proactive use of `FittedBox` in `StatsScreen` (lines 91, 212, 297), `AccountsScreen` (lines 109, 366, 437), and `HomeScreen` (lines 368, 424, 544) successfully prevents text overflows for large currency amounts.
- Strong visual hierarchy on `StatsScreen` using the "Money Flow" display title (line 52) and bold metric tiles.
- Card components have consistent `borderRadius` (22 to 34 range) and subtle `boxShadow` for a layered depth.

### Pillar 3: Color (3/4)
- Consistent use of `0xFF0A6BE8` (Primary Blue), `0xFF1DAA63` (Success Green), and `0xFFFF446D` (Error Red).
- Finding: `Color` literals are hardcoded in almost every widget.
    - `StatsScreen.dart`: lines 44, 56, 73, 86, 97, 114, 121, 134, 176, 187, 206, 223, 224, 303, 342, 380, 389, 409, 410.
    - `AccountsScreen.dart`: lines 84, 91, 103, 158, 168, 282, 322, 329, 350, 415, 421, 431, 443, 453, 490, 495, 504.
- High-contrast text is maintained for accessibility (e.g., white text on blue gradients).

### Pillar 4: Typography (4/4)
- Heavily weighted fonts (`w800`, `w900`) create a distinct, authoritative "fintech" style.
- Scale distribution:
    - Display: 38 (Stats net total), 34 (Accounts Net Worth).
    - Sub-headline: 28, 25.
    - Standard UI: 16, 17, 18.
    - Labels: 10, 12.
- Consistent use of `letterSpacing: 1.1` to `1.8` on uppercase labels provides a professional aesthetic.

### Pillar 5: Spacing (4/4)
- Standardized spacing scale: 8, 12, 16, 22, 24, 32.
- Layouts use `EdgeInsets.all(20)` to `EdgeInsets.all(26)` for card containers, ensuring generous whitespace.
- Vertical separation between distinct tools (Split Bill vs. Recurring) is clear with `SizedBox(height: 32)`.

### Pillar 6: Experience Design (3/4)
- Strong state handling:
    - Loading: `LinearProgressIndicator` in `AccountsScreen` (line 175), `CircularProgressIndicator` in `RecurringToolView` (line 69).
    - Empty: Custom `_EmptyCard` widgets in all tool views.
    - Error: Conditional rendering for `hasError` in `HomeScreen` and `RecurringToolView`.
- Interaction: `InkWell` used for interactive cards in `TransactionCard` (line 57) and `_AccountCard` (line 404).
- Minor UX issue: `SplitBillToolView`'s `_amountController` (line 15) defaults to `'0'`, which requires clearing before typing.

---

## Files Audited
- `lib/features/expense/presentation/screens/accounts_screen.dart`
- `lib/features/expense/presentation/screens/home_screen.dart`
- `lib/features/expense/presentation/screens/stats_screen.dart`
- `lib/features/expense/presentation/widgets/recurring_tool_view.dart`
- `lib/features/expense/presentation/widgets/split_bill_tool_view.dart`
- `lib/features/expense/presentation/widgets/transaction_card.dart`
