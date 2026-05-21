import 'package:flutter/foundation.dart';

class AgentTrace {
  final String agent;
  final String timestamp;
  final String observe;
  final String infer;
  final String decide;
  final String act;
  final String evaluate;

  const AgentTrace({
    required this.agent,
    required this.timestamp,
    required this.observe,
    required this.infer,
    required this.decide,
    required this.act,
    required this.evaluate,
  });

  Map<String, String> toJson() {
    return {
      'agent': agent,
      'timestamp': timestamp,
      'observe': observe,
      'infer': infer,
      'decide': decide,
      'act': act,
      'evaluate': evaluate,
    };
  }

  @override
  String toString() {
    return '[$timestamp] $agent:\n'
        '  OBSERVE: $observe\n'
        '  INFER: $infer\n'
        '  DECIDE: $decide\n'
        '  ACT: $act\n'
        '  EVALUATE: $evaluate';
  }
}

class MasterAgentConsole extends ChangeNotifier {
  final List<AgentTrace> _traceHistory = [];
  final Map<String, AgentTrace> _latestAgentTraces = {};

  List<AgentTrace> get traceHistory => List.unmodifiable(_traceHistory);
  Map<String, AgentTrace> get latestAgentTraces => Map.unmodifiable(_latestAgentTraces);

  /// Dispatch a new trace packet from an agent, refreshing listeners.
  void dispatchTrace(AgentTrace trace) {
    _traceHistory.add(trace);
    _latestAgentTraces[trace.agent] = trace;
    
    // Cap memory logs to prevent session overflow
    if (_traceHistory.length > 300) {
      _traceHistory.removeAt(0);
    }
    
    notifyListeners();
  }

  void clearLogs() {
    _traceHistory.clear();
    _latestAgentTraces.clear();
    notifyListeners();
  }
}
