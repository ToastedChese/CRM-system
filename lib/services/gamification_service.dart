import 'package:flutter/material.dart';

class Rank {
  final String name;
  final int minXp;
  final String emoji;

  const Rank({required this.name, required this.minXp, required this.emoji});

  static Rank getRank(int xp) {
    final ranks = GamificationService.ranks;
    return ranks.firstWhere((rank) => xp >= rank.minXp, orElse: () => ranks.last);
  }
}

class GamificationService {
  static const List<Rank> ranks = [
    Rank(name: 'Legend', minXp: 5000, emoji: '🏆'),
    Rank(name: 'Diamond III', minXp: 4500, emoji: '💎'),
    Rank(name: 'Diamond II', minXp: 4000, emoji: '💎'),
    Rank(name: 'Diamond I', minXp: 3500, emoji: '💎'),
    Rank(name: 'Platinum III', minXp: 3000, emoji: '🛡️'),
    Rank(name: 'Platinum II', minXp: 2500, emoji: '🛡️'),
    Rank(name: 'Platinum I', minXp: 2000, emoji: '🛡️'),
    Rank(name: 'Gold III', minXp: 1500, emoji: '🥇'),
    Rank(name: 'Gold II', minXp: 1000, emoji: '🥇'),
    Rank(name: 'Gold I', minXp: 750, emoji: '🥇'),
    Rank(name: 'Silver III', minXp: 500, emoji: '🥈'),
    Rank(name: 'Silver II', minXp: 300, emoji: '🥈'),
    Rank(name: 'Silver I', minXp: 100, emoji: '🥈'),
    Rank(name: 'Bronze III', minXp: 50, emoji: '🥉'),
    Rank(name: 'Bronze II', minXp: 20, emoji: '🥉'),
    Rank(name: 'Bronze I', minXp: 0, emoji: '🥉'),
  ];

  // Helper to get the next rank
  static Rank? getNextRank(int currentXp) {
    final currentRank = Rank.getRank(currentXp);
    // Find the index of the current rank in the (descending) list
    int currentRankIndex = ranks.indexWhere((rank) => rank.name == currentRank.name);
    
    // If the user is not the highest rank, return the next rank up.
    if (currentRankIndex > 0) {
      return ranks[currentRankIndex - 1];
    }
    
    // User is at the highest rank, there is no next rank.
    return null;
  }
}
