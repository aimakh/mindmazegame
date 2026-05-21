import 'dart:math';
import 'level_data.dart';

class GameMetrics {
  // Track last 10 player coordinates
  final List<Position> playerPathHistory = [];
  
  // Directions (horizontal, vertical, diagonal)
  int horizontalMoves = 0;
  int verticalMoves = 0;
  int diagonalMoves = 0;

  // Corner usage (wall-hugging indices)
  int wallHuggingSteps = 0;
  int totalSteps = 0;

  // Speed and time tracking
  DateTime lastMoveTime = DateTime.now();
  final List<double> moveIntervalsMs = [];

  // Objective priorities
  int collectedNodesCount = 0;
  int remainingNodesCount = 0;

  // Real-time threat coefficients
  int timesDetectedBySentinel = 0;
  int ticksInSentinelLOS = 0;
  double stressIndex = 0.0;

  void recordMove(Position oldPos, Position newPos, List<List<TileType>> grid) {
    totalSteps++;
    
    // Add path history (limit to 10)
    playerPathHistory.add(newPos);
    if (playerPathHistory.length > 10) {
      playerPathHistory.removeAt(0);
    }

    // Direction axis check
    int dx = (newPos.x - oldPos.x).abs();
    int dy = (newPos.y - oldPos.y).abs();
    if (dx > 0 && dy > 0) {
      diagonalMoves++;
    } else if (dx > 0) {
      horizontalMoves++;
    } else if (dy > 0) {
      verticalMoves++;
    }

    // Corner / boundary check (x in {0, 11} or y in {0, 11})
    if (newPos.x == 0 || newPos.x == 11 || newPos.y == 0 || newPos.y == 11) {
      wallHuggingSteps++;
    }

    // Interval tracking
    DateTime now = DateTime.now();
    double delta = now.difference(lastMoveTime).inMilliseconds.toDouble();
    lastMoveTime = now;
    moveIntervalsMs.add(delta);
    if (moveIntervalsMs.length > 15) {
      moveIntervalsMs.removeAt(0);
    }

    // Recalculate dynamic stress index based on speed stability and proximity threats
    double variance = _calculateVelocityVariance();
    double alertModifier = ticksInSentinelLOS * 0.15;
    stressIndex = ((variance / 1000.0) + alertModifier).clamp(0.0, 1.0);
  }

  String evaluatePreferredDirection() {
    int maxMove = max(horizontalMoves, max(verticalMoves, diagonalMoves));
    if (maxMove == 0) return 'Static';
    if (maxMove == diagonalMoves) return 'Diagonal';
    if (maxMove == horizontalMoves) return 'Horizontal';
    return 'Vertical';
  }

  double calculateCornerUsageRatio() {
    if (totalSteps == 0) return 0.0;
    return wallHuggingSteps / totalSteps;
  }

  String evaluateSpeedPattern() {
    if (moveIntervalsMs.isEmpty) return 'Steady';
    double avg = moveIntervalsMs.reduce((a, b) => a + b) / moveIntervalsMs.length;
    double varSum = 0.0;
    for (var val in moveIntervalsMs) {
      varSum += pow(val - avg, 2);
    }
    double stdDev = sqrt(varSum / moveIntervalsMs.length);
    
    // High standard deviation = explosive speed segments followed by wait cycles
    return stdDev > 250.0 ? 'Burst-then-Wait' : 'Steady-Pacing';
  }

  String evaluateObjectivePriority(int initialNodes) {
    if (initialNodes == 0) return 'Exit Focused';
    double collectionRatio = collectedNodesCount / initialNodes;
    if (collectionRatio > 0.8) return 'Systematic Collector';
    if (collectedNodesCount == 0 && totalSteps > 5) return 'Speedrun Rusher';
    return 'Balanced';
  }

  double _calculateVelocityVariance() {
    if (moveIntervalsMs.length < 2) return 0.0;
    double avg = moveIntervalsMs.reduce((a, b) => a + b) / moveIntervalsMs.length;
    return moveIntervalsMs.map((x) => pow(x - avg, 2)).reduce((a, b) => a + b) / moveIntervalsMs.length;
  }

  void reset() {
    playerPathHistory.clear();
    horizontalMoves = 0;
    verticalMoves = 0;
    diagonalMoves = 0;
    wallHuggingSteps = 0;
    totalSteps = 0;
    moveIntervalsMs.clear();
    collectedNodesCount = 0;
    remainingNodesCount = 0;
    timesDetectedBySentinel = 0;
    ticksInSentinelLOS = 0;
    stressIndex = 0.0;
    lastMoveTime = DateTime.now();
  }
}
