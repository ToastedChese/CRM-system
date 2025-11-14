import 'dart:async';
import 'package:flutter/material.dart';
import '../data/supabase_service.dart';

class ProjectCreateScreen extends StatefulWidget {
  const ProjectCreateScreen({super.key});
  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  int _step = 0;
  bool _submitting = false;

  // Step 1 – customer
  List<Map<String, dynamic>> _customers = [];
  Map<String, dynamic>? _selectedCustomer;

  // Step 2 – details
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _dueDate;
  String _status = 'active';

  // Step 3 – assignments
  final _managerIds = <String>{};
  final _employeeIds = <String>{};
  final _managerChips = <_UserChip>[];
  final _employeeChips = <_UserChip>[];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final rows = await SupabaseService.customersLite();
      setState(() => _customers = rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load customers failed: $e')));
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDate: (start ? _startDate : _dueDate) ?? now,
    );
    if (picked != null) {
      setState(() => start ? _startDate = picked : _dueDate = picked);
    }
  }

  bool get _canNextFromCustomer => _selectedCustomer != null;
  bool get _canNextFromDetails => _nameCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canNextFromDetails || !_canNextFromCustomer) return;
    setState(() => _submitting = true);
    try {
      final proj = await SupabaseService.createProject(
        customerId:
            (_selectedCustomer!['customer_id'] ?? _selectedCustomer!['id'])
                as int,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        startsAt: _startDate,
        dueDate: _dueDate,
        status: _status,
      );

      await SupabaseService.addAssignments(
        projectId: proj['id'] as int,
        managerUserIds: _managerIds.toList(),
        employeeUserIds: _employeeIds.toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Project created')));
      Navigator.pop(context, proj);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildCustomerStep(),
      _buildDetailsStep(),
      _buildAssignStep(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Project'),
        backgroundColor: const Color.fromARGB(255, 19, 35, 66),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Step header bound to _step
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _StepDot(index: 0, active: _step == 0, label: 'Customer'),
                const Expanded(child: Divider()),
                _StepDot(index: 1, active: _step == 1, label: 'Details'),
                const Expanded(child: Divider()),
                _StepDot(index: 2, active: _step == 2, label: 'Assign'),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: steps[_step],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (_step > 0)
              OutlinedButton.icon(
                icon: const Icon(Icons.chevron_left),
                label: const Text('Back'),
                onPressed: _submitting
                    ? null
                    : () => setState(() => _step -= 1),
              ),
            if (_step > 0) const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                icon: _step < 2
                    ? const Icon(Icons.chevron_right)
                    : const Icon(Icons.check),
                label: Text(_step < 2 ? 'Next' : 'Create'),
                onPressed: _submitting
                    ? null
                    : () {
                        if (_step == 0 && _canNextFromCustomer) {
                          setState(() => _step = 1);
                        } else if (_step == 1 && _canNextFromDetails) {
                          setState(() => _step = 2);
                        } else if (_step == 2) {
                          _submit();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── Step 1: Customer ─────────────
  Widget _buildCustomerStep() {
    return Padding(
      key: const ValueKey('customer'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Section(title: 'Select Customer', icon: Icons.business),
          const SizedBox(height: 8),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedCustomer,
            items: _customers
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(_customerLabel(c)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedCustomer = v),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Choose a customer…',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Quick add customer'),
              onPressed: _quickAddCustomer,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  String _customerLabel(Map<String, dynamic> c) {
    final fn = (c['first_name'] ?? '').toString();
    final ln = (c['last_name'] ?? '').toString();
    final em = (c['email'] ?? '').toString();
    final name = (fn + ' ' + ln).trim();
    return name.isEmpty ? em : '$name · $em';
  }

  Future<void> _quickAddCustomer() async {
    final first = TextEditingController();
    final last = TextEditingController();
    final email = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quick Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: first,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            TextField(
              controller: last,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final row = await SupabaseService.createCustomerQuick(
          firstName: first.text,
          lastName: last.text,
          email: email.text,
        );
        await _loadCustomers();
        setState(() => _selectedCustomer = row);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Add customer failed: $e')));
      }
    }
  }

  // ───────────── Step 2: Details ─────────────
  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      key: const ValueKey('details'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Section(title: 'Project Details', icon: Icons.description),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Project name *',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Start date',
                  value: _startDate,
                  onTap: () => _pickDate(start: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'Due date',
                  value: _dueDate,
                  onTap: () => _pickDate(start: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'active'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Status',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Required fields are marked *',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Step 3: Assign ─────────────
  Widget _buildAssignStep() {
    return SingleChildScrollView(
      key: const ValueKey('assign'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(title: 'Assign People', icon: Icons.group_add),
          const SizedBox(height: 8),
          _AssignRow(
            label: 'Managers',
            chips: _managerChips,
            onAdd: () => _openDirectoryPicker(
              onPicked: (u) {
                if (_managerIds.add(u.id)) {
                  setState(() => _managerChips.add(u));
                }
              },
            ),
            onRemove: (u) {
              setState(() {
                _managerIds.remove(u.id);
                _managerChips.removeWhere((c) => c.id == u.id);
              });
            },
          ),
          const SizedBox(height: 12),
          _AssignRow(
            label: 'Employees',
            chips: _employeeChips,
            onAdd: () => _openDirectoryPicker(
              onPicked: (u) {
                if (_employeeIds.add(u.id)) {
                  setState(() => _employeeChips.add(u));
                }
              },
            ),
            onRemove: (u) {
              setState(() {
                _employeeIds.remove(u.id);
                _employeeChips.removeWhere((c) => c.id == u.id);
              });
            },
          ),
          const SizedBox(height: 100),
          if (_submitting) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _openDirectoryPicker({
    required void Function(_UserChip picked) onPicked,
  }) async {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    Timer? debounce;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search people by name or email…',
                ),
                onChanged: (_) {
                  debounce?.cancel();
                  debounce = Timer(const Duration(milliseconds: 250), () async {
                    results = await SupabaseService.searchDirectory(
                      searchCtrl.text.trim(),
                    );
                    setLocal(() {});
                  });
                },
              ),
              const SizedBox(height: 8),
              Flexible(
                child: results.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Type to search…',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final r = results[i];
                          final chip = _UserChip(
                            id: (r['user_id'] ?? '').toString(),
                            name: (r['display_name'] ?? r['email'] ?? 'Unknown')
                                .toString(),
                            email: (r['email'] ?? '').toString(),
                            avatarUrl: (r['avatar_url'] ?? '').toString(),
                          );
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: chip.avatarUrl.isNotEmpty
                                  ? NetworkImage(chip.avatarUrl)
                                  : null,
                              child: chip.avatarUrl.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(chip.name),
                            subtitle: Text(chip.email),
                            onTap: () {
                              onPicked(chip);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── UI helpers ─────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF182D53)),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, this.value, required this.onTap});
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? ''
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(text.isEmpty ? 'Select…' : text),
      ),
    );
  }
}

class _AssignRow extends StatelessWidget {
  const _AssignRow({
    required this.label,
    required this.chips,
    required this.onAdd,
    required this.onRemove,
  });
  final String label;
  final List<_UserChip> chips;
  final VoidCallback onAdd;
  final void Function(_UserChip) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...chips.map(
              (c) => InputChip(
                avatar: CircleAvatar(
                  backgroundImage: c.avatarUrl.isNotEmpty
                      ? NetworkImage(c.avatarUrl)
                      : null,
                  child: c.avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                label: Text(c.name),
                onDeleted: () => onRemove(c),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add),
              label: const Text('Add'),
              onPressed: onAdd,
            ),
          ],
        ),
      ],
    );
  }
}

class _UserChip {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  _UserChip({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.active,
    required this.label,
  });
  final int index;
  final bool active;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = active ? const Color(0xFF182D53) : Colors.grey;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: c,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: c)),
      ],
    );
  }
}
