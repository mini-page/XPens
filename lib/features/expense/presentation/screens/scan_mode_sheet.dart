import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';

/// Shows the [ScanModeSheet] as a modal bottom sheet.
///
/// The sheet lets the user choose between two scanning modes:
///   1. Scan Receipt / Bill — barcode / QR extraction.
///   2. Snap a Product     — AI-powered product identification.
Future<void> showScanModeSheet(BuildContext context) {
  // Capture the outer navigator context before the sheet is shown so that
  // navigation after the sheet dismisses works on a mounted context.
  final outerContext = context;
  return showModalBottomSheet<void>(
    context: outerContext,
    backgroundColor: Colors.transparent,
    builder: (_) => ScanModeSheet(outerContext: outerContext),
  );
}

/// A bottom sheet presenting two scan-mode option cards.
class ScanModeSheet extends StatelessWidget {
  const ScanModeSheet({super.key, required this.outerContext});

  /// The [BuildContext] of the widget that opened this sheet. Used for
  /// navigation after the sheet is dismissed.
  final BuildContext outerContext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan & Log',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Choose how to capture the expense',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mode 1 — Receipt / Bill
            _ScanModeCard(
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF0A6BE8),
              iconBackground: const Color(0xFFE8F0FE),
              title: 'Scan Receipt / Bill',
              subtitle:
                  'Point the camera at any barcode or QR on a receipt to auto-fill amount & merchant',
              onTap: () {
                Navigator.of(context).pop();
                AppRoutes.pushReceiptScanner(outerContext);
              },
            ),
            const SizedBox(height: 12),

            // Mode 2 — Snap a Product (AI)
            _ScanModeCard(
              icon: Icons.camera_alt_rounded,
              iconColor: const Color(0xFF7B2FF7),
              iconBackground: const Color(0xFFF3E8FF),
              title: 'Snap a Product',
              subtitle:
                  'Photograph a product — AI identifies it and pre-fills the expense for you',
              badge: 'AI',
              onTap: () {
                Navigator.of(context).pop();
                AppRoutes.pushProductScanner(outerContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Option card ───────────────────────────────────────────────────────────────

class _ScanModeCard extends StatelessWidget {
  const _ScanModeCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceAccent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B2FF7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Color(0xFF7B2FF7),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
