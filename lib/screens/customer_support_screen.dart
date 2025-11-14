import 'package:flutter/material.dart';
import '../data/supabase_service.dart';

class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _isSubmitting = false;
  String _selectedRole = 'employee';
  List<Map<String, dynamic>> _assignees = [];
  int? _selectedAssigneeId;

  @override
  void initState() {
    super.initState();
    _loadAssignees();
  }

  Future<void> _loadAssignees() async {
    try {
      if (_selectedRole == 'employee') {
        _assignees = await SupabaseService.employeesLite();
      } else {
        _assignees = await SupabaseService.managersLite();
      }
      setState(() => _selectedAssigneeId = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedAssigneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all fields and pick assignee.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final customerId = await SupabaseService.getMyCustomerId();
      if (customerId == null) {
        throw Exception('No customer profile linked to this account.');
      }

      await SupabaseService.createServiceTicket(
        customerId: customerId,
        issueDescription: '[${_subjectCtrl.text}] ${_messageCtrl.text.trim()}',
        employeeId: _selectedRole == 'employee' ? _selectedAssigneeId : null,
        managerId: _selectedRole == 'manager' ? _selectedAssigneeId : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support request submitted!')),
      );
      _formKey.currentState!.reset();
      setState(() => _selectedAssigneeId = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contact Support',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: mainBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How can we help?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter a subject.' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _messageCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter a message.' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Assign to (role)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedRole = v);
                  _loadAssignees();
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _selectedAssigneeId,
                decoration: const InputDecoration(
                  labelText: 'Assign to',
                  border: OutlineInputBorder(),
                ),
                items: _assignees.map((e) {
                  final id = _selectedRole == 'employee'
                      ? e['employee_id'] as int
                      : e['id'] as int;
                  final name =
                      '${e['first_name'] ?? ''} ${e['last_name'] ?? ''}'.trim();
                  return DropdownMenuItem<int>(value: id, child: Text(name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedAssigneeId = v),
                validator: (v) =>
                    v == null ? 'Please select an assignee' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Request',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

