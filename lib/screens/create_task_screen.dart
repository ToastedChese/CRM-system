import 'package:flutter/material.dart';
import '../data/supabase_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final int? employeeId; // Optional preselected employee

  const CreateTaskScreen({Key? key, this.employeeId}) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _form = GlobalKey<FormState>();
  String _title = '';
  String? _desc;
  DateTime? _due;
  bool _submitting = false;

  int? _selectedEmployeeId;
  List<Map<String, dynamic>> _employees = [];
  bool _loadingEmployees = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await SupabaseService.employeesLite();
      setState(() {
        _employees = employees;
        _loadingEmployees = false;

        // Preselect employee if passed from constructor
        if (widget.employeeId != null &&
            _employees.any((e) => e['employee_id'] == widget.employeeId)) {
          _selectedEmployeeId = widget.employeeId;
        }
      });
    } catch (e) {
      setState(() => _loadingEmployees = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load employees: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loadingEmployees
            ? const Center(child: CircularProgressIndicator())
            : Form(
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
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                          labelText: 'Assign to Employee'),
                      value: _selectedEmployeeId, // Preselect if provided
                      items: _employees
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['employee_id'] as int,
                              child: Text('${e['first_name']} ${e['last_name']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedEmployeeId = v),
                      validator: (v) =>
                          v == null ? 'Please select an employee' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _due == null
                                ? 'No due date'
                                : 'Due: ${_due!.toLocal().toString().split(' ')[0]}',
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
      firstDate: now,
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
        assignedToEmployeeId: _selectedEmployeeId!,
        dueDate: _due,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
