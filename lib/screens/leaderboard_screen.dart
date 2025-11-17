
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/gamification_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final userId = _supabase.auth.currentUser?.id;
    int? currentEmployeeId;

    // Fetch leaderboard data and current user's employee_id in parallel
    final responses = await Future.wait([
      _supabase
          .from('employees')
          .select(
              'employee_id, first_name, last_name, email, rank_points, avatar_url')
          .order('rank_points', ascending: false)
          .limit(100),
      if (userId != null)
        _supabase
            .from('employees')
            .select('employee_id')
            .eq('auth_user_id', userId)
            .single()
    ]);

    final leaderboardResponse = responses[0] as List;
    if (responses.length > 1 && responses[1] != null) {
       final userResponse = responses[1] as Map<String, dynamic>?;
       currentEmployeeId = userResponse?['employee_id'];
    }

    return {
      'leaderboard': List<Map<String, dynamic>>.from(leaderboardResponse),
      'currentEmployeeId': currentEmployeeId,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Leaderboard'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(
                  child: Text('No players on the leaderboard yet.'));
            }

            final data = snapshot.data!;
            final players = data['leaderboard'] as List<Map<String, dynamic>>;
            final currentEmployeeId = data['currentEmployeeId'] as int?;

            if (players.isEmpty) {
              return const Center(child: Text('No players on the leaderboard yet.'));
            }

            final topThree = players.take(3).toList();
            final rest = players.skip(3).toList();

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _dataFuture = _fetchData();
                });
              },
              child: ListView(
                children: [
                  _buildPodium(topThree, currentEmployeeId),
                  const SizedBox(height: 20),
                  _buildLeaderboardList(rest, 4, currentEmployeeId),
                ],
              ),
            );
          }),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> topThree, int? currentEmployeeId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length > 1)
            _buildPodiumMember(topThree[1], 2, 120, currentEmployeeId),
          if (topThree.isNotEmpty)
            _buildPodiumMember(topThree[0], 1, 150, currentEmployeeId),
          if (topThree.length > 2)
            _buildPodiumMember(topThree[2], 3, 100, currentEmployeeId),
        ],
      ),
    );
  }

  Widget _buildPodiumMember(
      Map<String, dynamic> player, int rank, double height, int? currentEmployeeId) {
    final userRank = Rank.getRank(player['rank_points'] ?? 0);
    final playerName =
        '${player['first_name'] ?? ''} ${player['last_name'] ?? ''}'.trim();
    final bool isCurrentUser = player['employee_id'] == currentEmployeeId;
    final displayName = (playerName.isEmpty ? 'Player' : playerName) + (isCurrentUser ? ' (You)' : '');


    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(userRank.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: 30,
          backgroundImage: player['avatar_url'] != null &&
                  player['avatar_url'].isNotEmpty
              ? NetworkImage(player['avatar_url'])
              : null,
          child: player['avatar_url'] == null || player['avatar_url'].isEmpty
              ? const Icon(Icons.person, size: 30)
              : null,
        ),
        const SizedBox(height: 8),
        Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
        Text('${player['rank_points'] ?? 0} Points',
            style: TextStyle(color: Colors.grey[600])),
        Container(
          height: height,
          width: 60,
          decoration: BoxDecoration(
            color: rank == 1
                ? Colors.amber
                : rank == 2
                    ? Colors.grey[400]
                    : Colors.brown[300],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(
      List<Map<String, dynamic>> players, int startIndex, int? currentEmployeeId) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final playerRank = Rank.getRank(player['rank_points'] ?? 0);
        final playerName =
            '${player['first_name'] ?? ''} ${player['last_name'] ?? ''}'.trim();
        final bool isCurrentUser = player['employee_id'] == currentEmployeeId;
        final displayName = (playerName.isEmpty ? 'Player' : playerName) + (isCurrentUser ? ' (you)' : '');

        return ListTile(
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${startIndex + index}'),
              Text(playerRank.emoji, style: const TextStyle(fontSize: 18)),
            ],
          ),
          title: Text(displayName),
          subtitle: Text(playerRank.name),
          trailing: Text('${player['rank_points'] ?? 0} Points'),
        );
      },
    );
  }
}
