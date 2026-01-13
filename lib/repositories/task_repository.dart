import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Collection reference
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  // Create a new task
  Future<void> createTask({
    required String userId,
    required String taskName,
    required String description,
    required DateTime dueDate,
    String? category,
    bool isWishlist = false,
    DateTime? reminderTime,
    TaskColor color = TaskColor.blue,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final taskId = _uuid.v4();
    final task = TaskModel(
      id: taskId,
      userId: userId,
      taskName: taskName,
      description: description,
      creationDate: DateTime.now(),
      dueDate: dueDate,
      status: TaskStatus.toDo,
      priority: priority,
      category: category,
      isWishlist: isWishlist,
      reminderTime: reminderTime,
      color: color,
    );

    await _tasksCollection.doc(taskId).set(task.toMap());
  }

  // Get all tasks for a user
  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('isWishlist', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      // Sort in memory to avoid composite index
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    });
  }

  // Get today's tasks (To-Do tab)
  Stream<List<TaskModel>> getTodayTasks(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('isWishlist', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((task) => 
              task.dueDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              task.dueDate.isBefore(endOfDay.add(const Duration(seconds: 1))))
          .toList();
      // Sort in memory to avoid composite index
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    });
  }

  // Get tasks by status
  Stream<List<TaskModel>> getTasksByStatus(String userId, TaskStatus status) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.name)
        .where('isWishlist', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      // Sort in memory to avoid composite index
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    });
  }

  // Get tasks by category
  Stream<List<TaskModel>> getTasksByCategory(String userId, String category) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .where('isWishlist', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      // Sort in memory to avoid composite index
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    });
  }

  // Get wishlist tasks
  Stream<List<TaskModel>> getWishlistTasks(String userId) {
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('isWishlist', isEqualTo: true)
        .orderBy('creationDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Update task
  Future<void> updateTask(TaskModel task) async {
    await _tasksCollection.doc(task.id).update(task.toMap());
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await _tasksCollection.doc(taskId).update({'status': status.name});
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  // Get overdue tasks
  Stream<List<TaskModel>> getOverdueTasks(String userId) {
    final now = DateTime.now();
    
    return _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('isWishlist', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((task) => 
              task.dueDate.isBefore(now) &&
              (task.status == TaskStatus.toDo || task.status == TaskStatus.inProgress))
          .toList();
      // Sort in memory to avoid composite index
      tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return tasks;
    });
  }

  // Get tasks with reminders for notification scheduling
  Future<List<TaskModel>> getTasksWithReminders(String userId) async {
    final snapshot = await _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('reminderTime', isNull: false)
        .get();

    return snapshot.docs
        .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Get all unique categories for a user
  Future<List<String>> getUserCategories(String userId) async {
    final snapshot = await _tasksCollection
        .where('userId', isEqualTo: userId)
        .get();

    final categories = snapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['category'] as String?)
        .where((category) => category != null && category.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    return categories;
  }

  // Batch delete completed tasks
  Future<void> deleteCompletedTasks(String userId) async {
    final snapshot = await _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: TaskStatus.done.name)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Update category for all tasks of a user with oldCategory
  Future<void> updateTasksCategory(
    String userId,
    String oldCategory,
    String? newCategory,
  ) async {
    final snapshot = await _tasksCollection
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: oldCategory)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'category': newCategory});
    }
    await batch.commit();
  }
}
