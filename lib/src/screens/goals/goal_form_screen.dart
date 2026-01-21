import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../services/goal_repository.dart';

class GoalFormScreen extends StatefulWidget {
  final Goal? goal;

  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalRepository = GoalRepository();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  GoalType _type = GoalType.corporate;
  GoalStatus _status = GoalStatus.notStarted;
  DateTime? _targetDate;

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
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() {
        _targetDate = date;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    Goal goal;
    if (_isEditing) {
      goal = widget.goal!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _type,
        status: _status,
        targetDate: _targetDate,
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
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Goal' : 'New Goal'),
      ),
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
              Text(
                'Type',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<GoalType>(
                segments: const [
                  ButtonSegment(
                    value: GoalType.corporate,
                    label: Text('Corporate'),
                    icon: Icon(Icons.business),
                  ),
                  ButtonSegment(
                    value: GoalType.entrepreneurial,
                    label: Text('Entrepreneurial'),
                    icon: Icon(Icons.lightbulb_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Status',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: GoalStatus.values.map((status) {
                  return ChoiceChip(
                    label: Text(_statusLabel(status)),
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
              Text(
                'Target Date',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _targetDate != null
                      ? _formatDate(_targetDate!)
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
                  onPressed: _saveGoal,
                  child: Text(_isEditing ? 'Save Changes' : 'Create Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(GoalStatus status) {
    switch (status) {
      case GoalStatus.notStarted:
        return 'Not Started';
      case GoalStatus.inProgress:
        return 'In Progress';
      case GoalStatus.completed:
        return 'Completed';
      case GoalStatus.abandoned:
        return 'Abandoned';
    }
  }
}
