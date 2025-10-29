import 'package:flutter/material.dart';

class CustomerSatisfactionScreen extends StatefulWidget {
  const CustomerSatisfactionScreen({super.key});

  @override
  State<CustomerSatisfactionScreen> createState() =>
      _CustomerSatisfactionScreenState();
}

class _CustomerSatisfactionScreenState
    extends State<CustomerSatisfactionScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  // ---------- mock ratings (replace with your API later) ----------
  final List<_Rating> _all = [
    _Rating(
      'TechCorp',
      'Install',
      5,
      DateTime.now().subtract(const Duration(hours: 2)),
    ),
    _Rating(
      'Innovate LLC',
      'Upgrade',
      4,
      DateTime.now().subtract(const Duration(days: 1)),
    ),
    _Rating(
      'Global Solutions',
      'Repair',
      3,
      DateTime.now().subtract(const Duration(days: 2)),
    ),
    _Rating(
      'Contoso',
      'Audit',
      5,
      DateTime.now().subtract(const Duration(days: 6)),
    ),
    _Rating(
      'Tailwind',
      'Consult',
      2,
      DateTime.now().subtract(const Duration(days: 10)),
    ),
    _Rating(
      'Northwind',
      'Support',
      4,
      DateTime.now().subtract(const Duration(days: 15)),
    ),
    _Rating(
      'Acme',
      'Install',
      1,
      DateTime.now().subtract(const Duration(days: 25)),
    ),
  ];

  _Period _period = _Period.month;
  DateTimeRange? _custom;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilters(_all);
    final totalPoints = filtered.fold<int>(0, (s, r) => s + r.rating);
    final count = filtered.length;
    final avg = count == 0 ? 0.0 : totalPoints / count;

    final bucket = _bucket(totalPoints); // (label, emoji)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Satisfaction'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Period + Search
          Row(
            children: [
              Expanded(
                child: _PeriodPicker(
                  period: _period,
                  custom: _custom,
                  onChanged: _onPeriodChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search customer or service',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big status card
          Card(
            elevation: 2,
            child: ListTile(
              leading: Text(bucket.$2, style: const TextStyle(fontSize: 32)),
              title: Text('Total Points: $totalPoints'),
              subtitle: Text(
                'Ratings: $count  •  Avg: ${avg.toStringAsFixed(2)}/5',
              ),
              trailing: Text(
                bucket.$1,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Small KPI chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpi(
                Icons.star_rate_rounded,
                '5-star count',
                '${filtered.where((r) => r.rating == 5).length}',
              ),
              _kpi(
                Icons.sentiment_satisfied_alt_outlined,
                '≥4 ratings',
                '${filtered.where((r) => r.rating >= 4).length}',
              ),
              _kpi(
                Icons.flag_outlined,
                '≤2 ratings',
                '${filtered.where((r) => r.rating <= 2).length}',
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Latest Ratings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          if (filtered.isEmpty)
            _empty('No ratings for the selected period.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = filtered[i];
                return ListTile(
                  leading: _ratingPill(r.rating),
                  title: Text('${r.customer} • ${r.service}'),
                  subtitle: Text(_fmt(r.time)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: push to a rating details screen if you add one
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Rating ${r.rating}/5 from ${r.customer}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: mainBlue,
        onPressed: () => setState(() {}), // mock refresh
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }

  // ---------------- helpers ----------------

  List<_Rating> _applyFilters(List<_Rating> items) {
    final range = switch (_period) {
      _Period.week => _thisWeek(),
      _Period.month => _thisMonth(),
      _Period.custom => _custom ?? _thisMonth(),
    };
    Iterable<_Rating> it = items.where(
      (r) => r.time.isAfter(range.start) && r.time.isBefore(range.end),
    );
    if (_query.isNotEmpty) {
      it = it.where(
        (r) =>
            r.customer.toLowerCase().contains(_query) ||
            r.service.toLowerCase().contains(_query),
      );
    }
    final list = it.toList()..sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  void _onPeriodChanged(_Period p, DateTimeRange? custom) {
    setState(() {
      _period = p;
      _custom = custom;
    });
  }

  (String, String) _bucket(int totalPoints) {
    // your thresholds:
    // ≤15 -> Bad 😡  |  16..50 -> Average 😐  |  >50..100 -> Good/Great 😄
    if (totalPoints <= 15) return ('Bad', '😡');
    if (totalPoints <= 50) return ('Average', '😐');
    return ('Great', '😄');
  }

  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  // date ranges
  DateTimeRange _thisWeek() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final start = startOfDay.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return DateTimeRange(start: start, end: end);
  }

  DateTimeRange _thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return DateTimeRange(start: start, end: end);
  }

  Widget _kpi(IconData icon, String label, String value) {
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
          Icon(icon),
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

  Widget _ratingPill(int r) {
    final color = r >= 4
        ? Colors.green
        : r >= 3
        ? Colors.orange
        : Colors.red;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Text(
        '$r',
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _empty(String message) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// -------- period picker widget --------

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({
    required this.period,
    required this.custom,
    required this.onChanged,
  });

  final _Period period;
  final DateTimeRange? custom;
  final void Function(_Period, DateTimeRange?) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<_Period>(
      value: period,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Period',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: _Period.week, child: Text('This Week')),
        DropdownMenuItem(value: _Period.month, child: Text('This Month')),
        DropdownMenuItem(value: _Period.custom, child: Text('Custom…')),
      ],
      onChanged: (p) async {
        if (p == null) return;
        if (p != _Period.custom) {
          onChanged(p, null);
        } else {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(now.year - 2),
            lastDate: DateTime(now.year + 2),
            initialDateRange: DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: DateTime(now.year, now.month + 1, 1),
            ),
          );
          if (picked != null) {
            onChanged(_Period.custom, picked);
          }
        }
      },
    );
  }
}

// -------- tiny models --------

class _Rating {
  final String customer;
  final String service;
  final int rating; // 1..5
  final DateTime time;
  _Rating(this.customer, this.service, this.rating, this.time);
}

enum _Period { week, month, custom }
