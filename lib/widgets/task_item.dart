import 'package:flutter/material.dart';
import '../models/task.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class TaskItemWidget extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;

  const TaskItemWidget({
    super.key,
    required this.task,
    required this.onToggle,
  });

  @override
  State<TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<TaskItemWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smSpacing),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onToggle,
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.mdSpacing,
                vertical: AppConstants.lgSpacing),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.task.isCompleted
                        ? AppTheme.primaryBlue
                        : AppTheme.white,
                    border: Border.all(
                      color: widget.task.isCompleted
                          ? AppTheme.primaryBlue
                          : AppTheme.white,
                      width: 2,
                    ),
                  ),
                  child: widget.task.isCompleted
                      ? const Icon(
                          Icons.check,
                          color: AppTheme.white,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: AppConstants.mdSpacing),
                // Task details
                Expanded(
                  child: Text(
                    widget.task.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.darkText,
                          decoration: widget.task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 