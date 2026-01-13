import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _taskNameController;
  late TextEditingController _descriptionController;
  
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  DateTime? _reminderTime;
  late bool _isWishlist;
  late TaskStatus _status;
  late TaskColor _selectedColor;
  late TaskPriority _selectedPriority;
  bool _isLoading = false;
  String? _selectedCategory;
  List<String> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController(text: widget.task.taskName);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedCategory = widget.task.category ?? 'None';
    
    // Initialize with default categories and current category immediately
    _availableCategories = [
      'Work',
      'Personal',
      'Shopping',
      'Health',
      'Study',
    ];
    
    // Add current category if it's not in the list and not null/'None'
    if (widget.task.category != null && 
        widget.task.category != 'None' && 
        !_availableCategories.contains(widget.task.category)) {
      _availableCategories.add(widget.task.category!);
    }
    
    _dueDate = widget.task.dueDate;
    _dueTime = TimeOfDay.fromDateTime(widget.task.dueDate);
    _reminderTime = widget.task.reminderTime;
    _isWishlist = widget.task.isWishlist;
    _status = widget.task.status;
    _selectedColor = widget.task.color;
    _selectedPriority = widget.task.priority;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categories = prefs.getStringList('user_categories') ?? [
      'Work',
      'Personal',
      'Shopping',
      'Health',
      'Study',
    ];
    
    // Add current category if it's not in the list and not null/'None'
    if (widget.task.category != null && 
        widget.task.category != 'None' && 
        !categories.contains(widget.task.category)) {
      categories.add(widget.task.category!);
    }
    
    setState(() {
      _availableCategories = categories;
    });
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.accentBlue,
              onPrimary: Colors.white,
              surface: AppTheme.primaryBackground,
              onSurface: AppTheme.textPrimary,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.accentBlue,
              onPrimary: Colors.white,
              surface: AppTheme.primaryBackground,
              onSurface: AppTheme.textPrimary,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _selectReminderTime() async {
    final options = [
      '1 hour before',
      '1 day before',
      '1 week before',
      'Custom',
      'No reminder',
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return ListTile(
              title: Text(option),
              onTap: () => Navigator.of(context).pop(option),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null && mounted) {
      final dueDateTime = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      setState(() {
        switch (result) {
          case '1 hour before':
            _reminderTime = dueDateTime.subtract(const Duration(hours: 1));
            break;
          case '1 day before':
            _reminderTime = dueDateTime.subtract(const Duration(days: 1));
            break;
          case '1 week before':
            _reminderTime = dueDateTime.subtract(const Duration(days: 7));
            break;
          case 'No reminder':
            _reminderTime = null;
            break;
          case 'Custom':
            // Show custom date/time picker
            _selectCustomReminder();
            break;
        }
      });
    }
  }

  Future<void> _selectCustomReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _dueDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.accentBlue,
              onPrimary: Colors.white,
              surface: AppTheme.primaryBackground,
              onSurface: AppTheme.textPrimary,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppTheme.accentBlue,
                onPrimary: Colors.white,
                surface: AppTheme.primaryBackground,
                onSurface: AppTheme.textPrimary,
              ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          _reminderTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<bool?> _showExactAlarmPermissionDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Exact Alarms'),
        content: const Text(
          'To schedule notifications at exact times, this app needs permission to set exact alarms. '
          'Would you like to open settings to enable this permission?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final taskRepo = context.read<TaskRepository>();
      final notificationService = NotificationService();

      final dueDateTime = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      final updatedTask = widget.task.copyWith(
        taskName: _taskNameController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: dueDateTime,
        category: _selectedCategory,
        isWishlist: _isWishlist,
        reminderTime: _reminderTime,
        status: _status,
        color: _selectedColor,
        priority: _selectedPriority,
      );

      await taskRepo.updateTask(updatedTask);

      // Update notifications safely
      try {
        await notificationService.cancelTaskNotification(widget.task.id);
        if (_status != TaskStatus.done) {
          // Check if exact alarm permission is granted
          final canSchedule = await notificationService.canScheduleExactAlarms();
          
          if (!canSchedule && mounted) {
            // Show dialog to request permission
            final shouldOpenSettings = await _showExactAlarmPermissionDialog();
            if (shouldOpenSettings == true) {
              await notificationService.requestExactAlarmPermission();
            }
          } else {
            // Permission granted, schedule notifications
            await notificationService.scheduleDueDateNotification(updatedTask);
            if (_reminderTime != null) {
              await notificationService.scheduleReminderNotification(updatedTask);
            }
          }
        }
      } catch (e) {
        // Log error but don't crash - notification scheduling is optional
        debugPrint('Failed to schedule notifications: $e');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully'),
            backgroundColor: AppTheme.taskBlue,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update task',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final timeFormatter = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.taskBlue),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updateTask,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Task Name
            TextFormField(
              controller: _taskNameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                hintText: 'Enter task name',
                prefixIcon: Icon(Icons.task_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task name';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter task description',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category (Optional)',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select a category'),
              items: [
                const DropdownMenuItem(
                  value: 'None',
                  child: Text('No Category'),
                ),
                ..._availableCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value == 'None' ? null : value;
                });
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Status
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Status'),
              subtitle: Text(_getStatusName(_status)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showStatusPicker(),
            ),

            const Divider(),

            // Due Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Due Date'),
              subtitle: Text(dateFormatter.format(_dueDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
            ),

            const Divider(),

            // Due Time
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Due Time'),
              subtitle: Text(_dueTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTime,
            ),

            const Divider(),

            // Reminder
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Reminder'),
              subtitle: Text(
                _reminderTime != null
                    ? '${dateFormatter.format(_reminderTime!)} at ${timeFormatter.format(_reminderTime!)}'
                    : 'No reminder set',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectReminderTime,
            ),

            const Divider(),

            // Priority Selector
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flag_outlined, color: AppTheme.textSecondary),
                      SizedBox(width: AppSpacing.md),
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriorityChip(
                          'Low',
                          TaskPriority.low,
                          AppTheme.taskSage,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildPriorityChip(
                          'Medium',
                          TaskPriority.medium,
                          AppTheme.taskPeach,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildPriorityChip(
                          'High',
                          TaskPriority.high,
                          AppTheme.taskCoral,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Color Picker
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_outlined, color: AppTheme.textSecondary),
                      SizedBox(width: AppSpacing.md),
                      Text(
                        'Color',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: TaskColor.values.map((color) {
                      final isSelected = _selectedColor == color;
                      return InkWell(
                        onTap: () => setState(() => _selectedColor = color),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected 
                                  ? Colors.white 
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const Divider(),

            const SizedBox(height: AppSpacing.xl),

            // Update Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateTask,
                icon: const Icon(Icons.save),
                label: const Text('Update Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskStatus.values.map((status) {
            return RadioListTile<TaskStatus>(
              title: Text(_getStatusName(status)),
              value: status,
              groupValue: _status,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
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

  Widget _buildPriorityChip(String label, TaskPriority priority, Color color) {
    final isSelected = _selectedPriority == priority;
    return InkWell(
      onTap: () => setState(() => _selectedPriority = priority),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 16,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
