import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum SmartListType {
  myDay,
  important,
  planned,
  all,
}

class SmartListHeader extends StatelessWidget {
  final SmartListType selectedList;
  final Function(SmartListType) onListSelected;
  final Map<SmartListType, int> taskCounts;

  const SmartListHeader({
    super.key,
    required this.selectedList,
    required this.onListSelected,
    required this.taskCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildSmartListButton(
            context,
            SmartListType.myDay,
            Icons.wb_sunny_rounded,
            'My Day',
            AppTheme.taskSky,
          ),
          const SizedBox(width: 12),
          _buildSmartListButton(
            context,
            SmartListType.planned,
            Icons.calendar_today_rounded,
            'Planned',
            AppTheme.taskSky,
          ),
        ],
      ),
    );
  }

  Widget _buildSmartListButton(
    BuildContext context,
    SmartListType type,
    IconData icon,
    String label,
    Color color,
  ) {
    final isSelected = selectedList == type;
    final count = taskCounts[type] ?? 0;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onListSelected(type),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? color.withOpacity(0.4)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? color : Colors.white,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 16,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? color : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
