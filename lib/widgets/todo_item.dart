import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../models/todo_item.dart';

class TodoItemWidget extends StatefulWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<TodoItemWidget> createState() => _TodoItemWidgetState();
}

class _TodoItemWidgetState extends State<TodoItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Dismissible(
              key: Key(widget.todo.id),
              direction: DismissDirection.endToStart,
              background: _buildDismissBackground(),
              onDismissed: (direction) {
                widget.onDelete();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppConstants.smSpacing),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onToggle,
                    borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                    child: Container(
                      padding: const EdgeInsets.all(AppConstants.mdSpacing),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                        border: Border.all(
                          color: widget.todo.isCompleted 
                              ? AppColors.limeGreen.withValues(alpha: 0.3)
                              : AppColors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.todo.isCompleted 
                                  ? AppColors.limeGreen
                                  : AppColors.white,
                              border: Border.all(
                                color: widget.todo.isCompleted 
                                    ? AppColors.limeGreen
                                    : AppColors.grey.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: widget.todo.isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          
                          const SizedBox(width: AppConstants.mdSpacing),
                          
                          // Todo Text
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: widget.todo.isCompleted 
                                    ? AppColors.grey.withValues(alpha: 0.6)
                                    : AppColors.black,
                                decoration: widget.todo.isCompleted 
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: AppColors.limeGreen,
                                decorationThickness: 2,
                              ) ?? const TextStyle(),
                              child: Text(widget.todo.title),
                            ),
                          ),
                          
                          // Priority indicator (optional)
                          if (!widget.todo.isCompleted)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.electricBlue.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smSpacing),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.lgSpacing),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.delete,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: AppConstants.smSpacing),
          Text(
            'Delete',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 