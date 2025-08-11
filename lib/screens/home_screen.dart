import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:ui';
import '../models/todo_list_model.dart';
import '../models/task_model.dart';
import '../services/todo_list_service.dart';
import '../services/task_service.dart';
import '../services/supabase_auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/pomodoro_timer.dart';
import '../widgets/glass_card.dart';
import 'login_screen.dart';
import 'todo_list_detail_screen.dart';

class AddListIntent extends Intent {
  const AddListIntent();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late List<TodoList> _todoLists;
  late AnimationController _animationController;
  late TabController _tabController;
  final _authService = SupabaseAuthService();
  final _todoListService = TodoListService();
  final _taskService = TaskService();
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedListIndex = 0;
  Map<String, List<Task>> _tasksByList = {};
  bool _isTimerMinimized = false;
  bool _showCompletedTasks = true;
  
  // Timer state for minimized view
  int _timerTimeLeft = 25 * 60;
  bool _timerIsRunning = false;
  int _timerCompletedSessions = 0;
  
  // Timer controller for control
  final PomodoroTimerController _timerController = PomodoroTimerController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _todoLists = [];
    _tabController = TabController(length: 0, vsync: this);
    _ensureUserRecordAndLoadData();
  }

  Future<void> _ensureUserRecordAndLoadData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Ensure user record exists in database
        await _authService.ensureCurrentUserRecord();
      }
      _loadTodoLists();
    } catch (error) {
      print('❌ Error ensuring user record: $error');
      _loadTodoLists(); // Continue loading even if user record creation fails
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTodoLists() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final lists = await _todoListService.getUserTodoLists();
      
      // Load tasks for each list
      Map<String, List<Task>> tasksByList = {};
      for (final list in lists) {
        try {
          final tasks = await _taskService.getTasks(list.id);
          tasksByList[list.id] = tasks;
        } catch (error) {
          print('Error loading tasks for list ${list.name}: $error');
          tasksByList[list.id] = [];
        }
      }
      
      setState(() {
        _todoLists = lists;
        _tasksByList = tasksByList;
        _isLoading = false;
        
        // Update tab controller
        _tabController.dispose();
        _tabController = TabController(length: lists.length, vsync: this);
        if (_selectedListIndex >= lists.length) {
          _selectedListIndex = 0;
        }
        if (lists.isNotEmpty) {
          _tabController.index = _selectedListIndex;
        }
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load todo lists: $error';
        _isLoading = false;
      });
    }
  }

  void _showCreateListModal() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final colorController = TextEditingController(text: '#4A90E2');
    bool isPublic = false;

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
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50).withOpacity(0.95), // Semi-transparent dark blue-gray
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create New List',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // List name
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: AppTheme.white),
                        decoration: InputDecoration(
                          labelText: 'List Name',
                          labelStyle: const TextStyle(color: AppTheme.white),
                          hintText: 'Enter list name',
                          hintStyle: TextStyle(color: AppTheme.white.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.list_alt, color: AppTheme.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.white),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        autofocus: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: AppTheme.white),
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          labelStyle: const TextStyle(color: AppTheme.white),
                          hintText: 'Enter description',
                          hintStyle: TextStyle(color: AppTheme.white.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.description, color: AppTheme.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.white),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Color picker (simplified)
                      TextField(
                        controller: colorController,
                        style: const TextStyle(color: AppTheme.white),
                        decoration: InputDecoration(
                          labelText: 'Color (Hex)',
                          labelStyle: const TextStyle(color: AppTheme.white),
                          hintText: '#4A90E2',
                          hintStyle: TextStyle(color: AppTheme.white.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.color_lens, color: AppTheme.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.white),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Public toggle
                      Row(
                        children: [
                          Switch(
                            value: isPublic,
                            activeColor: AppTheme.primaryBlue,
                            inactiveThumbColor: AppTheme.white.withOpacity(0.7),
                            inactiveTrackColor: AppTheme.white.withOpacity(0.3),
                            onChanged: (value) {
                              setModalState(() {
                                isPublic = value;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Make list public',
                            style: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.white,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: AppTheme.white,
                              ),
                              onPressed: () async {
                                if (nameController.text.trim().isEmpty) return;
                                
                                try {
                                  await _todoListService.createTodoList(
                                    name: nameController.text.trim(),
                                    description: descriptionController.text.trim().isEmpty 
                                        ? null 
                                        : descriptionController.text.trim(),
                                    color: colorController.text.trim(),
                                    isPublic: isPublic,
                                  );
                                  
                                  Navigator.of(context).pop();
                                  _loadTodoLists();
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
  
  Future<void> _confirmDeleteList(TodoList todoList) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C3E50),
          title: const Text(
            'Delete List',
            style: TextStyle(color: AppTheme.white),
          ),
          content: Text(
            'Are you sure you want to delete "${todoList.name}"?\n\nThis will permanently delete the list and all its tasks. This action cannot be undone.',
            style: const TextStyle(color: AppTheme.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.white)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        await _todoListService.deleteTodoList(todoList.id);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('List "${todoList.name}" deleted successfully'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        
        // Reload the lists
        _loadTodoLists();
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting list: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Public method to be called from global hotkey
  void showAddTaskModalFromHotkey() {
    if (_todoLists.isNotEmpty) {
      _showCreateTaskModal(_todoLists[_selectedListIndex]);
    } else {
      _showCreateListModal();
    }
  }

  void _showCreateTaskModal(TodoList todoList) {
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
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50).withOpacity(0.95), // Semi-transparent dark blue-gray
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Add Task to "${todoList.name}"',
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
                        style: const TextStyle(color: AppTheme.white),
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          labelStyle: const TextStyle(color: AppTheme.white),
                          hintText: 'Enter task title',
                          hintStyle: TextStyle(color: AppTheme.white.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.task_alt, color: AppTheme.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.white),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        autofocus: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: AppTheme.white),
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          labelStyle: const TextStyle(color: AppTheme.white),
                          hintText: 'Enter description',
                          hintStyle: TextStyle(color: AppTheme.white.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.description, color: AppTheme.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.white),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Priority selector
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.white.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: DropdownButtonFormField<PriorityLevel>(
                          value: selectedPriority,
                          dropdownColor: const Color(0xFF2C3E50),
                          style: const TextStyle(color: AppTheme.white),
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            labelStyle: const TextStyle(color: AppTheme.white),
                            prefixIcon: const Icon(Icons.flag, color: AppTheme.white),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            border: Border.all(color: AppTheme.white.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppTheme.white),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  selectedDueDate != null
                                      ? DateFormat('MMM d, yyyy - h:mm a').format(selectedDueDate!)
                                      : 'Set due date (optional)',
                                  style: TextStyle(
                                    color: selectedDueDate != null 
                                        ? AppTheme.white
                                        : AppTheme.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                              if (selectedDueDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, color: AppTheme.white),
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
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.white,
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: AppTheme.white,
                              ),
                              onPressed: () async {
                                if (titleController.text.trim().isEmpty) return;
                                
                                try {
                                  await _taskService.createTask(
                                    todoListId: todoList.id,
                                    title: titleController.text.trim(),
                                    description: descriptionController.text.trim().isEmpty 
                                        ? null 
                                        : descriptionController.text.trim(),
                                    priority: selectedPriority,
                                    dueDate: selectedDueDate,
                                  );
                                  
                                  Navigator.of(context).pop();
                                  _loadTodoLists();
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

  void _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.keyC): const AddListIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC): const AddListIntent(),
      },
      child: Actions(
        actions: {
          AddListIntent: CallbackAction<AddListIntent>(
            onInvoke: (intent) => _showCreateListModal(),
          ),
        },
        child: Focus(
          autofocus: ModalRoute.of(context)?.isCurrent ?? false,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Glass morphic background layer
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                // Main content
                Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top section with header and timer - no top padding
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.lgSpacing),
                    child: Column(
                      children: [
                        // Account section at very top with minimal spacing
                        SizedBox(height: 4),
                        _buildHeader(),
                        const SizedBox(height: 4),
                        // Timer section right below header
                        _buildPomodoroSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.smSpacing),
                  // Todo lists section fills remaining space
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.lgSpacing),
                      child: _buildTodoListsSection(),
                    ),
                  ),
                ],
              ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                if (_todoLists.isNotEmpty) {
                  _showCreateTaskModal(_todoLists[_selectedListIndex]);
                } else {
                  _showCreateListModal();
                }
              },
              backgroundColor: _todoLists.isNotEmpty 
                  ? Color(int.parse(_todoLists[_selectedListIndex].color?.replaceFirst('#', '') ?? '4A90E2', radix: 16) + 0xFF000000)
                  : AppTheme.primaryBlue,
              child: const Icon(
                Icons.add,
                color: AppTheme.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = _authService.currentUser;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PopupMenuButton<String>(
          icon: CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              (user?.email?.substring(0, 1).toUpperCase() ?? 'U'),
              style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold),
            ),
          ),
          onSelected: (value) {
            if (value == 'signout') {
              _signOut();
            } else if (value == 'refresh') {
              _loadTodoLists();
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
            const PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimizedTimerContent() {
    // Calculate progress for clockwise direction - need total time from template
    final totalTime = 25 * 60; // Default fallback, will be updated by actual template time
    final double progress = (1 - (_timerTimeLeft / totalTime)).clamp(0.0, 1.0);
    final stateInfo = _timerController.stateInfo;
    
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          // State indicator badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: stateInfo.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  stateInfo.icon,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  stateInfo.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Compact timer display with progress
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress circle with state color
                CircularProgressIndicator(
                  value: progress, // Clockwise progress
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
                // Time display
                Text(
                  _formatTimeMinimized(_timerTimeLeft),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Session info and controls
          Expanded(
            child: Row(
              children: [
                // Session progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timerController.templateName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${_timerCompletedSessions} sessions completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.white.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Compact play/pause button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleTimer,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _timerIsRunning ? Icons.pause : Icons.play_arrow,
                        color: AppTheme.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onMinimizedTimerTap() {
    // Expand timer and let user interact with full controls
    setState(() {
      _isTimerMinimized = false;
    });
  }

  void _updateTimerState() {
    // This will be called by the timer widget to update our local state
    if (mounted) {
      setState(() {});
    }
  }

  void _onTimerUpdate(int timeLeft, bool isRunning, int completedSessions) {
    if (mounted) {
      setState(() {
        _timerTimeLeft = timeLeft;
        _timerIsRunning = isRunning;
        _timerCompletedSessions = completedSessions;
      });
    }
  }

  void _toggleTimer() {
    _timerController.togglePlayPause();
  }

  String _formatTimeMinimized(int seconds) {
    // Ensure seconds is non-negative
    final safeSeconds = seconds.abs();
    final minutes = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (safeSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Widget _buildPomodoroSection() {
    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(_isTimerMinimized ? AppConstants.smSpacing : AppConstants.lgSpacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with minimize/maximize button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_isTimerMinimized) ...[
                  Text(
                    _timerController.templateName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: AppTheme.white),
                  ),
                ] else ...[
                  // Minimized state - show compact timer info
                  Expanded(
                    child: _buildMinimizedTimerContent(),
                  ),
                ],
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isTimerMinimized = !_isTimerMinimized;
                    });
                  },
                  icon: Icon(
                    _isTimerMinimized ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: AppTheme.white,
                    size: 20,
                  ),
                  tooltip: _isTimerMinimized ? 'Expand Timer' : 'Minimize Timer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
            
            // Timer content - always present but hidden when minimized
            Visibility(
              visible: !_isTimerMinimized,
              maintainState: true,
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.mdSpacing),
                  PomodoroTimer(
                    controller: _timerController,
                    onStateChanged: _updateTimerState,
                    onTimerUpdate: _onTimerUpdate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoListsSection() {
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
              onPressed: _loadTodoLists,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_todoLists.isEmpty) {
      return Column(
        children: [
          // Show header with create list button even when empty
          Row(
            children: [
              Expanded(
                child: Text(
                  'Todo Lists',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppTheme.white.withOpacity(0.8)),
                ),
              ),
              IconButton(
                onPressed: _showCreateListModal,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.white.withOpacity(0.8),
                  size: 24,
                ),
                tooltip: 'Create New List',
              ),
            ],
          ),
          const SizedBox(height: AppConstants.mdSpacing),
          // Empty state
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    color: AppTheme.white.withOpacity(0.3),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No todo lists yet',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: AppTheme.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first list to get started!',
                    style: TextStyle(color: AppTheme.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateListModal,
                    icon: const Icon(Icons.add),
                    label: const Text('Create List'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Header with tab bar and create list button
        Row(
          children: [
            // Tab bar for todo lists
            Expanded(
              child: Container(
                height: 48,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppTheme.white,
                  unselectedLabelColor: AppTheme.white.withOpacity(0.6),
                  indicatorColor: AppTheme.primaryBlue,
                  onTap: (index) {
                    setState(() {
                      _selectedListIndex = index;
                    });
                  },
                  tabs: _todoLists.asMap().entries.map((entry) {
                    final index = entry.key;
                    final list = entry.value;
                    final isSelected = index == _selectedListIndex;
                    final color = Color(
                      int.parse(list.color?.replaceFirst('#', '') ?? '4A90E2', radix: 16) + 0xFF000000,
                    );
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(list.name),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: AppTheme.white.withOpacity(0.8),
                                size: 16,
                              ),
                              tooltip: 'List Options',
                              color: const Color(0xFF2C3E50),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _confirmDeleteList(list);
                                } else if (value == 'edit') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Edit functionality coming soon!')),
                                  );
                                }
                              },
                              itemBuilder: (context) {
                                return [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.edit, color: AppTheme.white, size: 16),
                                        const SizedBox(width: 8),
                                        const Text('Edit', style: TextStyle(color: AppTheme.white)),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.delete, color: Colors.red, size: 16),
                                        const SizedBox(width: 8),
                                        const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Create list button
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                onPressed: _showCreateListModal,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.white.withOpacity(0.8),
                  size: 24,
                ),
                tooltip: 'Create New List',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.smSpacing),
        // Filter toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showCompletedTasks = !_showCompletedTasks;
                  });
                },
                icon: Icon(
                  _showCompletedTasks ? Icons.check_box : Icons.check_box_outline_blank,
                  color: AppTheme.white.withOpacity(0.8),
                  size: 20,
                ),
                label: Text(
                  'Show completed',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.smSpacing),
        // Tasks for selected list
        Expanded(
          child: _buildTasksForCurrentList(),
        ),
      ],
    );
  }

  Widget _buildTasksForCurrentList() {
    if (_todoLists.isEmpty) return Container();
    
    final currentList = _todoLists[_selectedListIndex];
    final tasks = _tasksByList[currentList.id] ?? [];
    
    if (tasks.isEmpty) {
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
              'Add your first task!',
              style: TextStyle(color: AppTheme.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateTaskModal(currentList),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
      );
    }

    // Separate incomplete and completed tasks
    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final completedTasks = tasks.where((t) => t.isCompleted).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    
    // Combine tasks based on filter
    final displayTasks = _showCompletedTasks 
        ? [...incompleteTasks, ...completedTasks]
        : incompleteTasks;

    if (displayTasks.isEmpty) {
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
              _showCompletedTasks ? 'No tasks yet' : 'No open tasks',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppTheme.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first task!',
              style: TextStyle(color: AppTheme.white.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateTaskModal(currentList),
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Single unified task list
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: ReorderableListView.builder(
              proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Material(
                        color: Colors.transparent,
                        elevation: 0,
                        child: child,
                      );
                    },
                    child: child,
                  );
                },
                onReorder: (oldIndex, newIndex) async {
                  // Only allow reordering of incomplete tasks
                  if (oldIndex >= incompleteTasks.length || newIndex > incompleteTasks.length) {
                    return;
                  }
                  
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  
                  setState(() {
                    final reorderedIncompleteTasks = List<Task>.from(incompleteTasks);
                    final movedTask = reorderedIncompleteTasks.removeAt(oldIndex);
                    reorderedIncompleteTasks.insert(newIndex, movedTask);
                    
                    // Update positions based on new order
                    for (int i = 0; i < reorderedIncompleteTasks.length; i++) {
                      reorderedIncompleteTasks[i] = reorderedIncompleteTasks[i].copyWith(position: i);
                    }
                    
                    // Update the tasks map
                    _tasksByList[currentList.id] = [
                      ...reorderedIncompleteTasks,
                      ...completedTasks,
                    ];
                  });
                  
                  // Update positions in database
                  try {
                    final reorderedTasks = (_tasksByList[currentList.id] ?? [])
                        .where((t) => !t.isCompleted)
                        .toList();
                    await _taskService.reorderTasks(currentList.id, reorderedTasks);
                  } catch (error) {
                    // On reorder error, show message but keep local state
                    // Only reload as last resort if user dismisses error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error reordering tasks: $error'),
                        action: SnackBarAction(
                          label: 'Retry',
                          onPressed: () async {
                            try {
                              final reorderedTasks = (_tasksByList[currentList.id] ?? [])
                                  .where((t) => !t.isCompleted)
                                  .toList();
                              await _taskService.reorderTasks(currentList.id, reorderedTasks);
                            } catch (retryError) {
                              // Only reload if retry also fails
                              _loadTodoLists();
                            }
                          },
                        ),
                      ),
                    );
                  }
                },
                buildDefaultDragHandles: false,
                itemCount: displayTasks.length,
                itemBuilder: (context, index) {
                  final task = displayTasks[index];
                  final isIncomplete = !task.isCompleted;
                  return _buildTaskCard(
                    key: ValueKey(task.id),
                    task: task,
                    todoList: currentList,
                    showDragHandle: isIncomplete,
                    index: isIncomplete ? index : null,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskCard({
    Key? key,
    required Task task,
    required TodoList todoList,
    bool showDragHandle = false,
    int? index,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: GlassCard(
        backgroundColor: task.isCompleted 
            ? const Color(0xFF8B95DC)  // Muted purple for completed
            : null,  // Use default gradient for active tasks
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.mdSpacing),
          child: Row(
            children: [
              // Drag handle (more subtle)
              if (showDragHandle && index != null) ...[
                ReorderableDragStartListener(
                  index: index,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(
                      Icons.drag_handle,
                      color: AppTheme.white.withOpacity(0.3),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.smSpacing),
              ],
              
              // Checkbox
              Theme(
                data: Theme.of(context).copyWith(
                  checkboxTheme: CheckboxThemeData(
                    side: BorderSide(
                      color: task.isCompleted ? AppTheme.primaryBlue : AppTheme.white,
                      width: 2,
                    ),
                    fillColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppTheme.primaryBlue;
                      }
                      return Colors.transparent;
                    }),
                    checkColor: MaterialStateProperty.all(AppTheme.white),
                  ),
                ),
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) async {
                    try {
                      // Optimistic UI update - update local state immediately
                      setState(() {
                        final tasks = _tasksByList[todoList.id] ?? [];
                        final taskIndex = tasks.indexWhere((t) => t.id == task.id);
                        if (taskIndex != -1) {
                          _tasksByList[todoList.id]![taskIndex] = task.copyWith(isCompleted: value ?? false);
                        }
                      });
                      
                      // Update database in background
                      await _taskService.toggleTaskCompletion(task.id);
                    } catch (error) {
                      // Revert optimistic update on error
                      setState(() {
                        final tasks = _tasksByList[todoList.id] ?? [];
                        final taskIndex = tasks.indexWhere((t) => t.id == task.id);
                        if (taskIndex != -1) {
                          _tasksByList[todoList.id]![taskIndex] = task.copyWith(isCompleted: !(value ?? false));
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $error')),
                      );
                    }
                  },
                ),
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
                      // Optimistic UI update - remove from local state immediately
                      setState(() {
                        final tasks = _tasksByList[todoList.id] ?? [];
                        _tasksByList[todoList.id] = tasks.where((t) => t.id != task.id).toList();
                      });
                      
                      // Delete from database in background
                      await _taskService.deleteTask(task.id);
                    } catch (error) {
                      // Revert optimistic update on error by reloading
                      _loadTodoLists();
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

  Widget _buildTodoListCard(TodoList todoList) {
    final color = Color(
      int.parse(todoList.color?.replaceFirst('#', '') ?? '4A90E2', radix: 16) + 0xFF000000,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: GlassCard(
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TodoListDetailScreen(todoList: todoList),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.lgSpacing),
            child: Row(
              children: [
                // Color indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppConstants.mdSpacing),
                
                // List info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              todoList.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (todoList.isPublic)
                            Icon(
                              Icons.public,
                              color: AppTheme.white.withOpacity(0.5),
                              size: 16,
                            ),
                        ],
                      ),
                      if (todoList.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          todoList.description!,
                          style: TextStyle(
                            color: AppTheme.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}