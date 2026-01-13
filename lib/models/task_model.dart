import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskStatus {
  toDo,
  inProgress,
  done,
}

enum TaskPriority {
  low,
  medium,
  high,
}

// Task colors enum for easy selection
enum TaskColor {
  orange,
  red,
  blue,
  green,
  purple,
  yellow,
}

extension TaskColorExtension on TaskColor {
  Color get color {
    switch (this) {
      case TaskColor.orange:
        return const Color(0xFFFFCFA6); // Soft peach
      case TaskColor.red:
        return const Color(0xFFFFB4A2); // Soft coral
      case TaskColor.blue:
        return const Color(0xFF7BC4B8); // Mint-teal
      case TaskColor.green:
        return const Color(0xFF6FA876); // Darker sage green
      case TaskColor.purple:
        return const Color(0xFFCDB4DB); // Soft lavender
      case TaskColor.yellow:
        return const Color(0xFF98D8C8); // Soft mint
    }
  }
  
  int get value {
    return index;
  }
  
  static TaskColor fromValue(int value) {
    return TaskColor.values[value];
  }
}

class TaskModel {
  final String id;
  final String userId;
  final String taskName;
  final String description;
  final DateTime creationDate;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final String? category; // For custom lists like "Work", "Personal"
  final bool isWishlist; // For wishlist items
  final DateTime? reminderTime; // Custom alert time
  final TaskColor color; // Color for the task card
  
  TaskModel({
    required this.id,
    required this.userId,
    required this.taskName,
    required this.description,
    required this.creationDate,
    required this.dueDate,
    required this.status,
    this.priority = TaskPriority.medium,
    this.category,
    this.isWishlist = false,
    this.reminderTime,
    this.color = TaskColor.blue,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'taskName': taskName,
      'description': description,
      'creationDate': Timestamp.fromDate(creationDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status.name,
      'priority': priority.name,
      'category': category,
      'isWishlist': isWishlist,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'color': color.value,
    };
  }

  // Create from Firestore document
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      taskName: map['taskName'] ?? '',
      description: map['description'] ?? '',
      creationDate: (map['creationDate'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.toDo,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      category: map['category'],
      isWishlist: map['isWishlist'] ?? false,
      reminderTime: map['reminderTime'] != null 
          ? (map['reminderTime'] as Timestamp).toDate() 
          : null,
      color: map['color'] != null 
          ? TaskColorExtension.fromValue(map['color'] as int)
          : TaskColor.blue,
    );
  }

  // Create a copy with updated fields
  TaskModel copyWith({
    String? id,
    String? userId,
    String? taskName,
    String? description,
    DateTime? creationDate,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    String? category,
    bool? isWishlist,
    DateTime? reminderTime,
    TaskColor? color,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskName: taskName ?? this.taskName,
      description: description ?? this.description,
      creationDate: creationDate ?? this.creationDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isWishlist: isWishlist ?? this.isWishlist,
      reminderTime: reminderTime ?? this.reminderTime,
      color: color ?? this.color,
    );
  }

  // Check if task is due today
  bool isDueToday() {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  // Check if task is overdue
  bool isOverdue() {
    final now = DateTime.now();
    return dueDate.isBefore(now) && status != TaskStatus.done;
  }
}
