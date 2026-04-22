import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../utils/enum_labels.dart';
import '../../utils/format_helpers.dart';

/// Feature: goal-management
class GoalFormScreen extends StatefulWidget {
  final Goal? goal;

  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalRepository = ServiceLocator.goals;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  GoalType _type = GoalType.corporate;
  GoalStatus _status = GoalStatus.notStarted;
  DateTime? _targetDate;
  bool _saving = false;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _descriptionController.text = widget.goal!.description;
      _type = widget.goal!.type;
      _status = widget.goal!.status;
      _targetDate = widget.goal!.targetDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _targetDate ?? today;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _isEditing ? DateTime(2000) : today,
      lastDate: today.add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() {
        _targetDate = date;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    setState(() => _saving = true);

    try {
      Goal goal;
      if (_isEditing) {
        goal = widget.goal!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _type,
          status: _status,
          targetDate: _targetDate,
          clearTargetDate: _targetDate == null,
        );
      } else {
        goal = Goal.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _type,
          status: _status,
          targetDate: _targetDate,
        );
      }

      await _goalRepository.save(goal);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save goal: $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Goal' : 'New Goal')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter goal title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter goal description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text('Type', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<GoalType>(
                value: _type,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: GoalType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(type.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: 24),
              Text('Status', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: GoalStatus.values.map((status) {
                  return ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) {
                      setState(() {
                        _status = status;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Target Date', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _targetDate != null
                      ? formatDate(_targetDate)
                      : 'No date selected',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_targetDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _targetDate = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar),
                      onPressed: _selectDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveGoal,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
