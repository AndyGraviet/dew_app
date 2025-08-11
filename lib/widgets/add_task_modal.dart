import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/app_theme.dart';

class AddTaskModal extends StatefulWidget {
  final Function(Task) onAddTask;

  const AddTaskModal({super.key, required this.onAddTask});

  @override
  _AddTaskModalState createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  DateTime? _dueDate;
  late FocusNode _titleFocusNode;

  @override
  void initState() {
    super.initState();
    _titleFocusNode = FocusNode();
    _titleFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: AppTheme.white,
              onSurface: AppTheme.darkText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newTask = Task(
        id: DateTime.now().toString(),
        title: _title,
      );
      widget.onAddTask(newTask);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1B2333),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Task',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: AppTheme.white),
              ),
              const SizedBox(height: 24),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDueDateSelector(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildTitleField() {
    return TextFormField(
      focusNode: _titleFocusNode,
      style: const TextStyle(color: AppTheme.white),
      decoration: InputDecoration(
        labelText: 'Task Title',
        labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.7)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.white.withOpacity(0.5)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.white),
        ),
      ),
      onFieldSubmitted: (_) => _submitForm(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
      onSaved: (value) {
        _title = value!;
      },
    );
  }

  Widget _buildDueDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date',
          style: TextStyle(color: AppTheme.white.withOpacity(0.7)),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.white.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dueDate == null
                      ? 'Select a date'
                      : '${_dueDate!.toLocal()}'.split(' ')[0],
                  style: const TextStyle(color: AppTheme.white, fontSize: 16),
                ),
                const Icon(Icons.calendar_today, color: AppTheme.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _submitForm,
        child: const Text(
          'Add Task',
          style: TextStyle(color: AppTheme.white, fontSize: 16),
        ),
      ),
    );
  }
} 