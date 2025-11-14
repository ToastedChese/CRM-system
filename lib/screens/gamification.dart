import 'dart:math';
import 'package:flutter/material.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with TickerProviderStateMixin {
  String _period = 'weekly'; // weekly | monthly | all
  late final AnimationController _pointsAnim;
  late Future<_GamifyData> _future;

  @override
  void initState() {
    super.initState();
    _pointsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _future = _load(); // local mock
  }

  @override
  void dispose() {
    _pointsAnim.dispose();
    super.dispose();
  }

  Future<_GamifyData> _load() async {
    // Mock data generator (replace with real fetch later)
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final random = Random();
    final mePoints = switch (_period) {
      'weekly' => 420 + random.nextInt(180),
      'monthly' => 2400 + random.nextInt(800),
      _ => 8200 + random.nextInt(2200),
    };

    final names = [
      'You',
      'Alex',
      'Sam',
      'Riley',
      'Jordan',
      'Taylor',
      'Jamie',
      'Morgan',
      'Cameron',
      'Avery',
    ];

    
    final scores = <_Score>[];
    for (var i = 0; i < names.length; i++) {
      final base = i == 0 ? mePoints : mePoints - 50 * i + random.nextInt(120);
      scores.add(_Score(userId: i, name: names[i], points: max(50, base)));
    }
    scores.sort((a, b) => b.points.compareTo(a.points));
    for (var i = 0; i < scores.length; i++) {
      scores[i] = scores[i].copyWith(rank: i + 1);
    }

    final me = scores.firstWhere(
      (s) => s.name == 'You',
      orElse: () => scores.first,
    );

    final badges = <String>[
      if (me.points > 500) 'Streak x5',
      if (me.points > 1500) 'Closer Pro',
      if (me.points > 5000) 'Top Performer',
      'Team Player',
    ];

    _pointsAnim.forward(from: 0);
    return _GamifyData(
      me: _MyStats(totalPoints: me.points, badges: badges),
      board: scores,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GamifyData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        final me = data.me;
        final board = data.board;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PointsCard(
                      points: me.totalPoints,
                      anim: _pointsAnim,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PeriodChips(
                    value: _period,
                    onChanged: (p) {
                      setState(() => _period = p);
                      _refresh();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (me.badges.isNotEmpty) ...[
                Text(
                  'Your Badges',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: me.badges.map((b) => _BadgeChip(text: b)).toList(),
                ),
                const SizedBox(height: 16),
              ],

              if (board.length >= 3) _Podium(top: board.take(3).toList()),
              const SizedBox(height: 12),
              Text(
                'Leaderboard',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              ...board.map(
                (row) => _RowTile(
                  rank: row.rank,
                  name: row.name,
                  points: row.points,
                  isMe: row.name == 'You',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------- UI PARTS ----------

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points, required this.anim});
  final int points;
  final AnimationController anim;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    final color = Theme.of(context).colorScheme.primaryContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: curved,
        builder: (_, __) {
          final value = (points * curved.value).round();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Points',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: points == 0 ? 0 : value / points),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = const ['weekly', 'monthly', 'all'];
    return Wrap(
      spacing: 6,
      children: items.map((p) {
        final selected = p == value;
        return ChoiceChip(
          label: Text(p[0].toUpperCase() + p.substring(1)),
          selected: selected,
          onSelected: (_) => onChanged(p),
        );
      }).toList(),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.emoji_events, size: 18),
      label: Text(text),
      shape: StadiumBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(.3),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top});
  final List<_Score> top;

  @override
  Widget build(BuildContext context) {
    // order: #2, #1, #3 for nice visual
    final items = [top[1], top[0], top[2]];
    final heights = [120.0, 160.0, 100.0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final s = items[i];
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(s.name.characters.first.toUpperCase()),
              ),
              const SizedBox(height: 6),
              Text(
                '#${s.rank} ${s.name}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                height: heights[i],
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${s.points} pts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    required this.rank,
    required this.name,
    required this.points,
    this.isMe = false,
  });

  final int rank;
  final String name;
  final int points;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: CircleAvatar(child: Text(name.characters.first.toUpperCase())),
      title: Row(
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isMe) const SizedBox(width: 6),
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text('You', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      subtitle: Text('Rank #$rank'),
      trailing: Text(
        '$points pts',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );

    return Card(elevation: isMe ? 3 : 1, child: tile);
  }
}

/// ---------- Simple local models for mock ----------

class _Score {
  const _Score({
    required this.userId,
    required this.name,
    required this.points,
    this.rank = 0,
  });

  final int userId;
  final String name;
  final int points;
  final int rank;

  _Score copyWith({int? rank}) => _Score(
    userId: userId,
    name: name,
    points: points,
    rank: rank ?? this.rank,
  );
}

class _MyStats {
  const _MyStats({required this.totalPoints, required this.badges});
  final int totalPoints;
  final List<String> badges;
}

class _GamifyData {
  const _GamifyData({required this.me, required this.board});
  final _MyStats me;
  final List<_Score> board;
}
