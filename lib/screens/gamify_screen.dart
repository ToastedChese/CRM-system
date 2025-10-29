// import 'dart:async'; // No longer needed
import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // No longer needed

import '../services/gamification_service.dart';
import 'leaderboard_screen.dart';

class GamifyScreen extends StatefulWidget {
  const GamifyScreen({super.key});

  @override
  _GamifyScreenState createState() => _GamifyScreenState();
}

class _GamifyScreenState extends State<GamifyScreen> {
  // These are now the only state variables needed for this screen
  int _currentXp = 0;
  Rank _currentRank = Rank.allRanks[0];
  bool _isLoading = false; // We start with data immediately

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Fetches the user's initial XP from the local dummy data source.
  void _loadInitialData() {
    // Get XP directly from the static method in LeaderboardScreen
    final xp = LeaderboardScreen.getCurrentUserXp();
    setState(() {
      _currentXp = xp;
      _currentRank = Rank.getRank(xp);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamify (Local Test)'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildGamifyContent(), // Directly build the main content
    );
  }

  /// The main content of the gamification screen.
  Widget _buildGamifyContent() {
    final nextRank = Rank.getNextRank(_currentRank);
    double progress = 0;
    if (nextRank != null) {
      final rankXpRange = nextRank.minXp - _currentRank.minXp;
      final xpIntoRank = _currentXp - _currentRank.minXp;
      progress = xpIntoRank / rankXpRange;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildRankCard(nextRank, progress),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.check_circle_outline,
            label: 'Complete a Task',
            points: GamificationService.pointsForTaskCompletion,
            onPressed: () {
              int newXp = _currentXp + GamificationService.pointsForTaskCompletion;
              setState(() {
                _currentXp = newXp;
                _currentRank = Rank.getRank(newXp);
              });
              // Update the central local data source
              LeaderboardScreen.updateCurrentUserXp(newXp);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('LOCAL: Added ${GamificationService.pointsForTaskCompletion} XP!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.handshake_outlined,
            label: 'Welcome New Customer',
            points: GamificationService.pointsForWelcomingCustomer,
            onPressed: () {
              int newXp = _currentXp + GamificationService.pointsForWelcomingCustomer;
              setState(() {
                _currentXp = newXp;
                _currentRank = Rank.getRank(newXp);
              });
              // Update the central local data source
              LeaderboardScreen.updateCurrentUserXp(newXp);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('LOCAL: Added ${GamificationService.pointsForWelcomingCustomer} XP!')),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.leaderboard),
            label: const Text('View Leaderboard'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              textStyle: const TextStyle(fontSize: 18),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
              ).then((_) {
                // When we return from the leaderboard, refresh the Gamify screen's data
                _loadInitialData();
              });
            },
          ),
        ],
      ),
    );
  }

  // --- No changes needed for the helper widgets below ---
  Widget _buildRankCard(Rank? nextRank, double progress) {
    final theme = Theme.of(context).textTheme;
    final isGrandmaster = nextRank == null;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(_currentRank.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(_currentRank.name, style: theme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              isGrandmaster ? 'Total XP: $_currentXp' : '${_currentRank.minXp} - ${nextRank.minXp} XP',
              style: theme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: isGrandmaster ? 1.0 : progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            if (!isGrandmaster && nextRank != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('$_currentXp / ${nextRank.minXp} XP', style: theme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required int points, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }
}
