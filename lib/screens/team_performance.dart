import 'package:flutter/material.dart';

class TeamPerformanceScreen extends StatefulWidget {
  const TeamPerformanceScreen({super.key});

  @override
  State<TeamPerformanceScreen> createState() => _TeamPerformanceScreenState();
}

class _TeamPerformanceScreenState extends State<TeamPerformanceScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  // --- mock performance data (counts of tasks by bucket) ---
  final List<_MemberPerf> _all = [
    _MemberPerf('Jane Doe', before: 6, on: 3, over: 1),
    _MemberPerf('John Smith', before: 1, on: 6, over: 2),
    _MemberPerf('Maya Singh', before: 2, on: 2, over: 6),
    _MemberPerf('Oliver Jones', before: 0, on: 2, over: 0),
    _MemberPerf('Ethan Brown', before: 3, on: 3, over: 1),
  ];

  _Period _period = _Period.week;
  String _query = '';
  _Sort _sort = _Sort.bestFirst;

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilters(_all);
    final team = filtered.fold<_Buckets>(_Buckets(), (a, m) => a + m.buckets);
    final total = team.total == 0 ? 1 : team.total;

    String pct(int n) => '${(n / total * 100).toStringAsFixed(0)}%';
    final teamBadge = _badgeFromBuckets(team);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Performance'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period + Search + Sort
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<_Period>(
                  value: _period,
                  isExpanded: true,
                  decoration: _fieldDecoration('Period'),
                  items: const [
                    DropdownMenuItem(
                      value: _Period.week,
                      child: Text('This Week'),
                    ),
                    DropdownMenuItem(
                      value: _Period.month,
                      child: Text('This Month'),
                    ),
                    DropdownMenuItem(
                      value: _Period.quarter,
                      child: Text('This Quarter'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _period = v ?? _Period.week),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search teammate',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<_Sort>(
                value: _sort,
                items: const [
                  DropdownMenuItem(
                    value: _Sort.bestFirst,
                    child: Text('Best first'),
                  ),
                  DropdownMenuItem(
                    value: _Sort.mostTasks,
                    child: Text('Most tasks'),
                  ),
                  DropdownMenuItem(value: _Sort.aToZ, child: Text('A → Z')),
                ],
                onChanged: (v) => setState(() => _sort = v ?? _Sort.bestFirst),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Team KPIs
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpi('Great (before due)', pct(team.before), '😄'),
              _kpi('Good (on due date)', pct(team.on), '🙂'),
              _kpi('Horrible (overdue)', pct(team.over), '😫'),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Text(
                teamBadge.$2,
                style: const TextStyle(fontSize: 28),
              ),
              title: const Text('Overall'),
              subtitle: Text(
                'Before: ${team.before} • On: ${team.on} • Over: ${team.over}',
              ),
              trailing: Text(
                teamBadge.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Members
          if (filtered.isEmpty)
            _empty('No teammates match your filters.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = filtered[i];
                final b = _badgeFromBuckets(m.buckets);

                return ListTile(
                  leading: CircleAvatar(child: Text(m.initials)),
                  title: Text(m.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Before ${m.before} • On ${m.on} • Over ${m.over}'),
                      const SizedBox(height: 6),
                      _stackBar(before: m.before, on: m.on, over: m.over),
                    ],
                  ),
                  trailing: Text(
                    b.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    // TODO: navigate to this member’s tasks if you add a detail screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${m.name}: ${b.label}')),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  // ----- helpers -----

  List<_MemberPerf> _applyFilters(List<_MemberPerf> data) {
    Iterable<_MemberPerf> it = data;
    if (_query.isNotEmpty) {
      it = it.where((m) => m.name.toLowerCase().contains(_query));
    }
    var list = it.toList();

    switch (_sort) {
      case _Sort.bestFirst:
        list.sort(
          (a, b) => _score(b).compareTo(_score(a)),
        ); // higher score first
        break;
      case _Sort.mostTasks:
        list.sort((a, b) => b.total.compareTo(a.total));
        break;
      case _Sort.aToZ:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }
    return list;
  }

  // Score: reward "before", then "on", penalize "over"
  int _score(_MemberPerf m) => (m.before * 2) + (m.on) - (m.over * 3);

  (String label, String emoji) _badgeFromBuckets(_Buckets b) {
    final t = b.total;
    if (t == 0) return ('No data', '🙂');
    final bp = b.before / t;
    final op = b.on / t;
    if (bp >= 0.5) return ('Great', '😄'); // many before due date
    if (op >= 0.5) return ('Good', '🙂'); // many on due date
    return ('Horrible', '😫'); // otherwise overdue dominates
  }

  static InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _kpi(String label, String value, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
        boxShadow: kElevationToShadow[1],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(child: Text(text)),
    );
  }

  /// Simple stacked progress bar: before (green), on (blue/grey), over (red)
  Widget _stackBar({required int before, required int on, required int over}) {
    final t = (before + on + over).clamp(1, 1 << 30);
    final bw = before / t;
    final ow = on / t;
    final rw = over / t;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Expanded(
            flex: (bw * 1000).round(),
            child: Container(height: 8, color: Colors.green),
          ),
          Expanded(
            flex: (ow * 1000).round(),
            child: Container(height: 8, color: Colors.blueGrey),
          ),
          Expanded(
            flex: (rw * 1000).round(),
            child: Container(height: 8, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

extension on (String, String) {
  String get label => this.$1;
}

/* ------------------- tiny models ------------------- */

class _MemberPerf {
  final String name;
  final int before; // completed before due date
  final int on; // completed on due date
  final int over; // completed after due date
  _MemberPerf(
    this.name, {
    required this.before,
    required this.on,
    required this.over,
  });
  int get total => before + on + over;

  _Buckets get buckets => _Buckets()
    ..before = before
    ..on = on
    ..over = over;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _Buckets {
  int before = 0, on = 0, over = 0;
  int get total => before + on + over;
  _Buckets();
  _Buckets operator +(_Buckets b) {
    final n = _Buckets();
    n.before = before + b.before;
    n.on = on + b.on;
    n.over = over + b.over;
    return n;
  }
}

enum _Period { week, month, quarter }

enum _Sort { bestFirst, mostTasks, aToZ }

