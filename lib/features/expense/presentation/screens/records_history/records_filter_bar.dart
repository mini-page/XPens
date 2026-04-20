import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import 'records_filter.dart';

/// Horizontal scrollable row of [ChoiceChip]s for filtering records.
class RecordsFilterChips extends StatelessWidget {
  const RecordsFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.labelForFilter,
    this.onCustomDateRange,
    this.customDateRange,
  });

  final RecordsFilter selectedFilter;
  final ValueChanged<RecordsFilter> onFilterSelected;
  final String Function(RecordsFilter) labelForFilter;
  final VoidCallback? onCustomDateRange;
  final DateTimeRange? customDateRange;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: RecordsFilter.values.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(labelForFilter(filter)),
              selected: isSelected,
              onSelected: (_) {
                if (filter == RecordsFilter.custom) {
                  onCustomDateRange?.call();
                } else {
                  onFilterSelected(filter);
                }
              },
              avatar: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
              // Intentionally use a custom selected-state icon via avatar.
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.primaryBlue.withValues(alpha: 0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              selectedColor: AppColors.primaryBlue,
              backgroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF48607E),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 13,
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
