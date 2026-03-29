import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_item.dart';
import '../providers/task_provider.dart';

class TaskEditScreen extends StatefulWidget {
  final TaskItem? task;
  
  const TaskEditScreen({super.key, this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime _dueDate = DateTime.now();
  String _status = 'To-Do';
  int? _blockedBy;

  bool _isSaving = false;
  bool _isNewTask = true;

  @override
  void initState() {
    super.initState();
    _isNewTask = widget.task == null;
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    
    if (!_isNewTask) {
      _dueDate = widget.task!.dueDate;
      _status = widget.task!.status;
      _blockedBy = widget.task!.blockedBy;
    } else {
      _loadDraft();
    }
    
    // Save draft when text changes
    _titleController.addListener(_saveDraft);
    _descriptionController.addListener(_saveDraft);
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _titleController.text = prefs.getString('draft_title') ?? '';
      _descriptionController.text = prefs.getString('draft_description') ?? '';
      _status = prefs.getString('draft_status') ?? 'To-Do';
      final draftDateStr = prefs.getString('draft_dueDate');
      if (draftDateStr != null) {
        _dueDate = DateTime.parse(draftDateStr);
      }
      final draftBlockedBy = prefs.getInt('draft_blockedBy');
      if (draftBlockedBy != null) {
         final provider = context.read<TaskProvider>();
         final exists = provider.allTasks.any((t) => t.id == draftBlockedBy);
         if (exists) _blockedBy = draftBlockedBy;
      }
    });
  }

  Future<void> _saveDraft() async {
    if (!_isNewTask) return; // Only draft new tasks
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_title', _titleController.text);
    await prefs.setString('draft_description', _descriptionController.text);
    await prefs.setString('draft_status', _status);
    await prefs.setString('draft_dueDate', _dueDate.toIso8601String());
    if (_blockedBy != null) {
      await prefs.setInt('draft_blockedBy', _blockedBy!);
    } else {
      await prefs.remove('draft_blockedBy');
    }
  }

  Future<void> _clearDraft() async {
    if (!_isNewTask) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_title');
    await prefs.remove('draft_description');
    await prefs.remove('draft_status');
    await prefs.remove('draft_dueDate');
    await prefs.remove('draft_blockedBy');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isSaving = true; });

    final provider = context.read<TaskProvider>();
    
    final newTask = TaskItem(
      id: widget.task?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate,
      status: _status,
      blockedBy: _blockedBy,
    );

    try {
      if (_isNewTask) {
        await provider.addTask(newTask);
        await _clearDraft();
      } else {
        await provider.updateTask(newTask);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final availableTasks = provider.allTasks.where((t) => t.id != widget.task?.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewTask ? 'Create Task' : 'Edit Task'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 4,
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    title: const Text('Due Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_dueDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != _dueDate) {
                        setState(() { _dueDate = picked; });
                        _saveDraft();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: _status,
                    items: ['To-Do', 'In Progress', 'Done']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() { _status = val; });
                        _saveDraft();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (availableTasks.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      decoration: InputDecoration(
                          labelText: 'Blocked By (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      value: _blockedBy,
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('None')),
                        ...availableTasks.map((t) => DropdownMenuItem<int?>(
                          value: t.id,
                          child: Text('${t.title} (${t.status})'),
                        )),
                      ],
                      onChanged: (val) {
                        setState(() { _blockedBy = val; });
                        _saveDraft();
                      },
                      isExpanded: true,
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Task', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
            ),
        ],
      ),
    );
  }
}
