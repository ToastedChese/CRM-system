import 'package:flutter/material.dart';
import '../data/supabase_service.dart' as svc;

class TasksScreen extends StatefulWidget {
  final List<svc.Task>? assignedTasks; // optional tasks passed from dashboard

  const TasksScreen({super.key, this.assignedTasks});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  static const Color mainBlue = Color(0xFF182D53);
  late Future<List<svc.Task>> _future;
  bool _amManager = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.assignedTasks != null) {
      // Use tasks passed from dashboard
      _future = Future.value(widget.assignedTasks);
    } else {
      // Otherwise fetch from Supabase
      _future = svc.SupabaseService.myTasks();
    }

    // Show a FAB only for managers
    final isMgr = await svc.SupabaseService.amIManager();
    if (mounted) setState(() => _amManager = isMgr);
  }

  Future<void> _reload() async => _load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<svc.Task>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _Error(message: snap.error.toString(), onRetry: _reload);
          }
          final items = snap.data ?? const <svc.Task>[];
          if (items.isEmpty) return const Center(child: Text('No tasks yet.'));

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = items[i];
                final due = t.dueDate != null
                    ? ' • Due ${_fmt(t.dueDate!)}'
                    : '';
                return ListTile(
                  leading: const Icon(Icons.checklist_outlined),
                  title: Text(t.title),
                  subtitle: Text('${t.status}$due'),
                  // onTap: () => Navigator.push(... to a TaskDetail screen),
                );
              },
            ),
          );
        },
      ),
      // show a create button only if user is a manager
      floatingActionButton: _amManager
          ? FloatingActionButton.extended(
              backgroundColor: mainBlue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Task',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                // Add new task logic here
              },
            )
          : null,
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
