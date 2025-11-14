import 'package:flutter/material.dart';
import '../data/supabase_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key, required this.employeeId});
  final int employeeId; // employees.id to assign to

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _form = GlobalKey<FormState>();
  String _title = '';
  String? _desc;
  DateTime? _due;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                onSaved: (v) => _title = v!.trim(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                onSaved: (v) =>
                    _desc = v?.trim().isEmpty == true ? null : v?.trim(),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _due == null ? 'No due date' : 'Due: ${_due!.toLocal()}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDue,
                    child: const Text('Pick due date'),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _due = d);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();
    setState(() => _submitting = true);
    try {
      await SupabaseService.createTask(
        title: _title,
        description: _desc,
        assignedToEmployeeId: widget.employeeId,
        dueDate: _due,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
