import 'package:flutter/material.dart';
import '../models/agent_state.dart';

class LivePanel extends StatefulWidget {
  final MasterAgentConsole console;

  const LivePanel({super.key, required this.console});

  @override
  State<LivePanel> createState() => _LivePanelState();
}

class _LivePanelState extends State<LivePanel> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    widget.console.addListener(_autoScrollToBottom);
  }

  @override
  void dispose() {
    widget.console.removeListener(_autoScrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  List<AgentTrace> _getFilteredHistory() {
    List<AgentTrace> fullList = widget.console.traceHistory;
    if (_selectedFilter == 'ALL') return fullList;
    
    return fullList.where((trace) {
      if (_selectedFilter == 'SENTINELS') return trace.agent.startsWith('SentinelAgent');
      if (_selectedFilter == 'ARCHITECT') return trace.agent == 'GridArchitectAgent';
      if (_selectedFilter == 'DIFFICULTY') return trace.agent == 'DifficultyEngine';
      if (_selectedFilter == 'ENGAGEMENT') return trace.agent == 'EngagementWarden';
      if (_selectedFilter == 'REFEREE') return trace.agent == 'RefereeProtocol';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<AgentTrace> logs = _getFilteredHistory();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090A0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2030), width: 2),
      ),
      child: Column(
        children: [
          // Header Bar with Filter Tabs
          _buildFilterBar(),
          
          const Divider(color: Color(0xFF1B2030), height: 1),
          
          // Terminal Log Output
          Expanded(
            child: logs.isEmpty
                ? _buildEmptyTerminal()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      return _buildTerminalCard(logs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    List<String> tabs = ['ALL', 'SENTINELS', 'ARCHITECT', 'DIFFICULTY', 'ENGAGEMENT', 'REFEREE'];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          String tab = tabs[index];
          bool isSelected = _selectedFilter == tab;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = tab;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: isSelected ? _resolveAccentColor(tab).withOpacity(0.1) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? _resolveAccentColor(tab) : Colors.transparent,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isSelected ? _resolveAccentColor(tab) : const Color(0xFF808595),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _resolveAccentColor(String tab) {
    if (tab == 'SENTINELS') return const Color(0xFFFF2E93);
    if (tab == 'ARCHITECT') return const Color(0xFF00E5FF);
    if (tab == 'DIFFICULTY') return const Color(0xFFFFB300);
    if (tab == 'ENGAGEMENT') return const Color(0xFFBD00FF);
    if (tab == 'REFEREE') return const Color(0xFF00FF66);
    return const Color(0xFF00E5FF); // ALL
  }

  Widget _buildEmptyTerminal() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal, color: Color(0xFF1B2030), size: 48),
          SizedBox(height: 8),
          Text(
            'CONSOLE SECURE // AWAITING STREAM...',
            style: TextStyle(
              color: Color(0xFF4C505C),
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalCard(AgentTrace trace) {
    Color agentColor = _resolveAccentColor(trace.agent.startsWith('Sentinel') ? 'SENTINELS' : trace.agent);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF121626)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Agent Identity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                trace.agent.toUpperCase(),
                style: TextStyle(
                  color: agentColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  shadows: [
                    Shadow(color: agentColor.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
              Text(
                trace.timestamp,
                style: const TextStyle(
                  color: Color(0xFF4C505C),
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF121626), height: 1),
          const SizedBox(height: 8),
          
          // Trace Steps
          _buildTraceLine('OBSERVE', trace.observe, const Color(0xFF808595)),
          _buildTraceLine('INFER', trace.infer, const Color(0xFFFFB300)),
          _buildTraceLine('DECIDE', trace.decide, const Color(0xFF00FF66)),
          _buildTraceLine('ACT', trace.act, const Color(0xFFFF2E93)),
          _buildTraceLine('EVALUATE', trace.evaluate, const Color(0xFFBD00FF)),
        ],
      ),
    );
  }

  Widget _buildTraceLine(String step, String content, Color contentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '  ${step.padRight(9)}: ',
              style: const TextStyle(
                color: Color(0xFF4C505C),
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: content,
              style: TextStyle(color: contentColor),
            ),
          ],
        ),
      ),
    );
  }
}
