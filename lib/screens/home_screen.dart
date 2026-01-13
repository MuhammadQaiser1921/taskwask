import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/task_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import '../widgets/smart_list_header.dart';
import '../widgets/calendar_view.dart';
import 'add_task_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCalendarView = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SmartListType _selectedList = SmartListType.all;
  String? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = context.read<AuthRepository>();
    final userId = authRepo.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text(
          _isCalendarView ? 'Calendar' : _getListTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        actions: [
          // View toggle with segmented control style
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggle(
                  icon: Icons.list_rounded,
                  isSelected: !_isCalendarView,
                  onTap: () => setState(() => _isCalendarView = false),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: AppTheme.borderGrey,
                ),
                _buildViewToggle(
                  icon: Icons.calendar_month_rounded,
                  isSelected: _isCalendarView,
                  onTap: () => setState(() => _isCalendarView = true),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Smart Lists Header (only in list view)
          if (!_isCalendarView)
            StreamBuilder<List<TaskModel>>(
              stream: context.read<TaskRepository>().getUserTasks(userId),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                final taskCounts = _calculateTaskCounts(tasks);
                
                return SmartListHeader(
                  selectedList: _selectedList,
                  onListSelected: (type) {
                    setState(() {
                      _selectedList = type;
                      _searchQuery = ''; // Clear search when switching lists
                      _searchController.clear();
                    });
                  },
                  taskCounts: taskCounts,
                );
              },
            ),
          
          // Search Bar (only in list view, translucent style)
          if (!_isCalendarView)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 14,
                ),
              ),
            ),
          
          // Category Filter (only in list view, appears after search)
          if (!_isCalendarView)
            StreamBuilder<List<TaskModel>>(
              stream: context.read<TaskRepository>().getUserTasks(userId),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                // Get unique categories from tasks
                final categories = tasks
                    .where((t) => t.category != null && t.category!.isNotEmpty)
                    .map((t) => t.category!)
                    .toSet()
                    .toList()
                  ..sort();
                
                if (categories.isEmpty) return const SizedBox.shrink();
                
                return Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip('All', _selectedCategory == null),
                      const SizedBox(width: 8),
                      ...categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(
                            category,
                            _selectedCategory == category,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          
          // Content (List or Calendar)
          Expanded(
            child: _isCalendarView
                ? const CalendarView()
                : _TaskListView(
                    userId: userId,
                    searchQuery: _searchQuery,
                    selectedList: _selectedList,
                    selectedCategory: _selectedCategory,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddTaskScreen(),
            ),
          );
          
          // Show success message if task was created
          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Task created successfully',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.fixed,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }
  
  Widget _buildCategoryChip(String category, bool isSelected) {
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? (category == 'All' ? null : category) : null;
        });
      },
      backgroundColor: AppTheme.cardBackground,
      selectedColor: const Color(0xFF10B981).withOpacity(0.1),
      checkmarkColor: const Color(0xFF10B981),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF10B981) : AppTheme.borderGrey,
      ),
    );
  }
  
  Widget _buildViewToggle({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
        ),
      ),
    );
  }
  
  String _getListTitle() {
    switch (_selectedList) {
      case SmartListType.myDay:
        return 'My Day';
      case SmartListType.important:
        return 'Important';
      case SmartListType.planned:
        return 'Planned';
      case SmartListType.all:
        return 'Tasks';
    }
  }
  
  Map<SmartListType, int> _calculateTaskCounts(List<TaskModel> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return {
      SmartListType.myDay: tasks.where((t) {
        final taskDate = DateTime(
          t.dueDate.year,
          t.dueDate.month,
          t.dueDate.day,
        );
        return taskDate == today && t.status != TaskStatus.done;
      }).length,
      SmartListType.important: tasks.where((t) => 
        t.category == 'Important' && t.status != TaskStatus.done
      ).length,
      SmartListType.planned: tasks.where((t) => 
        t.status != TaskStatus.done
      ).length,
      SmartListType.all: tasks.length,
    };
  }
}

class _TaskListView extends StatelessWidget {
  final String userId;
  final String searchQuery;
  final SmartListType selectedList;
  final String? selectedCategory;

  const _TaskListView({
    required this.userId,
    required this.searchQuery,
    required this.selectedList,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final taskRepo = context.read<TaskRepository>();
    final tasksStream = taskRepo.getUserTasks(userId);

    return StreamBuilder<List<TaskModel>>(
      stream: tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF10B981),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Error loading tasks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final allTasks = snapshot.data ?? [];
        
        // Filter by smart list type
        List<TaskModel> tasks;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        switch (selectedList) {
          case SmartListType.myDay:
            tasks = allTasks.where((t) {
              final taskDate = DateTime(
                t.dueDate.year,
                t.dueDate.month,
                t.dueDate.day,
              );
              return taskDate == today && t.status != TaskStatus.done;
            }).toList();
            break;
          case SmartListType.important:
            tasks = allTasks.where((t) => 
              t.category == 'Important' && t.status != TaskStatus.done
            ).toList();
            break;
          case SmartListType.planned:
            tasks = allTasks.where((t) => 
              t.status != TaskStatus.done
            ).toList();
            break;
          case SmartListType.all:
            tasks = allTasks;
            break;
        }

        // Filter by search query
        if (searchQuery.isNotEmpty) {
          tasks = tasks.where((task) {
            return task.taskName.toLowerCase().contains(searchQuery) ||
                   task.description.toLowerCase().contains(searchQuery);
          }).toList();
        }
        
        // Filter by category
        if (selectedCategory != null) {
          tasks = tasks.where((task) {
            return task.category == selectedCategory;
          }).toList();
        }

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  searchQuery.isEmpty ? Icons.event_available_outlined : Icons.search_off,
                  size: 80,
                  color: const Color(0xFF6B7280).withOpacity(0.5),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  searchQuery.isEmpty ? 'No tasks yet' : 'No tasks found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (searchQuery.isEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tap + to create your first task',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        }

        // Group tasks by status
        final todoTasks = tasks.where((t) => t.status == TaskStatus.toDo).toList();
        final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
        final completedTasks = tasks.where((t) => t.status == TaskStatus.done).toList();

        // Build list with grouped sections
        return ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xxl * 2,
          ),
          children: [
            // TO DO Section
            if (todoTasks.isNotEmpty) ...[
              _buildStatusHeader(context, 'TO DO', todoTasks.length),
              ..._buildPriorityGroups(context, todoTasks, taskRepo),
            ],
            
            // IN PROGRESS Section
            if (inProgressTasks.isNotEmpty) ...[
              _buildStatusHeader(context, 'IN PROGRESS', inProgressTasks.length),
              ..._buildPriorityGroups(context, inProgressTasks, taskRepo),
            ],
            
            // COMPLETED Section
            if (completedTasks.isNotEmpty) ...[
              _buildStatusHeader(context, 'COMPLETED', completedTasks.length),
              ..._buildTaskList(context, completedTasks, taskRepo),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatusHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
        left: AppSpacing.xs,
      ),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildPriorityGroups(
    BuildContext context,
    List<TaskModel> tasks,
    TaskRepository taskRepo,
  ) {
    // Group by priority
    final highPriority = tasks.where((t) => t.priority == TaskPriority.high).toList();
    final mediumPriority = tasks.where((t) => t.priority == TaskPriority.medium).toList();
    final lowPriority = tasks.where((t) => t.priority == TaskPriority.low).toList();

    final widgets = <Widget>[];

    // High Priority
    if (highPriority.isNotEmpty) {
      widgets.add(_buildPriorityHeader(context, 'High Priority', AppTheme.taskCoral));
      widgets.addAll(_buildTaskList(context, highPriority, taskRepo));
    }

    // Medium Priority
    if (mediumPriority.isNotEmpty) {
      widgets.add(_buildPriorityHeader(context, 'Medium Priority', AppTheme.taskPeach));
      widgets.addAll(_buildTaskList(context, mediumPriority, taskRepo));
    }

    // Low Priority
    if (lowPriority.isNotEmpty) {
      widgets.add(_buildPriorityHeader(context, 'Low Priority', AppTheme.taskSage));
      widgets.addAll(_buildTaskList(context, lowPriority, taskRepo));
    }

    return widgets;
  }

  Widget _buildPriorityHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
        left: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(Icons.flag, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaskList(
    BuildContext context,
    List<TaskModel> tasks,
    TaskRepository taskRepo,
  ) {
    // Sort by due date
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return tasks.map((task) {
      return TaskTile(
        task: task,
        onStatusChanged: (newStatus) {
          taskRepo.updateTaskStatus(task.id, newStatus);
        },
        onStarToggle: () {
          // Toggle Important category
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
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Delete',
                    style: const TextStyle(color: Color(0xFFEF4444)),
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
    }).toList();
  }
}