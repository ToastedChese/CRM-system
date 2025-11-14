// lib/screens/meetings_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../data/supabase_service.dart' as svc;

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  static const Color mainBlue = Color(0xFF182D53);
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = svc.SupabaseService.meetingsUpcoming();
  }

  Future<void> _reload() async {
    setState(() => _future = svc.SupabaseService.meetingsUpcoming());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Error(message: snap.error.toString(), onRetry: _reload);
          }
          final items = snap.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return const Center(child: Text('No upcoming meetings.'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = items[i];
                final dt = _parseDt(m['date_time']);
                return ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text(m['title']?.toString() ?? 'Meeting'),
                  subtitle: Text(
                    dt == null
                        ? ''
                        : intl.DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(dt.toLocal()),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MeetingEditorScreen(
                          meetingId: (m['id'] as num).toInt(),
                        ),
                      ),
                    );
                    await _reload();
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Meeting'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MeetingEditorScreen()),
          );
          await _reload();
        },
      ),
    );
  }

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

class MeetingEditorScreen extends StatefulWidget {
  const MeetingEditorScreen({super.key, this.meetingId});
  final int? meetingId;

  @override
  State<MeetingEditorScreen> createState() => _MeetingEditorScreenState();
}

class _MeetingEditorScreenState extends State<MeetingEditorScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));

  int? _organizerEmployeeId;
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendance = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    if (widget.meetingId != null) {
      _loadMeeting(widget.meetingId!);
      _loadAttendance(widget.meetingId!);
    } else {
      _primeOrganizer();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _primeOrganizer() async {
    final me = await svc.SupabaseService.myEmployeeId();
    setState(() => _organizerEmployeeId = me);
  }

  Future<void> _loadEmployees() async {
    final rows = await svc.SupabaseService.employeesLite();
    setState(() => _employees = rows);
  }

  Future<void> _loadMeeting(int id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final m = await svc.SupabaseService.meetingById(id);
      _titleCtrl.text = (m['title'] ?? '').toString();
      _organizerEmployeeId = (m['organizer'] as num?)?.toInt();
      final dt = _parseDt(m['date_time']);
      if (dt != null) _dateTime = dt.toLocal();
      if (m['description'] != null)
        _descCtrl.text = m['description'].toString();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAttendance(int meetingId) async {
    final rows = await svc.SupabaseService.attendeesByMeeting(meetingId);
    setState(() => _attendance = rows);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_organizerEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an organizer')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.meetingId == null) {
        final row = await svc.SupabaseService.createMeeting(
          title: _titleCtrl.text,
          dateTime: _dateTime,
          organizerEmployeeId: _organizerEmployeeId!,
          description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
        );
        await _loadAttendance((row['id'] as num).toInt());
      } else {
        await svc.SupabaseService.updateMeeting(
          id: widget.meetingId!,
          title: _titleCtrl.text,
          dateTime: _dateTime,
          organizerEmployeeId: _organizerEmployeeId!,
          description: _descCtrl.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _empName(Map<String, dynamic> e) {
    final f = (e['first_name'] ?? '').toString();
    final l = (e['last_name'] ?? '').toString();
    return (f.isEmpty && l.isEmpty) ? 'Employee #${e['employee_id']}' : '$f $l';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.meetingId != null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Meeting' : 'New Meeting'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleCtrl,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule),
                        title: Text(
                          intl.DateFormat(
                            'yyyy-MM-dd HH:mm',
                          ).format(_dateTime.toLocal()),
                        ),
                        trailing: TextButton(
                          child: const Text('Pick'),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _dateTime,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d == null) return;
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_dateTime),
                            );
                            if (t == null) return;
                            setState(() {
                              _dateTime = DateTime(
                                d.year,
                                d.month,
                                d.day,
                                t.hour,
                                t.minute,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: _organizerEmployeeId,
                        decoration: const InputDecoration(
                          labelText: 'Organizer',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('— Select organizer —'),
                          ),
                          ..._employees.map(
                            (e) => DropdownMenuItem<int?>(
                              value: ((e['employee_id'] as num?) ?? 0).toInt(),
                              child: Text(_empName(e)),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _organizerEmployeeId = v;
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 5,
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: const InputDecoration(
                          labelText: 'Description / Summary',
                          hintText: 'Optional meeting notes or summary',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (isEditing) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Attendance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _AttendanceEditor(
                    meetingId: widget.meetingId!,
                    employees: _employees,
                    existing: _attendance,
                    onChanged: (rows) => setState(() => _attendance = rows),
                  ),
                ],
              ],
            ),
            if (_loading)
              const Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  static DateTime? _parseDt(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

class _AttendanceEditor extends StatefulWidget {
  const _AttendanceEditor({
    required this.meetingId,
    required this.employees,
    required this.existing,
    required this.onChanged,
  });

  final int meetingId;
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> existing;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  @override
  State<_AttendanceEditor> createState() => _AttendanceEditorState();
}

class _AttendanceEditorState extends State<_AttendanceEditor> {
  final Map<int, String> _status = {};

  @override
  void initState() {
    super.initState();
    for (final row in widget.existing) {
      _status[(row['employee_id'] as num).toInt()] =
          (row['attendance_status'] ?? '').toString();
    }
  }

  String _name(Map<String, dynamic> e) {
    final f = (e['first_name'] ?? '').toString();
    final l = (e['last_name'] ?? '').toString();
    return (f.isEmpty && l.isEmpty) ? 'Employee #${e['employee_id']}' : '$f $l';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.employees.map((e) {
        final id = (e['employee_id'] as num).toInt();
        final current = _status[id] ?? 'absent';
        return Card(
          child: ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(_name(e)),
            trailing: DropdownButton<String>(
              value: current,
              items: const [
                DropdownMenuItem(value: 'present', child: Text('Present')),
                DropdownMenuItem(value: 'late', child: Text('Late')),
                DropdownMenuItem(value: 'absent', child: Text('Absent')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                await svc.SupabaseService.setAttendance(
                  meetingId: widget.meetingId,
                  employeeId: id,
                  attendanceStatus: v,
                );
                setState(() => _status[id] = v);
                final rows = await svc.SupabaseService.attendeesByMeeting(
                  widget.meetingId,
                );
                widget.onChanged(rows);
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
