import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_list_model.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';

class TodoListDetailScreen extends StatefulWidget {
  final TodoList todoList;

  const TodoListDetailScreen({
    super.key,
    required this.todoList,
  });

  @override
  State<TodoListDetailScreen> createState() => _TodoListDetailScreenState();
}

class _TodoListDetailScreenState extends State<TodoListDetailScreen> {
  final _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final tasks = await _taskService.getTasks(widget.todoList.id);
      
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load tasks: $error';
        _isLoading = false;
      });
    }
  }

  void _showCreateTaskModal() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    PriorityLevel selectedPriority = PriorityLevel.medium;
    DateTime? selectedDueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GlassCard(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add New Task',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Task title
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          hintText: 'Enter task title',
                          prefixIcon: const Icon(Icons.task_alt),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                        ),
                        autofocus: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Enter description',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Priority selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<PriorityLevel>(
                          value: selectedPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            prefixIcon: Icon(Icons.flag),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: PriorityLevel.values.map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Row(
                                children: [
                                  _buildPriorityIcon(priority),
                                  const SizedBox(width: 8),
                                  Text(priority.displayName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() {
                                selectedPriority = value;
                              });
                            }
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Due date picker
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setModalState(() {
                                selectedDueDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  selectedDueDate != null
                                      ? DateFormat('MMM d, yyyy - h:mm a').format(selectedDueDate!)
                                      : 'Set due date (optional)',
                                  style: TextStyle(
                                    color: selectedDueDate != null 
                                        ? Theme.of(context).textTheme.bodyMedium?.color
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              if (selectedDueDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setModalState(() {
                                      selectedDueDate = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (titleController.text.trim().isEmpty) return;
                                
                                try {
                                  await _taskService.createTask(
                                    todoListId: widget.todoList.id,
                                    title: titleController.text.trim(),
                                    description: descriptionController.text.trim().isEmpty 
                                        ? null 
                                        : descriptionController.text.trim(),
                                    priority: selectedPriority,
                                    dueDate: selectedDueDate,
                                  );
                                  
                                  Navigator.of(context).pop();
                                  _loadTasks();
                                } catch (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $error')),
                                  );
                                }
                              },
                              child: const Text('Create'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriorityIcon(PriorityLevel priority) {
    Color color;
    IconData icon;

    switch (priority) {
      case PriorityLevel.low:
        color = Colors.green;
        icon = Icons.keyboard_arrow_down;
        break;
      case PriorityLevel.medium:
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case PriorityLevel.high:
        color = Colors.red;
        icon = Icons.keyboard_arrow_up;
        break;
      case PriorityLevel.urgent:
        color = Colors.purple;
        icon = Icons.priority_high;
        break;
    }

    return Icon(icon, color: color, size: 16);
  }

  @override
  Widget build(BuildContext context) {
    final listColor = Color(
      int.parse(widget.todoList.color?.replaceFirst('#', '') ?? '4A90E2', radix: 16) + 0xFF000000,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.todoList.name,
              style: const TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.todoList.description != null)
              Text(
                widget.todoList.description!,
                style: TextStyle(
                  color: AppTheme.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.white),
            onSelected: (value) {
              if (value == 'refresh') {
                _loadTasks();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.lgSpacing),
        child: _buildTasksSection(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskModal,
        backgroundColor: listColor,
        child: const Icon(
          Icons.add,
          color: AppTheme.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.white.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: AppTheme.white.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              color: AppTheme.white.withOpacity(0.3),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppTheme.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first task to get started!',
              style: TextStyle(color: AppTheme.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateTaskModal,
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
      );
    }

    // Sort tasks: incomplete first, then completed
    final sortedTasks = List<Task>.from(_tasks);
    sortedTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.position.compareTo(b.position);
    });

    return ListView.builder(
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.mdSpacing),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: task.isCompleted,
                onChanged: (value) async {
                  try {
                    await _taskService.toggleTaskCompletion(task.id);
                    _loadTasks();
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $error')),
                    );
                  }
                },
                activeColor: AppTheme.primaryBlue,
              ),
              
              const SizedBox(width: AppConstants.mdSpacing),
              
              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and priority
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: task.isCompleted 
                                      ? AppTheme.white.withOpacity(0.5)
                                      : AppTheme.white,
                                  decoration: task.isCompleted 
                                      ? TextDecoration.lineThrough 
                                      : null,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        _buildPriorityIcon(task.priority),
                      ],
                    ),
                    
                    // Description
                    if (task.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: TextStyle(
                          color: task.isCompleted 
                              ? AppTheme.white.withOpacity(0.3)
                              : AppTheme.white.withOpacity(0.7),
                          fontSize: 12,
                          decoration: task.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Due date
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: task.isOverdue 
                                ? Colors.red 
                                : AppTheme.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, h:mm a').format(task.dueDate!),
                            style: TextStyle(
                              color: task.isOverdue 
                                  ? Colors.red 
                                  : AppTheme.white.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: task.isOverdue ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppTheme.white.withOpacity(0.3),
                  size: 20,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: Text('Are you sure you want to delete "${task.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    try {
                      await _taskService.deleteTask(task.id);
                      _loadTasks();
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $error')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}