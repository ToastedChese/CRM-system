import 'package:flutter/material.dart';

class NewLeadsScreen extends StatelessWidget {
  const NewLeadsScreen({super.key});

  static const Color mainBlue = Color(0xFF182D53);

  @override
  Widget build(BuildContext context) {
    // Mock leads (you can change freely)
    final allLeads = <_Lead>[
      _Lead('Website form', 'Web', DateTime.now()),
      _Lead(
        'Referral: ACME',
        'Referral',
        DateTime.now().subtract(const Duration(days: 1)),
      ),
      _Lead(
        'LinkedIn DM',
        'LinkedIn',
        DateTime.now().subtract(const Duration(days: 2)),
      ),
      _Lead(
        'Cold call: TechCorp',
        'Phone',
        DateTime.now().subtract(const Duration(days: 4)),
      ),
      _Lead(
        'Email inbound: Contoso',
        'Email',
        DateTime.now().subtract(const Duration(days: 6)),
      ),
      _Lead(
        'Conference Booth',
        'Event',
        DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];

    return DefaultTabController(
      // <-- provides a TabController for both TabBar + TabBarView
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Leads', style: TextStyle(color: Colors.white)),
          backgroundColor: mainBlue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'This Week'),
              Tab(text: 'By Month'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: _NewLeadsBody(allLeads: allLeads),
      ),
    );
  }
}

class _NewLeadsBody extends StatefulWidget {
  const _NewLeadsBody({required this.allLeads});
  final List<_Lead> allLeads;

  @override
  State<_NewLeadsBody> createState() => _NewLeadsBodyState();
}

class _NewLeadsBodyState extends State<_NewLeadsBody> {
  static const Color mainBlue = Color(0xFF182D53);
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final week = _filterWeek(widget.allLeads);
    final month = _filterMonth(widget.allLeads, _month);

    return Column(
      children: [
        // top padding so lists aren't jammed against the edge
        const SizedBox(height: 8),

        // The TabBarView must be constrained -> Expanded avoids bottom overflow
        Expanded(
          child: TabBarView(
            children: [
              // -------- This Week --------
              _LeadsList(leads: week, emptyText: 'No new leads this week.'),

              // -------- By Month --------
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _label(_month),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: mainBlue,
                            ),
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: mainBlue,
                          ),
                          onPressed: _pickMonth,
                          child: const Text('Choose Month'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _LeadsList(
                      leads: month,
                      emptyText: 'No leads for ${_label(_month)}.',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(now.year - 2, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Pick any day in the month',
    );
    if (selected != null) {
      setState(() => _month = DateTime(selected.year, selected.month));
    }
  }

  // -------- helpers --------
  static String _label(DateTime m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[m.month - 1]} ${m.year}';
  }

  static List<_Lead> _filterWeek(List<_Lead> it) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1)); // Mon
    final end = start.add(const Duration(days: 7));
    return it
        .where((l) => l.time.isAfter(start) && l.time.isBefore(end))
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  static List<_Lead> _filterMonth(List<_Lead> it, DateTime m) {
    final start = DateTime(m.year, m.month, 1);
    final end = DateTime(m.year, m.month + 1, 1);
    return it
        .where((l) => l.time.isAfter(start) && l.time.isBefore(end))
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }
}

// ---------- simple list widget ----------
class _LeadsList extends StatelessWidget {
  const _LeadsList({required this.leads, required this.emptyText});
  final List<_Lead> leads;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: leads.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final l = leads[i];
        return ListTile(
          leading: const Icon(Icons.person_add_alt_1_outlined),
          title: Text(l.name),
          subtitle: Text('${l.source} • ${_fmt(l.time)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        );
      },
    );
  }

  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

// ---------- tiny model ----------
class _Lead {
  final String name, source;
  final DateTime time;
  _Lead(this.name, this.source, this.time);
}
