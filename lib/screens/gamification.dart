import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/gamification_service.dart';
import 'leaderboard_screen.dart'; // Import the new screen

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({Key? key}) : super(key: key);

  @override
  _GamificationScreenState createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  late Future<Map<String, dynamic>> _userProgressFuture;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _userProgressFuture = _fetchUserProgress();
  }

  Future<Map<String, dynamic>> _fetchUserProgress() async {
    final userId = _supabase.auth.currentUser!.id;

    // Fetch the current user's data
    final userQuery = _supabase
        .from('employees')
        .select()
        .eq('auth_user_id', userId)
        .single();

    // Fetch all players to determine rank
    final leaderboardQuery = _supabase
        .from('employees')
        .select('employee_id, rank_points')
        .order('rank_points', ascending: false);

    // Execute both queries in parallel
    final responses = await Future.wait([userQuery, leaderboardQuery]);

    final userData = responses[0] as Map<String, dynamic>;
    final leaderboardData = responses[1] as List<dynamic>;

    // Find the user's position
    int userRankPosition = leaderboardData.indexWhere(
          (player) => player['employee_id'] == userData['employee_id'],
    ) + 1; // Add 1 because index is 0-based

    return {
      'userData': userData,
      'leaderboardSize': leaderboardData.length,
      'userRankPosition': userRankPosition,
    };
  }

    Future<void> _addPoints(int amount) async {
    try {
      final userId = _supabase.auth.currentUser!.id; 
      final employeeResponse = await _supabase
          .from('employees')
          .select('employee_id, rank_points')
          .eq('auth_user_id', userId)
          .single();

      final employeeId = employeeResponse['employee_id'] as int;
      final currentPoints = employeeResponse['rank_points'] as int? ?? 0;
      final newPoints = currentPoints + amount;

      await _supabase
          .from('employees')
          .update({'rank_points': newPoints})
          .eq('employee_id', employeeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+$amount Points! Your new total is $newPoints Points.')));
        setState(() {
            _userProgressFuture = _fetchUserProgress();
        });
      }
    } catch (error) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating points: ${error.toString()}')));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProgressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading your progress: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Could not find your progress data.'));
          }

          final progressData = snapshot.data!;
          final userData = progressData['userData'] as Map<String, dynamic>;
          final currentPoints = userData['rank_points'] as int? ?? 0;
          final currentRank = Rank.getRank(currentPoints);
          final nextRank = GamificationService.getNextRank(currentPoints);

          double progress = 0.0;
          int pointsForNextRank = 0;
          if (nextRank != null) {
            final pointsInCurrentRank = currentPoints - currentRank.minXp;
            final pointsNeededForNextRank = nextRank.minXp - currentRank.minXp;
            progress = pointsInCurrentRank / pointsNeededForNextRank;
            pointsForNextRank = nextRank.minXp;
          } else {
            // User is at the highest rank
            progress = 1.0;
            pointsForNextRank = currentRank.minXp;
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _userProgressFuture = _fetchUserProgress();
              });
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(currentRank.emoji, style: const TextStyle(fontSize: 60)),
                    const SizedBox(height: 8),
                    Text(currentRank.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Global Rank: #${progressData['userRankPosition']} of ${progressData['leaderboardSize']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 40),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Text('$currentPoints / $pointsForNextRank Points to next rank'),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Task'),
                          onPressed: () => _addPoints(10),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('Customer'),
                          onPressed: () => _addPoints(5),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        ),
                      ],
                    ),
                     const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.leaderboard_outlined),
                      label: const Text('View Full Leaderboard'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                        );
                      },
                       style: ElevatedButton.styleFrom(
                         minimumSize: const Size(double.infinity, 48), // Make button wide
                       ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
