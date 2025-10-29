import 'package:flutter/material.dart';

class ActiveProjectsScreen extends StatelessWidget {
  const ActiveProjectsScreen({super.key});

  // Helper to get a dynamic color for light/dark mode
  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return isDarkMode ? Colors.blueAccent : const Color(0xFF182D53);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = _getDynamicColor(context);
    final mainBlue = const Color(0xFF182D53);
    // Mock data
    final managers = [
      _Person('Ava Williams', 8),
      _Person('Noah Patel', 2),
      _Person('Liam Chen', 5),
      _Person('Sofia Gomez', 0),
    ];
    final employees = [
      _Person('Jane Doe', 3),
      _Person('John Smith', 1),
      _Person('Maya Singh', 6),
      _Person('Oliver Jones', 0),
      _Person('Ethan Brown', 2),
    ];
    final totalActive =
        managers.fold<int>(0, (s, p) => s + p.count) +
        employees.fold<int>(0, (s, p) => s + p.count);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Active Projects'),
          backgroundColor: mainBlue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Managers'),
              Tab(text: 'Employees'),
            ],
          ),
        ),
        body: Column(
          children: [
            // KPIs
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _kpi(context, Icons.folder_open, 'Total Active', '$totalActive'),
                  _kpi(
                    context,
                    Icons.supervisor_account_outlined,
                    'Managers',
                    '${managers.length}',
                  ),
                  _kpi(
                    context,
                    Icons.badge_outlined,
                    'Employees',
                    '${employees.length}',
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  _PeopleList(people: managers, emptyText: 'No managers.'),
                  _PeopleList(people: employees, emptyText: 'No employees.'),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          backgroundColor: dynamicColor,
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text('Refresh', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // Using Card for the KPI widget for automatic dark/light theme adaptation
  Widget _kpi(BuildContext context, IconData icon, String label, String value) {
    final dynamicColor = _getDynamicColor(context);
    final theme = Theme.of(context);
    final onCardColor = theme.colorScheme.onSurface;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: dynamicColor),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: onCardColor.withOpacity(0.7)),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onCardColor, // Adapts to theme
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleList extends StatefulWidget {
  const _PeopleList({required this.people, required this.emptyText});
  final List<_Person> people;
  final String emptyText;

  @override
  State<_PeopleList> createState() => _PeopleListState();
}

class _PeopleListState extends State<_PeopleList> {
  String query = '';
  _Sort sort = _Sort.mostActive;

  @override
  Widget build(BuildContext context) {
    final filtered = _apply(widget.people);
    if (filtered.isEmpty) {
      return Column(
        children: [
          _controls(),
          Expanded(child: Center(child: Text(widget.emptyText))),
        ],
      );
    }
    return Column(
      children: [
        _controls(),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = filtered[i];
              final color = p.count == 0
                  ? Colors.grey
                  : (p.count > 5 ? Colors.green : Colors.orange);
              return ListTile(
                leading: CircleAvatar(child: Text(_initials(p.name))),
                title: Text(p.name),
                subtitle: Text(
                  '${p.count} active project${p.count == 1 ? '' : 's'}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withOpacity(.5)),
                  ),
                  child: Text(
                    '${p.count}',
                    style: TextStyle(
                      color: color, // Use base color for better visibility
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Open ${p.name}')));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search names…',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<_Sort>(
            value: sort,
            items: const [
              DropdownMenuItem(
                value: _Sort.mostActive,
                child: Text('Most Active'),
              ),
              DropdownMenuItem(value: _Sort.aToZ, child: Text('A → Z')),
              DropdownMenuItem(value: _Sort.zToA, child: Text('Z → A')),
            ],
            onChanged: (v) => setState(() => sort = v ?? _Sort.mostActive),
          ),
        ],
      ),
    );
  }

  List<_Person> _apply(List<_Person> list) {
    var it = list.where((p) => p.name.toLowerCase().contains(query)).toList();
    switch (sort) {
      case _Sort.mostActive:
        it.sort((a, b) => b.count.compareTo(a.count));
        break;
      case _Sort.aToZ:
        it.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _Sort.zToA:
        it.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
    return it;
  }

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _Person {
  final String name;
  final int count;
  _Person(this.name, this.count);
}

enum _Sort { mostActive, aToZ, zToA }
