# Quick Actions and FAB Refactor Design

**Goal**: Refactor the home screen quick actions to be horizontally scrollable, add a "Scanner" option with a "Soon" tag, remove the FAB long-press menu, and reposition the FAB lower.

## Architecture & Components

### 1. `QuickActionBar` (Flex-Bar)
*   **Implementation**: Wrap the existing `Row` in a `SingleChildScrollView`.
*   **Scrolling**: `scrollDirection: Axis.horizontal`.
*   **Layout**: Use `MainAxisSize.min` for the `Row` to allow it to be as wide as its children, ensuring scrolling works.
*   **Visuals**: Keep the current container styling (white, rounded, shadow).

### 2. `HomeScreen`
*   **Action List**: Add a new `QuickActionItem` for "SCANNER" with `icon: Icons.qr_code_scanner_rounded`, `label: 'SCANNER'`, and `badgeLabel: 'Soon'`.
*   **Order**: SMS, VOICE, SMART, SCANNER, MANUAL.

### 3. `AppShell` & `PowerPill`
*   **FAB Repositioning**: Decrease `AppSpacing.fabOffset` or the `Padding` in `AppShell` to move the FAB closer to the bottom edge.
*   **Menu Removal**: Delete `_showPowerMenu` and `_menuOverlay`. Remove `onLongPress` from the `PowerPill` widget.
*   **Cleanup**: Remove the `PowerPillMenu` class entirely if it's no longer used.

## Data Flow
*   The `QuickActionBar` remains stateless, receiving actions and a callback from `HomeScreen`.

## Testing
*   Verify horizontal scrolling on narrow screens.
*   Confirm FAB click still opens the add expense screen.
*   Confirm no errors occur since `onLongPress` is removed.
