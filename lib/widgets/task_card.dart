import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../screens/edit_task_screen.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final Function(TaskStatus) onStatusChanged;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.microInteraction,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: widget.task),
      ),
    );
  }

  Color _getCardColor() {
    // Use the task's assigned color
    return widget.task.color.color;
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.task.isOverdue();
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final cardColor = _getCardColor();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: cardColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                // Color Strip
                Container(
                  width: 6,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                
                // Task Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          children: [
                            // Status Checkbox
                            GestureDetector(
                              onTap: () {
                                _showStatusDialog(context);
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.task.status == TaskStatus.done 
                                        ? cardColor 
                                        : AppTheme.textSecondary,
                                    width: 2,
                                  ),
                                  color: widget.task.status == TaskStatus.done 
                                      ? cardColor 
                                      : Colors.transparent,
                                ),
                                child: widget.task.status == TaskStatus.done
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: AppTheme.primaryWhite,
                                      )
                                    : null,
                              ),
                            ),
                            
                            const SizedBox(width: AppSpacing.md),
                            
                            // Task Name
                            Expanded(
                              child: Text(
                                widget.task.taskName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  decoration: widget.task.status == TaskStatus.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: widget.task.status == TaskStatus.done
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            
                            // More Options
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
                              color: AppTheme.cardBackground,
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _handleTap();
                                } else if (value == 'delete') {
                                  _showDeleteDialog(context);
                                }
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Description
                        if (widget.task.description.isNotEmpty) ...[
                          Text(
                            widget.task.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: _isExpanded ? null : 2,
                            overflow: _isExpanded ? null : TextOverflow.ellipsis,
                          ),
                          if (widget.task.description.length > 100)
                            TextButton(
                              onPressed: () {
                                setState(() => _isExpanded = !_isExpanded);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _isExpanded ? 'Show less' : 'Show more',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        
                        // Footer Row
                        Row(
                          children: [
                            // Due Date
                            Icon(
                              isOverdue ? Icons.warning_amber_outlined : Icons.calendar_today_outlined,
                              size: 14,
                              color: isOverdue ? AppTheme.taskRed : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormatter.format(widget.task.dueDate),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: isOverdue ? AppTheme.taskRed : AppTheme.textSecondary,
                                fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            
                            if (widget.task.category != null) ...[
                              const SizedBox(width: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  widget.task.category!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: cardColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  void _showStatusDialog(BuildContext context) {
    final cardColor = _getCardColor();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskStatus.values.map((status) {
            return RadioListTile<TaskStatus>(
              title: Text(_getStatusName(status)),
              value: status,
              groupValue: widget.task.status,
              activeColor: cardColor,
              onChanged: (value) {
                if (value != null) {
                  widget.onStatusChanged(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onDelete();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkGrey,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getStatusName(TaskStatus status) {
    switch (status) {
      case TaskStatus.toDo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}
