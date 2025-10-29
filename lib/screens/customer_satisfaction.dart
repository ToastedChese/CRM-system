import 'package:flutter/material.dart';

class CustomerSatisfactionScreen extends StatefulWidget {
  const CustomerSatisfactionScreen({super.key});

  @override
  State<CustomerSatisfactionScreen> createState() =>
      _CustomerSatisfactionScreenState();
}

class _CustomerSatisfactionScreenState
    extends State<CustomerSatisfactionScreen> {

  // Helper to get a dynamic color for light/dark mode
  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return isDarkMode ? Colors.blueAccent : const Color(0xFF182D53);
  }

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
    // ... other mock data
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
    final dynamicColor = _getDynamicColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Satisfaction'),
        // Removed hardcoded colors
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
                context,
                Icons.star_rate_rounded,
                '5-star count',
                '${filtered.where((r) => r.rating == 5).length}',
              ),
              _kpi(
                context,
                Icons.sentiment_satisfied_alt_outlined,
                '≥4 ratings',
                '${filtered.where((r) => r.rating >= 4).length}',
              ),
              _kpi(
                context,
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
            _empty(context, 'No ratings for the selected period.')
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
        backgroundColor: dynamicColor, // Use dynamic color
        onPressed: () => setState(() {}), // mock refresh
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('Refresh', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  List<_Rating> _applyFilters(List<_Rating> items) {
    // ... (filter logic is unchanged)
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
    if (totalPoints <= 15) return ('Bad', '😡');
    if (totalPoints <= 50) return ('Average', '😐');
    return ('Great', '😄');
  }

  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

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
                    color: onCardColor,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Widget _empty(BuildContext context, String message) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  // ... (unchanged)
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

class _Rating {
  final String customer;
  final String service;
  final int rating; // 1..5
  final DateTime time;
  _Rating(this.customer, this.service, this.rating, this.time);
}

enum _Period { week, month, custom }
