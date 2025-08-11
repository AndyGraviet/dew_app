import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/timer_template_model.dart';
import '../services/timer_template_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';

class TimerCreationScreen extends StatefulWidget {
  final TimerTemplate? editingTemplate;
  
  const TimerCreationScreen({super.key, this.editingTemplate});

  @override
  State<TimerCreationScreen> createState() => _TimerCreationScreenState();
}

class _TimerCreationScreenState extends State<TimerCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timerTemplateService = TimerTemplateService();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _workDurationController;
  late TextEditingController _breakDurationController;
  late TextEditingController _longBreakDurationController;
  late TextEditingController _longBreakIntervalController;
  late TextEditingController _totalSessionsController;
  
  bool _isDefault = false;
  String _selectedColor = '#FF6B6B';
  bool _isLoading = false;
  
  final List<String> _colorOptions = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#96CEB4', // Green
    '#FFEAA7', // Yellow
    '#DDA0DD', // Plum
    '#FFB347', // Orange
    '#87CEEB', // Sky Blue
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final template = widget.editingTemplate;
    
    _nameController = TextEditingController(text: template?.name ?? '');
    _descriptionController = TextEditingController(text: template?.description ?? '');
    _workDurationController = TextEditingController(text: (template?.workDurationMinutes ?? 25).toString());
    _breakDurationController = TextEditingController(text: (template?.breakDurationMinutes ?? 5).toString());
    _longBreakDurationController = TextEditingController(text: (template?.longBreakDurationMinutes ?? 15).toString());
    _longBreakIntervalController = TextEditingController(text: (template?.longBreakInterval ?? 4).toString());
    _totalSessionsController = TextEditingController(text: (template?.totalSessions ?? 4).toString());
    
    _isDefault = template?.isDefault ?? false;
    _selectedColor = template?.color ?? '#FF6B6B';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _workDurationController.dispose();
    _breakDurationController.dispose();
    _longBreakDurationController.dispose();
    _longBreakIntervalController.dispose();
    _totalSessionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGradient.colors.first,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.lgSpacing),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBasicInfoSection(),
                        const SizedBox(height: AppConstants.lgSpacing),
                        _buildTimingSection(),
                        const SizedBox(height: AppConstants.lgSpacing),
                        _buildSessionsSection(),
                        const SizedBox(height: AppConstants.lgSpacing),
                        _buildCustomizationSection(),
                        const SizedBox(height: AppConstants.xlSpacing),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.lgSpacing),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          ),
          const SizedBox(width: AppConstants.mdSpacing),
          Expanded(
            child: Text(
              widget.editingTemplate != null ? 'Edit Timer' : 'Create New Timer',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.mdSpacing),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Timer Name',
                hintText: 'e.g., Focus Sessions',
                prefixIcon: const Icon(Icons.timer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                ),
                filled: true,
                fillColor: AppTheme.white.withOpacity(0.1),
              ),
              style: const TextStyle(color: AppTheme.white),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a timer name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.mdSpacing),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Briefly describe this timer setup',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                ),
                filled: true,
                fillColor: AppTheme.white.withOpacity(0.1),
              ),
              style: const TextStyle(color: AppTheme.white),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Timing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.mdSpacing),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _workDurationController,
                    label: 'Work Duration',
                    suffix: 'minutes',
                    icon: Icons.work,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final num = int.tryParse(value);
                      if (num == null || num < 1 || num > 180) {
                        return '1-180 min';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.mdSpacing),
                Expanded(
                  child: _buildNumberField(
                    controller: _breakDurationController,
                    label: 'Short Break',
                    suffix: 'minutes',
                    icon: Icons.coffee,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final num = int.tryParse(value);
                      if (num == null || num < 1 || num > 60) {
                        return '1-60 min';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.mdSpacing),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _longBreakDurationController,
                    label: 'Long Break',
                    suffix: 'minutes',
                    icon: Icons.lunch_dining,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final num = int.tryParse(value);
                      if (num == null || num < 1 || num > 120) {
                        return '1-120 min';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.mdSpacing),
                Expanded(
                  child: _buildNumberField(
                    controller: _longBreakIntervalController,
                    label: 'Long Break After',
                    suffix: 'sessions',
                    icon: Icons.schedule,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final num = int.tryParse(value);
                      if (num == null || num < 2 || num > 10) {
                        return '2-10 sessions';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.mdSpacing),
            _buildNumberField(
              controller: _totalSessionsController,
              label: 'Total Sessions',
              suffix: 'sessions',
              icon: Icons.repeat,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final num = int.tryParse(value);
                if (num == null || num < 1 || num > 20) {
                  return '1-20 sessions';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationSection() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.lgSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customization',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.mdSpacing),
            
            // Color Selection
            Text(
              'Theme Color',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: AppConstants.smSpacing),
            Wrap(
              spacing: AppConstants.smSpacing,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${color.substring(1)}')),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppTheme.white, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: AppTheme.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: AppConstants.mdSpacing),
            
            // Default Toggle
            Row(
              children: [
                Switch(
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value),
                  activeColor: AppTheme.primaryBlue,
                ),
                const SizedBox(width: AppConstants.smSpacing),
                Expanded(
                  child: Text(
                    'Set as default timer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        ),
        filled: true,
        fillColor: AppTheme.white.withOpacity(0.1),
      ),
      style: const TextStyle(color: AppTheme.white),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveTimer,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.white,
        padding: const EdgeInsets.symmetric(vertical: AppConstants.mdSpacing),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.mdRadius),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            )
          : Text(
              widget.editingTemplate != null ? 'Update Timer' : 'Create Timer',
              style: const TextStyle(
                fontSize: AppConstants.lgFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Future<void> _saveTimer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final workDuration = int.parse(_workDurationController.text);
      final breakDuration = int.parse(_breakDurationController.text);
      final longBreakDuration = int.parse(_longBreakDurationController.text);
      final longBreakInterval = int.parse(_longBreakIntervalController.text);
      final totalSessions = int.parse(_totalSessionsController.text);

      if (widget.editingTemplate != null) {
        // Update existing template
        await _timerTemplateService.updateTimerTemplate(
          widget.editingTemplate!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          workDurationMinutes: workDuration,
          breakDurationMinutes: breakDuration,
          longBreakDurationMinutes: longBreakDuration,
          longBreakInterval: longBreakInterval,
          totalSessions: totalSessions,
          isDefault: _isDefault,
          color: _selectedColor,
        );
      } else {
        // Create new template
        await _timerTemplateService.createTimerTemplate(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          workDurationMinutes: workDuration,
          breakDurationMinutes: breakDuration,
          longBreakDurationMinutes: longBreakDuration,
          longBreakInterval: longBreakInterval,
          totalSessions: totalSessions,
          isDefault: _isDefault,
          color: _selectedColor,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving timer: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}