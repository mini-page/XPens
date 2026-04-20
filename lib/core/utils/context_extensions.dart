import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum AppFeedbackType { success, error, warning, info }

extension ContextExtensions on BuildContext {
  /// Shows a [SnackBar] with the given [message].
  void showSnackBar(
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    final (IconData icon, Color accent) = switch (type) {
      AppFeedbackType.success => (Icons.check_circle_rounded, AppColors.success),
      AppFeedbackType.error => (Icons.error_rounded, AppColors.danger),
      AppFeedbackType.warning => (Icons.warning_amber_rounded, AppColors.warning),
      AppFeedbackType.info => (Icons.info_rounded, AppColors.primaryBlue),
    };

    final textColor = isDark ? Colors.white : AppColors.textDark;

    final messenger = ScaffoldMessenger.of(this);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2438) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: accent,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }
}
