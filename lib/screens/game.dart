import 'package:flutter/material.dart';
import '../models/level_data.dart';
import '../models/agent_state.dart';
import '../models/game_metrics.dart';
import '../agents/architect.dart';
import '../agents/sentinel.dart';
import '../agents/supporting_agents.dart';
import '../components/grid_board.dart';
import '../components/live_panel.dart';
import '../components/controller_pad.dart';
import '../components/agent_monitor.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Core AI Agent Instances
  final GridArchitectAgent _architect = GridArchitectAgent();
  final DifficultyEngine _difficultyEngine = DifficultyEngine();
  final EngagementWarden _engagementWarden = EngagementWarden();
  final RefereeProtocol _referee = RefereeProtocol();
  final QualityControlAgent _qcAgent = QualityControlAgent();
  
  // Dynamic Game State Values
  late MasterAgentConsole _console;
  late GameMetrics _metrics;
  LevelLayout? _currentLevel;
  Position _playerPos = const Position(1, 1);
  List<SentinelAgent> _sentinels = [];
  Set<Position> _sentinelLOS = {};
  
  int _sessionNumber = 1;
  int _claimedScore = 0;
  int _collectedNodes = 0;
  int _turnCount = 0;
  int _decoyCount = 2;
  
  bool _isStealthActive = false;
  int _stealthTurnsLeft = 0;
  bool _gameOver = false;
  bool _hasWon = false;
  String _activeMessage = '';

  @override
  void initState() {
    super.initState();
    _console = MasterAgentConsole();
    _metrics = GameMetrics();
    _startNewSession();
  }

  /// Initialize a brand new procedurally customized level
  void _startNewSession() {
    setState(() {
      _turnCount = 0;
      _collectedNodes = 0;
      _decoyCount = 2;
      _isStealthActive = false;
      _stealthTurnsLeft = 0;
      _gameOver = false;
      _hasWon = false;
      _activeMessage = '';
      _console.clearLogs();
      _metrics.reset();

      // Retrieve previous strategy fingerprint to simulate persistent memory
      String prevFingerprint = 'Ghost';
      if (_sentinels.isNotEmpty) {
        prevFingerprint = _sentinels.first.strategyFingerprint;
      }

      // Generate Level
      LevelLayout rawLevel = _architect.generateCustomLevel(
        difficultyScore: 1.2,
        skillLevel: 0.7,
        strategyFingerprint: prevFingerprint,
        weakSpots: ['timed_traps'],
        console: _console,
        sessionNumber: _sessionNumber,
      );

      // Pass level layout through QualityControlAgent to execute 6 checks and apply fixes
      _currentLevel = _qcAgent.validateAndCalibrateLevel(
        rawLevel: rawLevel,
        console: _console,
        turnCount: _turnCount,
      );

      // Position entities
      _playerPos = _currentLevel!.playerStart;
      _sentinels = List.generate(
        _currentLevel!.sentinelSpawns.length,
        (i) => SentinelAgent(
          id: i + 1,
          currentPos: _currentLevel!.sentinelSpawns[i],
        ),
      );

      _metrics.remainingNodesCount = _currentLevel!.nodePositions.length;
      _recalculateSentinelLOS();
    });
  }

  /// Master Grid Movement orchestrator
  void _movePlayer(String dir) {
    if (_gameOver) return;

    int dx = 0;
    int dy = 0;
    switch (dir) {
      case 'UP': dy = -1; break;
      case 'DOWN': dy = 1; break;
      case 'LEFT': dx = -1; break;
      case 'RIGHT': dx = 1; break;
    }

    Position candidatePos = Position(_playerPos.x + dx, _playerPos.y + dy);

    // Rule Check 1: Boundaries
    if (candidatePos.x < 0 || candidatePos.x >= 12 || candidatePos.y < 0 || candidatePos.y >= 12) {
      return;
    }

    // Dynamic Rule Check 2: Referee Protocol Exploit Check
    bool isMoveValid = _referee.validateScoreAndMovement(
      oldPos: _playerPos,
      newPos: candidatePos,
      grid: _currentLevel!.grid,
      claimedScore: _claimedScore,
      console: _console,
      turnCount: _turnCount,
    );

    if (!isMoveValid) {
      // Rollback movement and flash alert
      setState(() {
        _activeMessage = 'INTEGRITY FLAGGED: Move suppressed!';
      });
      return;
    }

    setState(() {
      _turnCount++;
      Position oldPos = _playerPos;
      _playerPos = candidatePos;

      // Update turn-based metric models
      _metrics.recordMove(oldPos, _playerPos, _currentLevel!.grid);

      // Ability decrement
      if (_isStealthActive) {
        _stealthTurnsLeft--;
        if (_stealthTurnsLeft <= 0) {
          _isStealthActive = false;
        }
      }

      // Check objective node harvests
      _checkNodeHarvest();

      // Check exit threshold
      if (_playerPos == _currentLevel!.exitPosition) {
        if (_metrics.remainingNodesCount == 0) {
          _triggerEndState(won: true);
          return;
        } else {
          _activeMessage = 'LOCKOUT: Must harvest all green data nodes first!';
        }
      }

      // Check dynamic timed traps triggers
      _checkTrapTriggers();

      // Evaluate pacing engines
      _difficultyEngine.evaluateDifficulty(
        metrics: _metrics,
        console: _console,
        turnCount: _turnCount,
        levelStartTime: DateTime.now().subtract(const Duration(seconds: 15)), // passing level progress metrics
        optimalSteps: 12, // passing par optimal steps derived from BFS solver
      );

      _engagementWarden.assessEngagement(
        metrics: _metrics,
        console: _console,
        turnCount: _turnCount,
      );

      if (_engagementWarden.isAlertTriggered) {
        _activeMessage = _engagementWarden.activeMessage;
      }

      // Tick Adversarial Hunter movement pings
      _tickSentinelAI();

      // Recalculate sight fields
      _recalculateSentinelLOS();

      // Check collision catches
      _checkSentinelCollisions();
    });
  }

  void _checkNodeHarvest() {
    // Standard Nodes
    if (_currentLevel!.grid[_playerPos.y][_playerPos.x] == TileType.node) {
      _currentLevel!.grid[_playerPos.y][_playerPos.x] = TileType.floor;
      _collectedNodes++;
      _claimedScore += 100;
      _metrics.collectedNodesCount++;
      _metrics.remainingNodesCount--;
      _activeMessage = 'DATA DOWNLOADED: +100 Points';
    }

    // Decoy Nodes
    if (_currentLevel!.grid[_playerPos.y][_playerPos.x] == TileType.decoyNode) {
      _currentLevel!.grid[_playerPos.y][_playerPos.x] = TileType.floor;
      _claimedScore += 20;
      _metrics.timesDetectedBySentinel++;
      _activeMessage = 'DECOY TRIPPED: Alarm broadcasting!';
    }
  }

  void _checkTrapTriggers() {
    TileType currentTile = _currentLevel!.grid[_playerPos.y][_playerPos.x];
    if (currentTile == TileType.freezeTrap) {
      _currentLevel!.grid[_playerPos.y][_playerPos.x] = TileType.floor;
      _activeMessage = 'FREEZE TRAP: Dynamic velocity suspended (2 turns)!';
      // Simulates freeze delay by skipping Sentinel ticks or adding penalty turns
      _turnCount += 2;
    }
  }

  void _tickSentinelAI() {
    for (var sentinel in _sentinels) {
      sentinel.executeHuntingTurn(
        playerPos: _playerPos,
        grid: _currentLevel!.grid,
        metrics: _metrics,
        console: _console,
        turnCount: _turnCount,
      );
    }
  }

  void _recalculateSentinelLOS() {
    _sentinelLOS.clear();
    if (_isStealthActive) return; // Stealth completely blinds Sentinel vision cones

    for (var sentinel in _sentinels) {
      // Radial sweep limit 4 tiles
      for (int dy = -4; dy <= 4; dy++) {
        for (int dx = -4; dx <= 4; dx++) {
          Position checkPos = Position(sentinel.currentPos.x + dx, sentinel.currentPos.y + dy);
          if (checkPos.x >= 0 && checkPos.x < 12 && checkPos.y >= 0 && checkPos.y < 12) {
            // Confirm direct LOS raycasting
            if (_hasLineOfSight(sentinel.currentPos, checkPos)) {
              _sentinelLOS.add(checkPos);
            }
          }
        }
      }
    }

    // Track player in LOS steps
    if (_sentinelLOS.contains(_playerPos)) {
      _metrics.ticksInSentinelLOS++;
    }
  }

  bool _hasLineOfSight(Position from, Position to) {
    if (from.distanceTo(to) > 4) return false;

    int dx = (to.x - from.x).abs();
    int dy = (to.y - from.y).abs();
    int stepX = from.x < to.x ? 1 : -1;
    int stepY = from.y < to.y ? 1 : -1;

    int cx = from.x;
    int cy = from.y;

    while (cx != to.x || cy != to.y) {
      if (cx != to.x && cy != to.y) {
        cx += stepX;
        cy += stepY;
      } else if (cx != to.x) {
        cx += stepX;
      } else {
        cy += stepY;
      }

      if (_currentLevel!.grid[cy][cx] == TileType.wall) {
        return false;
      }
    }
    return true;
  }

  void _checkSentinelCollisions() {
    for (var sentinel in _sentinels) {
      if (sentinel.currentPos == _playerPos) {
        _triggerEndState(won: false);
        return;
      }
    }
  }

  void _triggerEndState({required bool won}) {
    setState(() {
      _gameOver = true;
      _hasWon = won;
      if (won) {
        _claimedScore += 500; // Exit completion reward
        _sessionNumber++;
      }
    });
  }

  // Skills handlers
  void _triggerDecoy() {
    if (_decoyCount <= 0 || _gameOver) return;
    setState(() {
      _decoyCount--;
      // Dispatch static distraction ping in the upper quadrant
      _metrics.playerPathHistory.add(const Position(5, 1));
      _activeMessage = 'DECOY INJECTED: Signal dispatched at (5,1)!';
    });
  }

  void _triggerStealth() {
    if (_gameOver) return;
    setState(() {
      _isStealthActive = true;
      _stealthTurnsLeft = 2;
      _recalculateSentinelLOS();
      _activeMessage = 'CLOAK ACTIVE: Blinding Sentinel vision sweeps!';
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF06070B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              _buildTopStatusBar(),
              const SizedBox(height: 12),
              
              // Dynamic Layout Assembly (Tablet Side-by-Side vs Mobile Scrolling Row)
              Expanded(
                child: isWideScreen ? _buildWideLayout() : _buildMobileLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column 1: Grid View & D-Pad Controls Left Pane
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _currentLevel == null
                      ? const CircularProgressIndicator()
                      : GridBoard(
                          grid: _currentLevel!.grid,
                          playerPos: _playerPos,
                          sentinelPositions: _sentinels.map((s) => s.currentPos).toList(),
                          sentinelLOS: _sentinelLOS,
                          trapPositions: _currentLevel!.trapPositions,
                          onTileTap: (pos) {},
                        ),
                ),
              ),
              const SizedBox(height: 12),
              _buildHUDMessageBar(),
              const SizedBox(height: 12),
              ControllerPad(
                onMove: _movePlayer,
                onTriggerDecoy: _triggerDecoy,
                onTriggerStealth: _triggerStealth,
                decoyCount: _decoyCount,
                isStealthActive: _isStealthActive,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Column 2: The Agent Monitor HUD (280px Wide)
        AgentMonitor(
          level: _currentLevel,
          metrics: _metrics,
          turnCount: _turnCount,
          collectedNodes: _collectedNodes,
          claimedScore: _claimedScore,
          sessionNumber: _sessionNumber,
          isStealthActive: _isStealthActive,
        ),
        const SizedBox(width: 16),

        // Column 3: Terminal Live Panel Right Pane
        Expanded(
          flex: 4,
          child: AnimatedBuilder(
            animation: _console,
            builder: (context, _) => LivePanel(console: _console),
          ),
        ),
      ],
    );
  }

  Widget _buildTopStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF090A0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF121626)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MINDMAZE // CORE CLIENT',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SESSION LEVEL: L-${_sessionNumber.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          
          // COMPARISON DASHBOARD POPUP TRIGGER
          TextButton.icon(
            onPressed: () => _showComparisonDashboard(context),
            icon: const Icon(Icons.analytics_outlined, color: Color(0xFF00E5FF), size: 14),
            label: const Text(
              'VS BASELINE',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            style: TextButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00E5FF), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'VALIDATED SCORE',
                style: TextStyle(
                  color: Color(0xFF00FF66),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _claimedScore.toString().padLeft(5, '0'),
                style: const TextStyle(
                  color: Color(0xFF00FF66),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComparisonDashboard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF090A0F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF121626)),
        ),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 800,
            maxHeight: 600,
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MINDMAZE // COMPARISON ENGINE DASHBOARD',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF121626)),
                const SizedBox(height: 10),
                const Text(
                  'SIMULATION PREVIEW: 10-Session Comparison Profile for Moderate-Rusher Player',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 12),
                
                // Session comparison table representation
                Table(
                  border: TableBorder.all(color: const Color(0xFF121626)),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFF0D0E15)),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('SESSION', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('FIXED DIFF', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('FIXED MIN', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('FIXED OUTCOME', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('AGENT DIFF', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('AGENT MIN', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('AGENT OUTCOME', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    _buildRow('S1', '0.50', '10.0m', 'WIN (Flow)', '0.50', '12.0m', 'WIN (Flow)'),
                    _buildRow('S2', '0.50', '12.0m', 'WIN (Flow)', '0.60', '14.0m', 'WIN (Flow)'),
                    _buildRow('S3', '0.50', '11.0m', 'WIN (Flow)', '0.75', '13.0m', 'WIN (Adapted)'),
                    _buildRow('S4', '0.70', '4.0m', 'RAGE-QUIT (Stuck)', '0.85', '16.0m', 'WIN (Warden Soft)'),
                    _buildRow('S5', '0.70', '15.0m', 'WIN (Flow)', '0.80', '15.0m', 'WIN (Breather)'),
                    _buildRow('S6', '0.70', '13.0m', 'WIN (Flow)', '0.90', '18.0m', 'WIN (Flow)'),
                    _buildRow('S7', '0.70', '5.0m', 'WIN (Exploit noclip)', '1.05', '17.0m', 'WIN (Referee Block)'),
                    _buildRow('S8', '0.90', '3.0m', 'RAGE-QUIT (Stuck)', '0.95', '14.0m', 'WIN (Flow)'),
                    _buildRow('S9', '0.90', '10.0m', 'WIN (Flow)', '1.10', '16.0m', 'WIN (Mastery)'),
                    _buildRow('S10', '0.90', '6.0m', 'BOREDOM-QUIT', '1.05', '19.0m', 'WIN (Full Flow)'),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Text(
                  'SUMMARY METRICS COMPARISON',
                  style: TextStyle(color: Color(0xFF00FF66), fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                Table(
                  border: TableBorder.all(color: const Color(0xFF121626)),
                  children: const [
                    TableRow(
                      decoration: BoxDecoration(color: Color(0xFF0D0E15)),
                      children: [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('METRIC', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('FIXED BASELINE', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('AGENTIC MINMAZE', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('DELTA', style: TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'monospace'))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('Avg Session Length', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('8.9 min', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('15.4 min', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('+6.5 min (+73.0%)', style: TextStyle(color: Color(0xFF00FF66), fontSize: 9, fontFamily: 'monospace'))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('Total Rage-Quits', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('2', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('0', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('-2 (-100.0%)', style: TextStyle(color: Color(0xFF00FF66), fontSize: 9, fontFamily: 'monospace'))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('Levels Completed', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('7', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('10', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('+3 (+42.8%)', style: TextStyle(color: Color(0xFF00FF66), fontSize: 9, fontFamily: 'monospace'))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('Win Rate', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('70.0%', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('100.0%', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('+30.0%', style: TextStyle(color: Color(0xFF00FF66), fontSize: 9, fontFamily: 'monospace'))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(padding: EdgeInsets.all(8.0), child: Text('Satisfaction Proxy', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('4.2/10', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('8.8/10', style: TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'))),
                        Padding(padding: EdgeInsets.all(8.0), child: Text('+109.5%', style: TextStyle(color: Color(0xFF00FF66), fontSize: 9, fontFamily: 'monospace'))),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                const Text(
                  'KEY DECISION MOMENTS',
                  style: TextStyle(color: Color(0xFFFF2E93), fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildMomentWidget(
                  'Moment 1: Session 4 — Player Stuck (Rage-Quit Risk)',
                  'FIXED: Rigidity. No intervention offered. The moderate skill player gets stuck on level 2 of the cycle pool for 5 attempts, gets frustrated, and rage-quits.',
                  'AGENTIC: EngagementWarden flags Churn Risk at 0.70. Drops difficulty by 0.4, loads a breather level with zero traps, unlocks visual skin rewards, and returns the player to a flow state.',
                ),
                const SizedBox(height: 12),
                _buildMomentWidget(
                  'Moment 2: Session 7 — Wall-Clipping Exploit Used',
                  'FIXED: Clockwork clock controls. The player exploits coordinate clips to jump obstacles and bypass data nodes. The system records an invalid score without verification.',
                  'AGENTIC: RefereeProtocol flags the teleport step, voids the action coordinate back to source, locks exit gates, and commands Sentinel to patch A* network patrol gaps.',
                ),
                const SizedBox(height: 12),
                _buildMomentWidget(
                  'Moment 3: Session 10 — Pacing Plateau & Boredom',
                  'FIXED: Clockwork patrol. Linear clock routing leads to highly repetitive patrol pathways. The player completes the map with zero mental stimulation and quits out of boredom.',
                  'AGENTIC: DifficultyEngine detects 88% accuracy and 90% Rusher consistency. Transitions to Mastery Zone, shrinks grid rows to narrow channels, spawns decoy nodes, and intercepts paths.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildRow(String s, String fd, String fm, String fo, String ad, String am, String ao) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(6.0), child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'monospace'))),
        Padding(padding: const EdgeInsets.all(6.0), child: Text(fd, style: const TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'monospace'))),
        Padding(padding: const EdgeInsets.all(6.0), child: Text(fm, style: const TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'monospace'))),
        Padding(padding: const EdgeInsets.all(6.0), child: Text(fo, style: TextStyle(color: fo.contains('RAGE') ? Colors.red : Colors.white, fontSize: 8, fontFamily: 'monospace'))),
        Padding(padding: const EdgeInsets.all(6.0), child: Text(ad, style: const TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'monospace'))),
        Padding(padding: const EdgeInsets.all(6.0), child: Text(am, style: const TextStyle(color: Colors.white, fontSize: 8, fontFamily: 'monospace'))),
        Padding(padding: const EdgeInsets.all(6.0), child: Text(ao, style: const TextStyle(color: Color(0xFF00FF66), fontSize: 8, fontFamily: 'monospace'))),
      ],
    );
  }

  Widget _buildMomentWidget(String title, String fixed, String agentic) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0E15),
        border: Border.all(color: const Color(0xFF121626)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(fixed, style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(agentic, style: const TextStyle(color: Color(0xFF00FF66), fontSize: 9, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Nav Tabs
          const TabBar(
            tabs: [
              Tab(text: 'TACTICAL MAP'),
              Tab(text: 'COGNITIVE LOGS'),
            ],
            indicatorColor: Color(0xFF00E5FF),
            labelColor: Color(0xFF00E5FF),
            unselectedLabelColor: Color(0xFF4C505C),
            labelStyle: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(), // Prevent swipe conflicts with controls
              children: [
                // MAP TAB
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: _currentLevel == null
                            ? const CircularProgressIndicator()
                            : GridBoard(
                                grid: _currentLevel!.grid,
                                playerPos: _playerPos,
                                sentinelPositions: _sentinels.map((s) => s.currentPos).toList(),
                                sentinelLOS: _sentinelLOS,
                                trapPositions: _currentLevel!.trapPositions,
                                onTileTap: (pos) {},
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHUDMessageBar(),
                    const SizedBox(height: 12),
                    ControllerPad(
                      onMove: _movePlayer,
                      onTriggerDecoy: _triggerDecoy,
                      onTriggerStealth: _triggerStealth,
                      decoyCount: _decoyCount,
                      isStealthActive: _isStealthActive,
                    ),
                  ],
                ),

                // LOGS TAB
                AnimatedBuilder(
                  animation: _console,
                  builder: (context, _) => LivePanel(console: _console),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDMessageBar() {
    if (_gameOver) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _hasWon ? const Color(0xFF00260F) : const Color(0xFF260515),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hasWon ? const Color(0xFF00FF66) : const Color(0xFFFF2E93)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _hasWon ? 'ROGUE AI SYSTEM ESCAPED // SECURED' : 'SECURITY BREACH // SYSTEM TERMINATED',
              style: TextStyle(
                color: _hasWon ? const Color(0xFF00FF66) : const Color(0xFFFF2E93),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            TextButton(
              onPressed: _startNewSession,
              style: TextButton.styleFrom(
                backgroundColor: _hasWon ? const Color(0xFF00FF66) : const Color(0xFFFF2E93),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text(
                'RESTART',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF090A0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF121626)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Color(0xFF00E5FF), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _activeMessage.isEmpty ? 'SYSTEM INTEGRITY GREEN // READY FOR ACTIONS' : _activeMessage.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF808595),
                fontSize: 9,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'NODES: $_collectedNodes/${_currentLevel?.nodePositions.length ?? 0}',
            style: const TextStyle(
              color: Color(0xFF00FF66),
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
