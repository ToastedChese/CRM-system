import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/gamification_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  // --- 1. LOCAL DATA SOURCE & HELPERS ---
  static const String testUserId = 'local_test_user'; // A hardcoded ID for our local user
  static List<Map<String, dynamic>>? _dummyLeaderboardData;

  static void updateCurrentUserXp(int newXp) {
    if (_dummyLeaderboardData == null) return;
    try {
      final currentUserData = _dummyLeaderboardData!.firstWhere((user) => user['id'] == testUserId);
      currentUserData['xp'] = newXp;
    } catch (e) {
      print("Local test user not found in dummy data: $e");
    }
  }

  static int getCurrentUserXp() {
    if (_dummyLeaderboardData == null) return 0;
    try {
      return _dummyLeaderboardData!.firstWhere((user) => user['id'] == testUserId)['xp'];
    } catch (e) {
      return 0;
    }
  }
  // --- END OF LOCAL DATA SECTION ---

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {

  @override
  void initState() {
    super.initState();
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboard() async {
    if (LeaderboardScreen._dummyLeaderboardData == null) {
      print("--- Generating new LOCAL dummy leaderboard data. ---");
      List<Map<String, dynamic>> generatedData = [];

      generatedData.add({
        'id': LeaderboardScreen.testUserId,
        'username': 'You (Local Test)',
        'xp': 0,
        'avatar_url': null,
      });

      for (int i = 1; i <= 20; i++) {
        generatedData.add({
          'id': 'dummy_id_$i',
          'username': 'User $i',
          'xp': (20 - i) * 150 + 50,
          'avatar_url': null,
        });
      }

      LeaderboardScreen._dummyLeaderboardData = generatedData;
    }

    LeaderboardScreen._dummyLeaderboardData!.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));

    await Future.delayed(const Duration(milliseconds: 50));
    return LeaderboardScreen._dummyLeaderboardData!;
  }

  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return isDarkMode ? Colors.blueAccent : theme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard (Local)'),
        backgroundColor: const Color(0xFF182D53),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                LeaderboardScreen._dummyLeaderboardData = null;
              });
            },
            tooltip: 'Reset Local Data',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Could not load local data.'));
          }

          final employees = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                final rank = index + 1;
                final rankColor = _getRankColor(rank);
                final userRank = Rank.getRank(employee['xp'] ?? 0);
                final isCurrentUser = employee['id'] == LeaderboardScreen.testUserId;
                final dynamicHighlightColor = _getDynamicColor(context);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: isCurrentUser ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    side: isCurrentUser ? BorderSide(color: dynamicHighlightColor, width: 2) : BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rankColor,
                      child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    title: Text(
                      employee['username'] ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser ? dynamicHighlightColor : null,
                      ),
                    ),
                    subtitle: Text('${userRank.name} - ${NumberFormat.compact().format(employee['xp'] ?? 0)} XP'),
                    trailing: Text(userRank.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700;
    if (rank == 2) return Colors.grey.shade600;
    if (rank == 3) return Colors.brown.shade600;
    return Theme.of(context).primaryColor;
  }
}
