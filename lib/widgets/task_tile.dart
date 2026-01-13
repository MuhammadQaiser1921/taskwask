import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';
import '../screens/edit_task_screen.dart';

/// Microsoft To-Do style slim task tile
class TaskTile extends StatefulWidget {
  final TaskModel task;
  final Function(TaskStatus) onStatusChanged;
  final VoidCallback onDelete;
  final VoidCallback? onStarToggle;

  const TaskTile({
    super.key,
    required this.task,
    required this.onStatusChanged,
    required this.onDelete,
    this.onStarToggle,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );
    
    if (widget.task.status == TaskStatus.done) {
      _checkController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  void _handleCheckboxTap() {
    final newStatus = widget.task.status == TaskStatus.done 
        ? TaskStatus.toDo 
        : TaskStatus.done;
    
    if (newStatus == TaskStatus.done) {
      _checkController.forward();
    } else {
      _checkController.reverse();
    }
    
    widget.onStatusChanged(newStatus);
  }

  void _handleTileTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(task: widget.task),
      ),
    );
  }

  Color _getTaskColor() {
    return widget.task.color.color;
  }

  @override
  Widget build(BuildContext context) {
    final taskColor = _getTaskColor();
    final isCompleted = widget.task.status == TaskStatus.done;
    final dateFormatter = DateFormat('MMM dd');
    final isOverdue = widget.task.isOverdue() && !isCompleted;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF3D4052) : const Color(0xFF36394A),
          border: Border(
            left: BorderSide(
              color: taskColor,
              width: 3,
            ),
            bottom: const BorderSide(
              color: Color(0xFF404254),
              width: 1,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTileTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: _handleCheckboxTap,
                    child: AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted
                                  ? taskColor
                                  : const Color(0xFF9CA3AF),
                              width: 2,
                            ),
                            color: Color.lerp(
                              Colors.transparent,
                              taskColor,
                              _checkAnimation.value,
                            ),
                          ),
                          child: _checkAnimation.value > 0.5
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Task Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Title
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: const Color(0xFF9CA3AF),
                            color: isCompleted
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFFFFFFFF),
                          ),
                          child: Text(
                            widget.task.taskName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Due Date
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isOverdue
                                  ? Icons.warning_rounded
                                  : Icons.calendar_today_rounded,
                              size: 12,
                              color: isOverdue
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormatter.format(widget.task.dueDate),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isOverdue
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF9CA3AF),
                                fontWeight: isOverdue ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Star icon (for Important)
                  if (_isHovered || (widget.task.category == 'Important'))
                    IconButton(
                      icon: Icon(
                        widget.task.category == 'Important'
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 20,
                        color: widget.task.category == 'Important'
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF9CA3AF),
                      ),
                      onPressed: widget.onStarToggle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
