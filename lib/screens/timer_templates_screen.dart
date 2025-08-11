import 'package:flutter/material.dart';
import '../models/timer_template_model.dart';
import '../services/timer_template_service.dart';
import '../services/audio_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';
import 'timer_creation_screen.dart';

class TimerTemplatesScreen extends StatefulWidget {
  const TimerTemplatesScreen({super.key});

  @override
  State<TimerTemplatesScreen> createState() => _TimerTemplatesScreenState();
}

class _TimerTemplatesScreenState extends State<TimerTemplatesScreen> {
  final _timerTemplateService = TimerTemplateService();
  final _audioService = AudioService();
  List<TimerTemplate> _templates = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _currentVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _loadAudioSettings();
  }

  Future<void> _loadAudioSettings() async {
    setState(() {
      _currentVolume = _audioService.volume;
    });
  }

  Future<void> _loadTemplates() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final templates = await _timerTemplateService.getUserTimerTemplates();
      
      // Ensure there's at least a default template
      if (templates.isEmpty) {
        await _timerTemplateService.ensureDefaultTemplate();
        final updatedTemplates = await _timerTemplateService.getUserTimerTemplates();
        setState(() {
          _templates = updatedTemplates;
        });
      } else {
        setState(() {
          _templates = templates;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                child: _buildBody(),
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
              'Timer Templates',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _createNewTemplate,
            icon: const Icon(Icons.add, color: AppTheme.white),
            tooltip: 'Create New Timer',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.lgSpacing),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.white,
                size: 48,
              ),
              const SizedBox(height: AppConstants.mdSpacing),
              Text(
                'Error loading templates',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(height: AppConstants.smSpacing),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.lgSpacing),
              ElevatedButton(
                onPressed: _loadTemplates,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.lgSpacing),
        itemCount: _templates.length + 2, // +1 for create new card, +1 for audio settings
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAudioSettingsCard();
          }
          if (index == _templates.length + 1) {
            return _buildCreateNewCard();
          }
          return _buildTemplateCard(_templates[index - 1]);
        },
      ),
    );
  }

  Widget _buildAudioSettingsCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.lgSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.volume_up,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: AppConstants.smSpacing),
                  Text(
                    'Audio Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.mdSpacing),
              
              // Mute toggle
              Row(
                children: [
                  Icon(
                    _audioService.isMuted ? Icons.volume_off : Icons.volume_up,
                    color: AppTheme.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.smSpacing),
                  Text(
                    'Mute Timer Sounds',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.white.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: !_audioService.isMuted,
                    onChanged: (value) {
                      setState(() {
                        _audioService.setMuted(!value);
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                ],
              ),
              
              const SizedBox(height: AppConstants.mdSpacing),
              
              // Volume slider
              if (!_audioService.isMuted) ...[
                Row(
                  children: [
                    Icon(
                      Icons.volume_down,
                      color: AppTheme.white.withOpacity(0.5),
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.smSpacing),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.primaryBlue,
                          inactiveTrackColor: AppTheme.primaryBlue.withOpacity(0.3),
                          thumbColor: AppTheme.primaryBlue,
                          overlayColor: AppTheme.primaryBlue.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _currentVolume,
                          onChanged: (value) {
                            setState(() {
                              _currentVolume = value;
                            });
                            _audioService.setVolume(value);
                          },
                          onChangeEnd: (value) {
                            // Preview sound when slider is released
                            _audioService.previewVolume();
                          },
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.smSpacing),
                    Icon(
                      Icons.volume_up,
                      color: AppTheme.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ],
                ),
                
                Center(
                  child: Text(
                    '${(_currentVolume * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateNewCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: GlassCard(
        onTap: _createNewTemplate,
        child: Container(
          padding: const EdgeInsets.all(AppConstants.lgSpacing),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.3),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppTheme.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppConstants.mdSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Timer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.xsSpacing),
                    Text(
                      'Set up a custom timer with your preferred settings',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(TimerTemplate template) {
    final color = Color(int.parse('0xFF${template.color?.substring(1) ?? 'FF6B6B'}'));
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.mdSpacing),
      child: GlassCard(
        onTap: () => _selectTemplate(template),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.lgSpacing),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppConstants.mdRadius),
                ),
                child: const Icon(
                  Icons.timer,
                  color: AppTheme.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppConstants.mdSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (template.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.smSpacing,
                              vertical: AppConstants.xsSpacing,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(AppConstants.smRadius),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (template.description != null) ...[
                      const SizedBox(height: AppConstants.xsSpacing),
                      Text(
                        template.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.white.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppConstants.smSpacing),
                    Wrap(
                      spacing: AppConstants.mdSpacing,
                      runSpacing: AppConstants.xsSpacing,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.work,
                              size: 16,
                              color: AppTheme.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: AppConstants.xsSpacing),
                            Text(
                              '${template.workDurationMinutes}min',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.coffee,
                              size: 16,
                              color: AppTheme.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: AppConstants.xsSpacing),
                            Text(
                              '${template.breakDurationMinutes}min',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 16,
                              color: AppTheme.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: AppConstants.xsSpacing),
                            Text(
                              '${template.totalSessions}x',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppTheme.white.withOpacity(0.7),
                ),
                onSelected: (value) => _handleTemplateAction(value, template),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'select',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow),
                        SizedBox(width: 8),
                        Text('Use Timer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (!template.isDefault)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTemplateAction(String action, TimerTemplate template) {
    switch (action) {
      case 'select':
        _selectTemplate(template);
        break;
      case 'edit':
        _editTemplate(template);
        break;
      case 'delete':
        _deleteTemplate(template);
        break;
    }
  }

  void _selectTemplate(TimerTemplate template) {
    Navigator.of(context).pop(template);
  }

  Future<void> _createNewTemplate() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TimerCreationScreen(),
      ),
    );

    if (result == true) {
      _loadTemplates();
    }
  }

  Future<void> _editTemplate(TimerTemplate template) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TimerCreationScreen(editingTemplate: template),
      ),
    );

    if (result == true) {
      _loadTemplates();
    }
  }

  Future<void> _deleteTemplate(TimerTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timer Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _timerTemplateService.deleteTimerTemplate(template.id);
        _loadTemplates();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${template.name}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting template: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}