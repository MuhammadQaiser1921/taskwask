import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../repositories/task_repository.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<String> _categories = [];
  bool _isLoading = true;
  static const String _categoriesKey = 'user_categories';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _categories =
          prefs.getStringList(_categoriesKey) ??
          ['Work', 'Personal', 'Shopping', 'Health', 'Study'];
      _isLoading = false;
    });
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, _categories);
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'Enter category name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar('Category name cannot be empty');
                return;
              }
              if (_categories.contains(name)) {
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar('Category already exists');
                return;
              }

              // Close dialog first
              Navigator.of(dialogContext).pop();

              // Perform operations asynchronously
              setState(() {
                _categories.add(name);
              });
              _saveCategories().catchError((error) {
                if (mounted) {
                  _showErrorSnackBar('Failed to save category');
                  setState(() {
                    _categories.remove(name);
                  });
                }
              });

              // Show success after a brief delay to ensure dialog is closed
              if (mounted) {
                _showSuccessSnackBar('Category added successfully');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar('Category name cannot be empty');
                return;
              }
              if (newName != oldName && _categories.contains(newName)) {
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar('Category already exists');
                return;
              }

              // Close dialog first
              Navigator.of(dialogContext).pop();

              // Perform operations asynchronously
              final index = _categories.indexOf(oldName);
              if (index == -1) {
                if (mounted) {
                  _showErrorSnackBar('Category not found');
                }
                return;
              }

              setState(() {
                _categories[index] = newName;
              });

              _updateTasksCategory(oldName, newName);
              _saveCategories().catchError((error) {
                if (mounted) {
                  _showErrorSnackBar('Failed to save category');
                  setState(() {
                    _categories[index] = oldName;
                  });
                }
              });

              if (mounted) {
                _showSuccessSnackBar('Category updated successfully');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTasksCategory(
    String oldCategory,
    String newCategory,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // This would require adding a method to TaskRepository
      // For now, we'll handle it gracefully
    } catch (e) {
      // Handle error silently for now
    }
  }

  void _showDeleteCategoryDialog(String category) {
    // Check if any tasks use this category
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Show loading dialog immediately to not block UI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Run check asynchronously without blocking
    _checkCategoryInUse(category)
        .then((hasTasksWithCategory) {
          if (!mounted) return;

          // Close loading dialog
          Navigator.of(context).pop();

          if (hasTasksWithCategory) {
            _showCategoryInUseDialog(category);
          } else {
            _confirmDeleteCategory(category);
          }
        })
        .catchError((error) {
          if (!mounted) return;

          // Close loading dialog
          Navigator.of(context).pop();

          // Show error and allow simple delete
          _confirmDeleteCategory(category);
        });
  }

  Future<bool> _checkCategoryInUse(String category) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      final taskRepo = context.read<TaskRepository>();
      final categories = await taskRepo
          .getUserCategories(userId)
          .timeout(const Duration(seconds: 3), onTimeout: () => <String>[]);
      return categories.contains(category);
    } catch (e) {
      return false;
    }
  }

  void _showCategoryInUseDialog(String category) {
    final otherCategories = _categories.where((c) => c != category).toList();
    String? selectedCategory = 'None';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Category In Use'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This category is being used by some tasks. Please reassign them first.',
              ),
              const SizedBox(height: 16),
              const Text('Reassign tasks to:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select category',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'None',
                    child: Text('No Category'),
                  ),
                  ...otherCategories.map(
                    (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                  ),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedCategory = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Reassign tasks (convert 'None' to null)
                final newCat = selectedCategory == 'None'
                    ? null
                    : selectedCategory;

                // Store navigator before async operations
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                // Close dialog first
                navigator.pop();

                // Show loading using a BuildContext we can track
                BuildContext? loadingContext;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) {
                    loadingContext = ctx;
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                // Perform operations with proper error handling
                try {
                  await _reassignTasksCategory(category, newCat);
                  
                  if (!mounted) return;
                  
                  setState(() {
                    _categories.remove(category);
                  });
                  
                  await _saveCategories();
                  
                  // Close loading dialog using stored context
                  final ctx = loadingContext;
                  if (ctx != null && mounted) {
                    Navigator.of(ctx, rootNavigator: true).pop();
                  }
                  
                  if (!mounted) return;
                  
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Category deleted and tasks reassigned',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (error) {
                  // Close loading dialog using stored context
                  final ctx = loadingContext;
                  if (ctx != null && mounted) {
                    Navigator.of(ctx, rootNavigator: true).pop();
                  }
                  
                  if (!mounted) return;
                  
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to delete category',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Reassign & Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reassignTasksCategory(
    String oldCategory,
    String? newCategory,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final taskRepository = Provider.of<TaskRepository>(context, listen: false);
    
    // Update all tasks with oldCategory to newCategory in Firestore
    await taskRepository.updateTasksCategory(userId, oldCategory, newCategory);
  }

  void _confirmDeleteCategory(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$category"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close dialog first
              Navigator.of(context).pop();

              // Perform delete asynchronously
              setState(() {
                _categories.remove(category);
              });
              _saveCategories().catchError((error) {
                if (mounted) {
                  _showErrorSnackBar('Failed to delete category');
                }
              });

              if (mounted) {
                _showSuccessSnackBar('Category deleted successfully');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No categories yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Tap + to add a category'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditCategoryDialog(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: const Color(0xFFDC2626),
                          onPressed: () => _showDeleteCategoryDialog(category),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
