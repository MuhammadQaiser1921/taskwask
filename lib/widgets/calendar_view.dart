import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<TaskModel>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<TaskModel> _getTasksForDay(DateTime day) {
    final normalized = _normalizeDate(day);
    return _tasksByDate[normalized] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    final userId = authRepo.currentUser?.uid ?? '';
    final taskRepo = context.read<TaskRepository>();

    return StreamBuilder<List<TaskModel>>(
      stream: taskRepo.getUserTasks(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Group tasks by date
          _tasksByDate = {};
          for (var task in snapshot.data!) {
            final normalizedDate = _normalizeDate(task.dueDate);
            if (_tasksByDate[normalizedDate] == null) {
              _tasksByDate[normalizedDate] = [];
            }
            _tasksByDate[normalizedDate]!.add(task);
          }
        }

        final selectedTasks = _selectedDay != null 
            ? _getTasksForDay(_selectedDay!)
            : [];

        return Column(
          children: [
            // Calendar
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: TableCalendar<TaskModel>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getTasksForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.accentBlue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppTheme.taskMint,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: const TextStyle(color: AppTheme.textPrimary),
                  weekendTextStyle: const TextStyle(color: AppTheme.textSecondary),
                  todayTextStyle: const TextStyle(color: AppTheme.textPrimary),
                  selectedTextStyle: const TextStyle(color: AppTheme.primaryWhite),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: AppTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                  titleTextStyle: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: AppTheme.textPrimary,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textPrimary,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
            
            // Selected Date Tasks Header
            if (_selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(_selectedDay!),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedTasks.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '${selectedTasks.length} ${selectedTasks.length == 1 ? 'task' : 'tasks'}',
                          style: const TextStyle(
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            // Tasks List for Selected Date
            Expanded(
              child: selectedTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 64,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No tasks for this day',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.xxl * 2,
                      ),
                      itemCount: selectedTasks.length,
                      itemBuilder: (context, index) {
                        final task = selectedTasks[index];
                        return TaskTile(
                          task: task,
                          onStatusChanged: (newStatus) {
                            taskRepo.updateTaskStatus(task.id, newStatus);
                          },
                          onStarToggle: () {
                            final newCategory = task.category == 'Important' 
                                ? 'General' 
                                : 'Important';
                            final updatedTask = task.copyWith(category: newCategory);
                            taskRepo.updateTask(updatedTask);
                          },
                          onDelete: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppTheme.cardBackground,
                                title: Text(
                                  'Delete Task',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                content: Text(
                                  'Are you sure you want to delete "${task.taskName}"?',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: AppTheme.textSecondary),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: AppTheme.taskCoral),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            
                            if (shouldDelete == true) {
                              taskRepo.deleteTask(task.id);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
