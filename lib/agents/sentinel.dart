import 'dart:math';
import '../models/level_data.dart';
import '../models/agent_state.dart';
import '../models/game_metrics.dart';

class SentinelAgent {
  final int id;
  Position currentPos;
  
  // Persistent memory fields
  String strategyFingerprint = 'Ghost';
  double fingerprintConfidence = 0.85;

  SentinelAgent({
    required this.id,
    required this.currentPos,
  });

  /// Compute next coordinate step towards player using pathfinding heuristics
  Position executeHuntingTurn({
    required Position playerPos,
    required List<List<TileType>> grid,
    required GameMetrics metrics,
    required MasterAgentConsole console,
    required int turnCount,
  }) {
    String timestamp = 'T+${turnCount.toString().padLeft(4, '0')}';
    
    // Step 1: Observe player states and tracking parameters
    bool playerInLOS = _hasLineOfSight(currentPos, playerPos, grid);
    double dist = currentPos.distanceTo(playerPos);
    
    String observe = 'Observer sweep: Sentinel #$id at $currentPos. Player at $playerPos. '
        'LOS state: ${playerInLOS ? 'ILLUMINATED' : 'SHADOWED'}. Distance: ${dist.toStringAsFixed(1)} cells. '
        'Path memory size: ${metrics.playerPathHistory.length} moves.';

    // Step 2: Infer/Classify player strategy pattern
    _classifyPlayerStrategy(metrics);
    
    String infer = 'Infer Strategy Fingerprint: "$strategyFingerprint" '
        '(Confidence: ${(fingerprintConfidence * 100).toStringAsFixed(0)}%). '
        'Acoustic noise signature is typical of a speedrun ${strategyFingerprint.toLowerCase()}.';

    // Step 3: Decide tactical behavior
    String tacticalMode = 'Patrol';
    Position targetWaypoint = playerPos; // Intercept player coordinates

    if (strategyFingerprint == 'Rusher') {
      tacticalMode = 'Exit Intercept';
      // Pre-position to exit at (10, 10) to cut off the rusher!
      targetWaypoint = const Position(10, 10);
    } else if (playerInLOS) {
      tacticalMode = 'Pursuit';
      targetWaypoint = playerPos;
    } else if (metrics.playerPathHistory.isNotEmpty) {
      tacticalMode = 'Investigate Noise';
      // Head to last known position
      targetWaypoint = metrics.playerPathHistory.last;
    }

    // Solve shortest path to target using BFS pathfinder
    List<Position> path = _findShortestPath(currentPos, targetWaypoint, grid);
    Position nextStep = currentPos;
    if (path.length > 1) {
      nextStep = path[1]; // Index 0 is currentPos, Index 1 is next step
    }

    String decide = 'Tactical Protocol: $tacticalMode. Target set at $targetWaypoint. '
        'Recalculating path to intercept. Path length: ${path.length} steps.';

    // Step 4: Act (move coordinate)
    Position oldPos = currentPos;
    currentPos = nextStep;
    
    String act = 'Dispatched move step: $oldPos -> $currentPos. '
        'Sensor ping sweep focused at 45° angle. Threat array updated.';

    // Step 5: Evaluate tactical efficacy
    double endingDist = currentPos.distanceTo(playerPos);
    double delta = dist - endingDist;
    String evaluationResult = delta > 0 ? 'GAINED' : 'LOST';
    
    String evaluate = 'Interception metric: $evaluationResult. Dynamic distance delta: '
        '${delta.abs().toStringAsFixed(1)} cells. '
        'Player containment rating in this quadrant: ${(endingDist < 3 ? 90 : 30)}%.';

    // Stream trace outputs to dynamic console logs
    console.dispatchTrace(AgentTrace(
      agent: 'SentinelAgent_$id',
      timestamp: timestamp,
      observe: observe,
      infer: infer,
      decide: decide,
      act: act,
      evaluate: evaluate,
    ));

    return currentPos;
  }

  /// Classify player strategy dynamically based on collected telemetry
  void _classifyPlayerStrategy(GameMetrics metrics) {
    if (metrics.totalSteps < 3) return; // Need telemetry buffer

    String preferredDir = metrics.evaluatePreferredDirection();
    double cornerRatio = metrics.calculateCornerUsageRatio();
    String speed = metrics.evaluateSpeedPattern();

    // Strategy classifier rules
    if (speed == 'Burst-then-Wait' && cornerRatio > 0.6) {
      _updateFingerprint('Ghost', 0.88);
    } else if (speed == 'Steady-Pacing' && cornerRatio < 0.3) {
      _updateFingerprint('Rusher', 0.92);
    } else if (metrics.collectedNodesCount > 3) {
      _updateFingerprint('Collector', 0.85);
    } else {
      _updateFingerprint('Chaotic', 0.65);
    }
  }

  void _updateFingerprint(String fingerprint, double baselineConf) {
    if (strategyFingerprint == fingerprint) {
      // Scale confidence up over time if pattern persists
      fingerprintConfidence = min(1.0, fingerprintConfidence + 0.05);
    } else {
      // Abrupt pivot triggers confidence drop, transitioning strategy profile
      strategyFingerprint = fingerprint;
      fingerprintConfidence = baselineConf;
    }
  }

  /// Simple raycasting check to confirm Sentinel Line of Sight (LOS)
  bool _hasLineOfSight(Position from, Position to, List<List<TileType>> grid) {
    // Manhattan vector bounds
    int dx = (to.x - from.x).abs();
    int dy = (to.y - from.y).abs();
    if (dx + dy > 5) return false; // Vision range capped at 5 cells

    int stepX = from.x < to.x ? 1 : -1;
    int stepY = from.y < to.y ? 1 : -1;

    int cx = from.x;
    int cy = from.y;

    // Check cells along path to confirm no blocking walls
    while (cx != to.x || cy != to.y) {
      if (cx != to.x && cy != to.y) {
        cx += stepX;
        cy += stepY;
      } else if (cx != to.x) {
        cx += stepX;
      } else {
        cy += stepY;
      }

      if (grid[cy][cx] == TileType.wall) {
        return false; // Solid wall blocks sight ray
      }
    }
    return true;
  }

  /// BFS Shortest Path Solver around walls
  List<Position> _findShortestPath(Position start, Position target, List<List<TileType>> grid) {
    List<List<Position>> queue = [[start]];
    Set<Position> visited = {start};

    while (queue.isNotEmpty) {
      List<Position> path = queue.removeAt(0);
      Position curr = path.last;

      if (curr == target) return path;

      // Expand 4 orthogonal directions
      List<Position> neighbors = [
        Position(curr.x + 1, curr.y),
        Position(curr.x - 1, curr.y),
        Position(curr.x, curr.y + 1),
        Position(curr.x, curr.y - 1),
      ];

      for (var next in neighbors) {
        if (next.x >= 0 && next.x < 12 && next.y >= 0 && next.y < 12) {
          if (grid[next.y][next.x] != TileType.wall && !visited.contains(next)) {
            visited.add(next);
            List<Position> newPath = List.from(path)..add(next);
            queue.add(newPath);
          }
        }
      }
    }
    return [start]; // Return single step if pathfinding is blocked
  }
}
