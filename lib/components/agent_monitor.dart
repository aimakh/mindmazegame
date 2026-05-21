import 'package:flutter/material.dart';
import '../models/agent_state.dart';
import '../models/level_data.dart';
import '../models/game_metrics.dart';
import '../agents/supporting_agents.dart';

class AgentMonitor extends StatefulWidget {
  final LevelLayout? level;
  final GameMetrics metrics;
  final int turnCount;
  final int collectedNodes;
  final int claimedScore;
  final int sessionNumber;
  final bool isStealthActive;

  const AgentMonitor({
    super.key,
    required this.level,
    required this.metrics,
    required this.turnCount,
    required this.collectedNodes,
    required this.claimedScore,
    required this.sessionNumber,
    required this.isStealthActive,
  });

  @override
  State<AgentMonitor> createState() => _AgentMonitorState();
}

class _AgentMonitorState extends State<AgentMonitor> with SingleTickerProviderStateMixin {
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant AgentMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Flash HUD when turn changes or significant state moves occur
    if (widget.turnCount != oldWidget.turnCount) {
      _flashController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int totalNodes = widget.level?.nodePositions.length ?? 5;
    double nodeRatio = widget.collectedNodes / (totalNodes == 0 ? 1 : totalNodes);
    
    // Simulate real-time par clock (e.g. counting down from 90)
    int elapsed = (widget.turnCount * 2.5).toInt();
    int timeRemaining = (90 - elapsed).clamp(0, 90);
    String timeStr = '00:${timeRemaining.toString().padLeft(2, '0')}';

    return AnimatedBuilder(
      animation: _flashController,
      builder: (context, child) {
        double flashVal = _flashController.value;
        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF090A0F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF1B2030),
                const Color(0xFF00E5FF),
                flashVal,
              )!,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0E15),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MINDMAZE AGENT MONITOR',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Session ${widget.sessionNumber} · Level ${widget.level?.levelId ?? 'LVL-0047'}',
                      style: const TextStyle(
                        color: Color(0xFF808595),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1B2030), height: 1),

              // Sentinel Agent Segment
              _buildMonitorItem(
                title: '● SENTINEL AGENT',
                status: widget.isStealthActive ? 'BLIND' : 'LIVE',
                statusColor: widget.isStealthActive ? const Color(0xFFFFB300) : const Color(0xFF00FF66),
                lines: [
                  'Observing: Preferred ${widget.metrics.evaluatePreferredDirection()}',
                  'Classifying: Rusher (82%)',
                  'Action: Intercept exit corridor',
                ],
              ),
              const Divider(color: Color(0xFF1B2030), height: 1),

              // Difficulty Engine Segment
              _buildMonitorItem(
                title: '● DIFFICULTY ENGINE',
                status: 'LIVE',
                statusColor: const Color(0xFF00FF66),
                lines: [
                  'Score: 1.095 ↑',
                  'Zone: MASTERY',
                  'Next: Shrink rows by 2',
                ],
              ),
              const Divider(color: Color(0xFF1B2030), height: 1),

              // Engagement Warden Segment
              _buildMonitorItem(
                title: '● ENGAGEMENT WARDEN',
                status: 'OK',
                statusColor: const Color(0xFF00FF66),
                lines: [
                  'Session: 14.2 min ↑',
                  'Churn risk: 0.18 ✓',
                  'Satisfaction: 8.4/10',
                ],
              ),
              const Divider(color: Color(0xFF1B2030), height: 1),

              // QC Agent Segment
              _buildMonitorItem(
                title: '● QC AGENT',
                status: 'PASS',
                statusColor: const Color(0xFF00FF66),
                lines: [
                  'Level ${widget.level?.levelId ?? 'LVL-0047'} validated',
                  '6/6 checks passed',
                ],
              ),
              const Divider(color: Color(0xFF1B2030), height: 1),

              // Referee Segment
              _buildMonitorItem(
                title: '● REFEREE',
                status: 'WATCH',
                statusColor: const Color(0xFFFFB300),
                lines: [
                  'Speed check: monitoring',
                  'Score formula: valid',
                ],
              ),
              const Divider(color: Color(0xFF1B2030), height: 1),

              // Progress bars & live metrics
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'METRICS LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMetricBar('Time Remaining', timeRemaining / 90.0, timeStr, const Color(0xFF00E5FF)),
                    _buildMetricBar('Node Harvest', nodeRatio, '${widget.collectedNodes}/$totalNodes', const Color(0xFF00FF66)),
                    _buildMetricBar('Optimal Accuracy', 0.84, '84%', const Color(0xFFFFB300)),
                    _buildMetricBar('Retry Penalties', 0.0, '0', const Color(0xFFFF2E93)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonitorItem({
    required String title,
    required String status,
    required Color statusColor,
    required List<String> lines,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor, width: 0.5),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: Color(0xFF808595),
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, double ratio, String valText, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF808595), fontSize: 8, fontFamily: 'monospace'),
              ),
              Text(
                valText,
                style: TextStyle(color: barColor, fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Container(
              height: 4,
              color: const Color(0xFF121626),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    color: barColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
