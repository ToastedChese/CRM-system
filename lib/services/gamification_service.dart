
import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  final SupabaseClient _supabase;

  GamificationService(this._supabase);

  // --- Constants for Points ---
  static const int pointsForTaskCompletion = 25;
  static const int pointsForWelcomingCustomer = 15;

  /// Retrieves the current XP for a given employee.
  Future<int> getCurrentXp(String employeeId) async {
    try {
      final response = await _supabase
          .from('employees')
          .select('xp')
          .eq('id', employeeId)
          .single();
      return response['xp'] as int? ?? 0;
    } catch (e) {
      print('Error fetching XP: $e');
      return 0;
    }
  }

  /// Awards points to an employee and updates their XP in the database.
  Future<int> awardPoints(String employeeId, int pointsToAdd) async {
    try {
      // 'rpc' calls a remote procedure call, which is a database function.
      // This is often faster and more secure than fetching, calculating, and then updating.
      final newXp = await _supabase.rpc(
        'award_xp',
        params: {'employee_id': employeeId, 'points_to_add': pointsToAdd},
      );
      return newXp as int;
    } on PostgrestException catch (e) {
      // Handle potential errors, like if the function doesn't exist.
      print('Error awarding points: ${e.message}');
      // As a fallback, do it manually (though the RPC is preferred)
      final currentXp = await getCurrentXp(employeeId);
      final updatedXp = currentXp + pointsToAdd;
      await _supabase
          .from('employees')
          .update({'xp': updatedXp}).eq('id', employeeId);
      return updatedXp;
    } catch (e) {
      print('An unexpected error occurred: $e');
      return await getCurrentXp(employeeId); // Return current XP on failure
    }
  }
}

/// A utility class to manage the ranking system logic.
class Rank {
  final String name;
  final int minXp;
  final String emoji;

  const Rank(this.name, this.minXp, this.emoji);

  // --- Static List of All Ranks ---
  static const List<Rank> allRanks = [
    Rank('Bronze I', 0, '🥉'),
    Rank('Bronze II', 100, '🥉'),
    Rank('Bronze III', 200, '🥉'),
    Rank('Silver I', 300, '🥈'),
    Rank('Silver II', 400, '🥈'),
    Rank('Silver III', 500, '🥈'),
    Rank('Gold I', 600, '🥇'),
    Rank('Gold II', 700, '🥇'),
    Rank('Gold III', 800, '🥇'),
    Rank('Platinum', 900, '🛡️'),
    Rank('Diamond', 1200, '💎'),
    Rank('Master', 1500, '👑'),
    Rank('Grandmaster', 2000, '🏆'),
  ];

  /// Calculates the current rank based on the employee's XP.
  static Rank getRank(int xp) {
    // Iterates backwards from Grandmaster down to Bronze.
    for (int i = allRanks.length - 1; i >= 0; i--) {
      if (xp >= allRanks[i].minXp) {
        return allRanks[i];
      }
    }
    return allRanks[0]; // Default to Bronze I
  }

  /// Finds the next rank in the progression.
  static Rank? getNextRank(Rank currentRank) {
    final currentIndex = allRanks.indexOf(currentRank);
    // If the current rank is not the last one (Grandmaster)
    if (currentIndex < allRanks.length - 1) {
      return allRanks[currentIndex + 1];
    }
    return null; // No next rank after Grandmaster
  }
}
