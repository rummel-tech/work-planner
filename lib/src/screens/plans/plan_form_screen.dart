import '../../services/service_locator.dart';
import 'package:flutter/material.dart';

import '../../models/plan.dart';
import '../../utils/enum_labels.dart';
class PlanFormScreen extends StatefulWidget {
  final Plan? plan;
  final String? goalId;

  const PlanFormScreen({super.key, this.plan, this.goalId});

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planRepository = ServiceLocator.plans;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  PlanStatus _status = PlanStatus.draft;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _titleController.text = widget.plan!.title;
      _descriptionController.text = widget.plan!.description;
      _status = widget.plan!.status;
      _startDate = widget.plan!.startDate;
      _endDate = widget.plan!.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: _isEditing
          ? DateTime(2000)
          : today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fallbackFirst = _isEditing ? DateTime(2000) : today;
    final firstDate = _startDate ?? fallbackFirst;
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? today,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    setState(() => _saving = true);

    try {
      Plan plan;
      if (_isEditing) {
        plan = widget.plan!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          startDate: _startDate,
          clearStartDate: _startDate == null,
          endDate: _endDate,
          clearEndDate: _endDate == null,
        );
      } else {
        final goalId = widget.goalId;
        if (goalId == null) {
          throw StateError('goalId is required when creating a new plan');
        }
        plan = Plan.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          goalId: goalId,
          status: _status,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      await _planRepository.save(plan);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save plan: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Plan' : 'New Plan')),
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
                  hintText: 'Enter plan title',
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
                  hintText: 'Enter plan description',
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
              Text('Status', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PlanStatus.values.map((status) {
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
              Text('Date Range', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _selectStartDate,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _startDate != null
                                        ? _formatDate(_startDate!)
                                        : 'Select',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _endDate != null
                                        ? _formatDate(_endDate!)
                                        : 'Select',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_startDate != null || _endDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    child: const Text('Clear Dates'),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _savePlan,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save Changes' : 'Create Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
