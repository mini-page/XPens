# Gemini CLI Project Configuration: XPensa

You are acting as an expert Senior Flutter Developer and Architect working on the `XPensa` application, an expense tracker built specifically for Android (and cross-platform).

## Project Tech Stack
- **Framework:** Flutter (Dart >= 3.0.0)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Local Storage / Database:** Hive (`hive`, `hive_flutter`)
- **Charting & Data Viz:** `fl_chart`
- **Other Key Dependencies:** `mobile_scanner`, `workmanager`, `file_picker`, `permission_handler`.

## Core Architectural Guidelines

### 1. Feature-First Architecture
The app follows a feature-driven folder structure inside `lib/`.
- `lib/core/`: Application-wide utilities, constants, themes, and base classes (e.g., `lib/core/theme/app_colors.dart`).
- `lib/features/`: Contains isolated feature modules like `accounts`, `analytics`, `categories`, `expense`, `recurring`, `settings`, `transactions`.
- `lib/shared/`: Shared reusable UI widgets and components across multiple features (e.g., `app_button.dart`).
- Every new feature should be self-contained with its own `data`, `domain`, and `presentation` layers.

### 2. State Management (Riverpod)
- Always use Riverpod (`ConsumerWidget`, `ConsumerStatefulWidget`, `Notifier`, `AsyncNotifier`) for state management.
- Avoid using `setState` or `StatefulWidget` unless handling strictly localized, ephemeral UI state (like an animation controller).
- Keep business logic inside Providers and Notifiers, not in UI widgets.

### 3. Data Persistence (Hive)
- Data is stored locally using Hive. Ensure models are properly generated with TypeAdapters.
- When querying data, wrap Hive boxes in repository classes.

### 4. UI & Styling
- Adhere to the established custom theme in `lib/core/theme/`.
- Use the defined design tokens (Colors, Typography, Spacing).
- Ensure the app remains visually polished, following Material Design principles with a modern aesthetic, keeping Android specifics in mind.

### 5. Best Practices & Code Quality
- Write clean, DRY, and well-documented Dart code.
- Always implement and update tests when modifying business logic or providers (`test/features/...`).
- Run `flutter analyze` and address all linting warnings before finalizing any feature.
- Run `flutter format .` to maintain code consistency.
- Handle exceptions gracefully and provide user-friendly error messages.

## Execution Directives
- **Validation First:** When asked to implement a feature, always test it locally or advise the user to run `flutter run` to verify.
- **Dependency Checks:** If instructed to use a new package, run `flutter pub add <package>` first and verify compatibility.
- **Context Search:** Utilize the `grep_search` and `glob` tools to find existing widgets or utility functions in `lib/shared` and `lib/core` before building anything from scratch to prevent duplication.
