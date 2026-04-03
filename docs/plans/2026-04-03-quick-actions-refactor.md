# Quick Actions and FAB Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor quick actions to be scrollable, add Scanner (Soon), remove FAB long-press, and lower FAB position.

**Architecture:** Update `QuickActionBar` to use `SingleChildScrollView`, update `HomeScreen` data, and clean up `AppShell` FAB logic.

**Tech Stack:** Flutter, Dart.

---

### Task 1: Refactor QuickActionBar to Flex-Bar

**Files:**
- Modify: `lib/features/expense/presentation/widgets/quick_action_bar.dart`

**Step 1: Replace Row with SingleChildScrollView**

Wrap the `Row` in a `SingleChildScrollView` with `scrollDirection: Axis.horizontal` and set `MainAxisSize.min` on the `Row`.

**Step 2: Commit**

```bash
git add lib/features/expense/presentation/widgets/quick_action_bar.dart
git commit -m "refactor: make QuickActionBar horizontally scrollable"
```

---

### Task 2: Add Scanner to HomeScreen Quick Actions

**Files:**
- Modify: `lib/features/expense/presentation/screens/home_screen.dart`

**Step 1: Update QuickActionItem list**

Add `QuickActionItem(label: 'SCANNER', icon: Icons.qr_code_scanner_rounded, isEnabled: false, badgeLabel: 'Soon')` before the `MANUAL` action.

**Step 2: Commit**

```bash
git add lib/features/expense/presentation/screens/home_screen.dart
git commit -m "feat: add Scanner (Soon) to quick actions"
```

---

### Task 3: Remove FAB Long Press and Position Lower

**Files:**
- Modify: `lib/features/expense/presentation/screens/app_shell.dart`
- Modify: `lib/features/expense/presentation/widgets/power_pill_menu.dart` (Cleanup)

**Step 1: Remove long press logic in AppShell**

Delete `_menuOverlay`, `_showPowerMenu`, and the `onLongPress` callback from the `PowerPill` usage.

**Step 2: Adjust FAB position**

Decrease the `bottom` padding in the `floatingActionButton` `Padding` wrapper from `AppSpacing.fabOffset` (which is 92) to a lower value (e.g., 78) to move it closer to the bottom nav bar.

**Step 3: Update PowerPill definition**

Remove `onLongPress` field and usage from `PowerPill` class in `power_pill_menu.dart`.

**Step 4: Cleanup PowerPillMenu**

Delete the `PowerPillMenu` class from `power_pill_menu.dart`.

**Step 5: Commit**

```bash
git add lib/features/expense/presentation/screens/app_shell.dart lib/features/expense/presentation/widgets/power_pill_menu.dart
git commit -m "refactor: remove FAB long press and adjust position"
```

---

### Task 4: Verification

**Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors.

**Step 2: Run flutter test**

Run: `flutter test`
Expected: All tests pass.
