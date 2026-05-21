# MINDMAZE: The Adaptive Intelligence Arena
## Technical Architecture & Agent Specification Document

This document defines the system-level design, multi-agent communication topology, state schemas, and privacy standards for **MINDMAZE: The Adaptive Intelligence Arena**, a grid-based AI-stealth puzzle game.

In MINDMAZE, the player is a rogue AI navigating a procedurally generated 12x12 facility. They are hunted by a Sentinel AI. Every decision made by the system’s six background agents is streamed live in a side panel, giving the player full visibility into the AI's cognitive loop.

---

## 1. System Topology & Data Flow

MINDMAZE operates on a strict unidirectional feedback loop:
```
Player Action ──> MetricsCollector ──> [ All 6 Agents ] ──> GameStateUpdate ──> Render
```

1. **Player Action**: The player (Rogue AI) performs an action (move, hack, hide, ping).
2. **MetricsCollector**: Intercepts the action, telemetry, current grid coordinates, timing, and performance histories.
3. **Multi-Agent Evaluation**:
   - The **6 Antigravity Agents** receive the updated metrics payload simultaneously.
   - Agents perform cognitive operations synchronously or asynchronously, updating their internal states.
   - The `GridArchitectAgent` and `QualityControlAgent` collaborate out-of-band to prepare new levels during stage transitions, while the others operate in real-time.
4. **GameStateUpdate**: Aggregates all six agents' structured traces (`observe`, `infer`, `decide`, `act`, `evaluate`) and resolves movements, score updates, active alerts, trap triggers, and referee violations.
5. **Render**: Draws the visual state of the 12x12 grid and streams the full agent reasoning log to the live side panel.

---

## 2. Agent Communication Graph

The following JSON graph maps the nodes and directed communication edges among the system components. It defines how telemetry flows, how agents coordinate on difficulty and layout generation, and how traces reach the state update.

```json
{
  "graph": {
    "version": "1.0.0",
    "name": "MINDMAZE Agent Communication Graph",
    "nodes": [
      {
        "id": "player_interface",
        "label": "Player Interface",
        "role": "User Input Client",
        "description": "Receives grid navigation inputs and stealth actions from the user."
      },
      {
        "id": "metrics_collector",
        "label": "Metrics Collector",
        "role": "Telemetry & Aggregation Engine",
        "description": "Collects real-time action intervals, spatial heatmaps, failure rates, and window focus tracking."
      },
      {
        "id": "grid_architect_agent",
        "label": "GridArchitectAgent",
        "role": "Procedural Generator Agent",
        "description": "Generates 12x12 levels based on seeds and dynamic difficulty constraints."
      },
      {
        "id": "quality_control_agent",
        "label": "QualityControlAgent",
        "role": "Validation and Solver Agent",
        "description": "Uses pathfinding algorithms (BFS/Dijkstra) to guarantee solvable, fair, and novel level generations."
      },
      {
        "id": "sentinel_agent",
        "label": "SentinelAgent",
        "role": "Dynamic Hunter Adversary Agent",
        "description": "Hunts the player, predicts routes, establishes search sweeps, and intercepts escape corridors."
      },
      {
        "id": "difficulty_engine",
        "label": "DifficultyEngine",
        "role": "Dynamic Stress & Pacing Tuner",
        "description": "Processes performance profiles to scale Sentinel stats, trap density, and node distributions in real-time."
      },
      {
        "id": "engagement_warden",
        "label": "EngagementWarden",
        "role": "Retention & Intervention Agent",
        "description": "Analyzes play patterns to prevent frustration or boredom by injecting in-game events or relief."
      },
      {
        "id": "referee_protocol",
        "label": "RefereeProtocol",
        "role": "Security, Integrity & Rule Auditor",
        "description": "Verifies score structures, detects visual/coordinate hacks, and confirms level exit validations."
      },
      {
        "id": "game_state_update",
        "label": "Game State Update",
        "role": "Master Orchestration and Resolve System",
        "description": "Combines current layouts, active coordinate positions, active events, and 6-Agent cognitive state logs."
      },
      {
        "id": "render_pipeline",
        "label": "Render Pipeline",
        "role": "Double-Pane Visualizer Client",
        "description": "Renders the 12x12 playing board and prints the agent reasoning logs in the live side panel."
      }
    ],
    "edges": [
      {
        "source": "player_interface",
        "target": "metrics_collector",
        "label": "DISPATCH_ACTION",
        "payload": {
          "type": "ActionTelemetry",
          "fields": ["actionType", "coordinates", "timestamp", "inputLatency"]
        }
      },
      {
        "source": "metrics_collector",
        "target": "sentinel_agent",
        "label": "PROVIDE_SPATIAL_METRICS",
        "payload": {
          "type": "SpatialTelemetry",
          "fields": ["playerPosition", "lastKnownPosition", "noiseLocation", "visionLines"]
        }
      },
      {
        "source": "metrics_collector",
        "target": "difficulty_engine",
        "label": "PROVIDE_PERFORMANCE_METRICS",
        "payload": {
          "type": "PerformanceTelemetry",
          "fields": ["winRate", "deathCount", "timeInSentinelLOS", "levelDurationSeconds"]
        }
      },
      {
        "source": "metrics_collector",
        "target": "engagement_warden",
        "label": "PROVIDE_ENGAGEMENT_METRICS",
        "payload": {
          "type": "BehavioralTelemetry",
          "fields": ["idleDurationSeconds", "retrySequenceCount", "focusLostEvents", "inputFrequencyHz"]
        }
      },
      {
        "source": "metrics_collector",
        "target": "referee_protocol",
        "label": "PROVIDE_SECURE_INPUTS",
        "payload": {
          "type": "SecurityTelemetry",
          "fields": ["inputSequence", "memoryVerificationHashes", "coordinateHopDeltas"]
        }
      },
      {
        "source": "difficulty_engine",
        "target": "grid_architect_agent",
        "label": "APPLY_GENERATION_MODIFIERS",
        "payload": {
          "type": "GenerationParameters",
          "fields": ["targetComplexityMultiplier", "minTrapDensity", "minPathsToExit"]
        }
      },
      {
        "source": "difficulty_engine",
        "target": "sentinel_agent",
        "label": "APPLY_HUNTER_BUFFS",
        "payload": {
          "type": "HunterParameters",
          "fields": ["movementSpeed", "visionRadius", "searchAggressionCoefficient"]
        }
      },
      {
        "source": "grid_architect_agent",
        "target": "quality_control_agent",
        "label": "SUBMIT_GENERATED_LEVEL",
        "payload": {
          "type": "RawLevelMap",
          "fields": ["seed", "gridArray", "spawnCoordinates", "exitCoordinates", "nodesList"]
        }
      },
      {
        "source": "quality_control_agent",
        "target": "grid_architect_agent",
        "label": "VALIDATION_FEEDBACK",
        "payload": {
          "type": "ValidationResult",
          "fields": ["isApproved", "rejectionReason", "entropyRating", "noveltyScore"]
        }
      },
      {
        "source": "quality_control_agent",
        "target": "game_state_update",
        "label": "COMMIT_APPROVED_LEVEL",
        "payload": {
          "type": "ApprovedLevelMap",
          "fields": ["gridArray", "exitCoordinates", "safetyExitPathLength"]
        }
      },
      {
        "source": "engagement_warden",
        "target": "game_state_update",
        "label": "TRIGGER_ENGAGEMENT_INTERVENTION",
        "payload": {
          "type": "EngagementIntervention",
          "fields": ["interventionType", "messageBroadcast", "gridEffectParameters"]
        }
      },
      {
        "source": "referee_protocol",
        "target": "game_state_update",
        "label": "COMMIT_SECURITY_AUDIT",
        "payload": {
          "type": "SecurityAuditStatus",
          "fields": ["isValidated", "rollbackSignal", "exploitLogClassification"]
        }
      },
      {
        "source": "sentinel_agent",
        "target": "game_state_update",
        "label": "DISPATCH_HUNTER_ACTION",
        "payload": {
          "type": "SentinelActionState",
          "fields": ["nextCoordinate", "currentPathList", "alertLevel"]
        }
      },
      {
        "source": "sentinel_agent",
        "target": "game_state_update",
        "label": "STREAM_AGENT_TRACE",
        "payload": { "type": "CognitiveTrace", "fields": ["observe", "infer", "decide", "act", "evaluate"] }
      },
      {
        "source": "grid_architect_agent",
        "target": "game_state_update",
        "label": "STREAM_AGENT_TRACE",
        "payload": { "type": "CognitiveTrace", "fields": ["observe", "infer", "decide", "act", "evaluate"] }
      },
      {
        "source": "quality_control_agent",
        "target": "game_state_update",
        "label": "STREAM_AGENT_TRACE",
        "payload": { "type": "CognitiveTrace", "fields": ["observe", "infer", "decide", "act", "evaluate"] }
      },
      {
        "source": "difficulty_engine",
        "target": "game_state_update",
        "label": "STREAM_AGENT_TRACE",
        "payload": { "type": "CognitiveTrace", "fields": ["observe", "infer", "decide", "act", "evaluate"] }
      },
      {
        "source": "engagement_warden",
        "target": "game_state_update",
        "label": "STREAM_AGENT_TRACE",
        "payload": { "type": "CognitiveTrace", "fields": ["observe", "infer", "decide", "act", "evaluate"] }
      },
      {
        "source": "referee_protocol",
        "target": "game_state_update",
        "label": "STREAM_AGENT_TRACE",
        "payload": { "type": "CognitiveTrace", "fields": ["observe", "infer", "decide", "act", "evaluate"] }
      },
      {
        "source": "game_state_update",
        "target": "render_pipeline",
        "label": "PUSH_FRAME_UPDATE",
        "payload": {
          "type": "MasterFrameData",
          "fields": ["gridState", "playerCoordinates", "sentinelCoordinates", "score", "activeInterventions", "cognitiveTraceLogs"]
        }
      }
    ]
  }
}
```

---

## 3. Cognitive Agent State Schemas

Every agent outputs its internal processing loop using five core dimensions: **Observe**, **Infer**, **Decide**, **Act**, and **Evaluate**. 

Below is the complete state schema specification. Each agent block details the data structure in a JSON schema standard.

### 3.1. SentinelAgent
Combines adversarial telemetry with dynamic heuristics to hunt down the player rogue AI.

```ts
interface SentinelAgentSchema {
  agent: "SentinelAgent";
  timestamp: string; // ISO-8601 or T+Relative time format (e.g. "T+00:42")
  
  observe: {
    playerPositionKnown: boolean;
    playerCoordinates: { x: number; y: number } | null;
    lastKnownPosition: { x: number; y: number } | null;
    sentinelCoordinates: { x: number; y: number };
    acousticPings: Array<{ x: number; y: number; intensity: number }>;
    activeLineOfSightPolygon: Array<{ x: number; y: number }>;
    ambientTrapTriggers: Array<{ x: number; y: number; timeSinceTrigger: number }>;
  };

  infer: {
    inferredPlayerArchetype: "speedrunner" | "ghost" | "cautious" | "chaotic";
    playerDestinationProbabilityHeatmap: Array<{ x: number; y: number; probability: number }>;
    predictedNextPlayerMove: { x: number; y: number };
    stealthDecayRate: number; // Ratio of player noise generation
  };

  decide: {
    tacticalMode: "patrol" | "investigate_noise" | "intercept" | "flee_to_charge";
    targetWaypoint: { x: number; y: number };
    plannedPath: Array<{ x: number; y: number }>;
    interceptionSuccessEstimate: number; // Percentage (0.00 to 1.00)
  };

  act: {
    nextMovementStep: { dx: number; dy: number }; // Directional offset
    sensorPingDispatched: boolean;
    searchlightFocusAngleDegrees: number;
    trapActivationCall: { targetCoordinate: { x: number; y: number } } | null;
  };

  evaluate: {
    distanceDeltaToPlayer: number; // Positive is closer, negative is farther
    predictionAccuracyScore: number; // 1.0 if actual player move matches prediction
    patrolEfficiencyCoefficient: number; // Ratio of area explored vs time
    tacticalPathDeviationMetric: number; // Deviation from optimal path due to obstacles
  };
}
```

---

### 3.2. GridArchitectAgent
Acts as the procedural designer, synthesizing the grid array using parameters provided by the DifficultyEngine.

```ts
interface GridArchitectAgentSchema {
  agent: "GridArchitectAgent";
  timestamp: string;

  observe: {
    targetDifficultyLevel: number; // Scales 1 to 10
    gridDimensions: { width: number; height: number }; // 12x12 default
    currentSeed: string;
    historicPlayerLayoutPreference: Array<string>; // Types of levels player thrives in
    requiredSpecialRooms: Array<"server_room" | "trap_corridor" | "power_node" | "exit">;
  };

  infer: {
    optimalDeadEndCount: number;
    idealChokePointsCount: number;
    estimatedMinimumStepsToExit: number;
    spatialComplexityTarget: number; // Entropy target (0.0 to 1.0)
  };

  decide: {
    placementStrategy: "cellular_automata" | "mst_spanning_tree" | "hybrid_maze";
    criticalPoints: {
      spawn: { x: number; y: number };
      exit: { x: number; y: number };
      powerNodes: Array<{ x: number; y: number }>;
      hazards: Array<{ x: number; y: number; hazardType: string }>;
    };
    wallDistributionProfile: "dense" | "open" | "labyrinthine";
  };

  act: {
    generatedGridMatrix: Array<Array<{
      tileType: "wall" | "floor" | "trap" | "node" | "exit" | "spawn";
      intensity: number; // e.g. for trap lethality levels
      id: string;
    }>>;
    seedUsed: string;
  };

  evaluate: {
    generatedDensityRatio: number; // Wall-to-floor percentage
    symmetryCoefficient: number;
    pathBranchingFactor: number; // Average node connection rate
    spatialEntropyScore: number; // Verification of true grid unpredictability
  };
}
```

---

### 3.3. QualityControlAgent
Acts as the automated puzzle validator. It runs full simulated plays (BFS/Dijkstra search) to ensure generated levels are valid and fair before deployment.

```ts
interface QualityControlAgentSchema {
  agent: "QualityControlAgent";
  timestamp: string;

  observe: {
    submittedSeed: string;
    gridMatrix: Array<Array<{ tileType: string; id: string }>>;
    spawnPosition: { x: number; y: number };
    exitPosition: { x: number; y: number };
    nodePositions: Array<{ x: number; y: number }>;
  };

  infer: {
    shortestPathExitDistanceSteps: number;
    alternateRoutesCount: number;
    inescapableTrapTrapsDetected: Array<{ x: number; y: number }>;
    bottleneckCoordinates: Array<{ x: number; y: number }>;
    deadEndTrapsRatio: number;
  };

  decide: {
    levelValidationState: "APPROVED" | "REJECTED_UNSOLVABLE" | "REJECTED_UNFAIR" | "REJECTED_TRAP_HEAVY";
    recommendedRebuildAction: "none" | "reduce_walls" | "relocate_exit" | "remove_overlapping_traps";
    assignedCalibratedDifficulty: number; // Rating based on shortest path vs active nodes
  };

  act: {
    validationApprovalFlag: boolean;
    structuralHeatmapOverlay: Array<Array<number>>; // Value of path traversal frequencies
    feedbackDirectives: Array<string>;
  };

  evaluate: {
    solverAlgorithmCyclesCount: number;
    estimatedSolverConfidence: number; // 0.00 to 1.00 accuracy of solver assessment
    noveltyScoreVsDatabase: number; // Structural difference from previously saved layouts
  };
}
```

---

### 3.4. DifficultyEngine
Tracks player capability metrics to tune system speed, vision range, trap density, and node counts in real-time.

```ts
interface DifficultyEngineSchema {
  agent: "DifficultyEngine";
  timestamp: string;

  observe: {
    fiveCoreMetrics: {
      completionTimeRatio: number; // Actual time vs QC Agent estimated time
      playerDeathRateRatio: number; // Total failures per total moves
      sentinelAlertTimePercentage: number; // Ratio of ticks spent in Line of Sight (LOS)
      nodeCollectionDensity: number; // Percentage of optional node data collected
      backtrackFrequency: number; // Re-navigating previously crossed tiles
    };
    activeSystemDifficultyIndex: number; // Scale 1 to 10
  };

  infer: {
    estimatedPlayerSkillLevel: number; // 0.00 (novice) to 1.00 (super-intelligence)
    playerStressIndex: number; // Estimated stress based on move intervals and close escapes
    difficultyMisalignmentFactor: number; // Divergence between stress and system target difficulty
  };

  decide: {
    tuningDirection: "INCREASE_DIFFICULTY" | "DECREASE_DIFFICULTY" | "MAINTAIN_DIFFICULTY";
    targetTuningMagnitude: number; // Absolute scaling offset
    systemAdjustments: {
      sentinelSpeedMultiplier: number;
      sentinelVisionRangeCells: number;
      activeTrapDensityLimit: number;
      powerNodesCountAllocation: number;
    };
  };

  act: {
    appliedStatModifiers: {
      sentinelSpeed: number;
      sentinelVision: number;
      trapDensity: number;
      nodeCount: number;
    };
    difficultyAlertLog: string;
  };

  evaluate: {
    priorStateAdjustmentLatency: number; // Seconds since last difficulty state shift
    stressResponseSettlingTimeSeconds: number; // Time it took player to stabilize stress after tuning
    varianceControlAccuracyIndex: number; // Effectiveness of pacing bounds
  };
}
```

---

### 3.5. EngagementWarden
Responsible for player retention, detecting user frustration (churn risk), and firing adaptive supportive protocols.

```ts
interface EngagementWardenSchema {
  agent: "EngagementWarden";
  timestamp: string;

  observe: {
    sessionDurationSeconds: number;
    levelRetryCount: number;
    inputSequenceDelayAverageMs: number; // High delays point to fatigue or distraction
    focusLostEventCount: number; // Triggers if player tabs away from window
    rageQuitIndications: Array<{ eventType: string; timestamp: string }>;
  };

  infer: {
    playerEngagementStatus: "hyper_engaged" | "neutral" | "bored" | "highly_frustrated";
    estimatedChurnRiskPercentage: number; // Probability player will quit the game session
    cognitiveLoadProfile: "flow" | "overload" | "underload";
  };

  decide: {
    requiresIntervention: boolean;
    selectedInterventionProtocol: "NONE" | "REVEAL_SURROUNDINGS" | "SPAWN_ESCAPE_NODES" | "NERF_SENTINEL_VISION" | "SUPPORTIVE_BROADCAST";
    interventionDecisionsLog: string;
  };

  act: {
    activeInterventionSignal: boolean;
    inGameNarrativeLogPayload: {
      narrativeText: string; // Message sent to the side panel
      visualOverlayEvent: string | null;
    };
    gridInterventionCoordinate: { x: number; y: number } | null;
  };

  evaluate: {
    interventionResponseTimeSeconds: number;
    retentionImprovementDelta: number; // Difference in metrics post-intervention vs pre-intervention
    fatigueRecedenceIndicator: boolean; // Indicates if delay between inputs stabilized
  };
}
```

---

### 3.6. RefereeProtocol
Validates every score calculation and movement action, detecting noclip hacks, speed exploits, and memory tampering.

```ts
interface RefereeProtocolSchema {
  agent: "RefereeProtocol";
  timestamp: string;

  observe: {
    claimedScore: number;
    claimedLevelCompletionTimeSeconds: number;
    playerActionCoordinatesSequence: Array<{ x: number; y: number; timeOffset: number }>;
    activePhysicsConstants: { maxVelocityTilesPerSecond: number; allowedHops: number };
    stateSecurityTokenHash: string;
  };

  infer: {
    calculatedMoveVelocityVariance: number;
    wallCollisionOverlapRatio: number; // Any value > 0 indicates noclip
    heuristicExploitProbability: number; // Percent chance of game hacking
    timeCompressionRatio: number; // Telemetry time scale vs real-time clock
  };

  decide: {
    gameIntegrityStatus: "SECURE" | "SUSPICIOUS" | "EXPLOIT_CONFIRMED";
    correctiveActionRequired: "none" | "rollback_to_secure_tick" | "invalidate_score" | "flag_suspicious_activity";
    violatedRuleCodesList: Array<string>;
  };

  act: {
    integrityApprovalStatus: boolean;
    stateRollbackFrameIndex: number | null;
    validationCertificate: string; // Cryptographic validation token signed by Referee
  };

  evaluate: {
    integrityCalculationOverheadMs: number;
    falsePositiveIndicatorFlag: boolean;
    verificationFidelityPercentage: number;
  };
}
```

---

## 4. Privacy Policy & Data Handling Charter

MINDMAZE uses extensive real-time telemetry to power its adaptive gameplay. Maintaining trust and protecting player data is foundational. This Privacy Policy outlines our strict boundaries on data storage, anonymization, and collection.

```
                  ┌──────────────────────────────────────────┐
                  │          MINDMAZE TELEMETRY DATA         │
                  └────────────────────┬─────────────────────┘
                                       │
            ┌──────────────────────────┼──────────────────────────┐
            ▼                          ▼                          ▼
 ┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
 │       STORED        │    │     ANONYMIZED      │    │        NEVER        │
 │    (Persistent)     │    │      (Session)      │    │      COLLECTED      │
 ├─────────────────────┤    ├─────────────────────┤    ├─────────────────────┤
 │ • Cryptographic     │    │ • Coordinates       │    │ • Email / Name / PII│
 │   User Hash         │    │   Telemetry         │    │ • Keystroke Content │
 │ • Level Seeds       │    │ • Action Intervals  │    │ • Local File Names  │
 │ • Verified Scores   │    │ • Agent Reason logs │    │ • Hardware IDs      │
 │ • Achievement IDs   │    │ • Stress Indicators │    │ • IP Addresses      │
 └─────────────────────┘    └─────────────────────┘    └─────────────────────┘
```

### 4.1. What Is Stored (Persistent Data)
We store the minimum possible data required to preserve high-score validity, track achievements, and improve procedural generation models. This data is securely stored and never shared:
* **Cryptographic User Hash**: A standard SHA-256 hashed signature combining local browser attributes. Used for anonymous leaderboard tracking without collecting emails or usernames.
* **Level Generation Seeds**: The layout seeds that players successfully solve or fail. Used to build a shared dataset of high-quality puzzle levels.
* **Verified Scores**: High scores validated by the `RefereeProtocol` containing completion times, node counts, and level numbers.
* **Achievement Metadata**: Boolean progression flags (e.g. `is_sentinel_hacked_level_10`) indicating game achievements.
* **Agent Performance Logs (Aggregated)**: Meta-analytics (e.g., average difficulty rating, failure paths) used to calibrate the neural weights of future puzzle engines.

### 4.2. What Is Anonymized (Session/Ephemeral Data)
These temporary metrics are processed in local volatile memory (RAM) or anonymized before sending to telemetry endpoints. They are detached from any persistent identifiers:
* **Grid Navigation Telemetry**: Grid coordinates of player paths are analyzed to build positional heatmaps. This data is aggregated across all play sessions to optimize wall generation patterns.
* **Action Intervals & Timings**: In-game speed metrics and delay profiles. This is anonymized into general curves to refine the `DifficultyEngine`'s stress prediction models.
* **Agent Trace Logs**: Raw outputs from `observe`, `infer`, `decide`, `act`, and `evaluate`. These logs are kept for diagnostic tuning of agent reasoning patterns, separated from specific player profiles.
* **Interface Delays**: Focus lost counts and timing variances, aggregated as session-level percentage points.

### 4.3. What Is Never Collected (Absolute Security Boundary)
The MINDMAZE engine is designed to operate safely. We enforce strict technical barriers that prevent the collection or transmission of:
* **Personally Identifiable Information (PII)**: We do not collect emails, real names, phone numbers, or credit card details. There is no account sign-up system; player identities exist solely as localized, one-way hashes.
* **Raw Keyboard Input Details**: We process strictly discrete spatial game commands (Up, Down, Left, Right, Action keys). We never capture text, input buffer details, or any keycodes outside game control scopes.
* **Precise Geographic Location**: We do not capture IP addresses. Any geo-lookup is performed entirely in memory at the edge to determine simple region codes (e.g., EU, US, AP), and the source IP is instantly dropped.
* **Local Workspace & Environment Telemetry**: We never read file structures, local environment paths, running process lists, browser tabs, or other device profiles.
* **Device Hardware Serial Numbers**: We do not collect MAC addresses, device serial keys, or hardware-specific GUIDs.

---

### 4.4. Compliance & Consent Charter

1. **Local-First Processing**: 95% of all agent reasoning calculations run locally on the client’s CPU.
2. **Opt-Out Control**: Players can disable remote analytic uploads inside the game interface. Doing so isolates all telemetry inside local storage (`localStorage`).
3. **Data Portability**: Players can download their active local profile (`.json`) containing their level completion history, or clear their local record entirely with a single click.

---
*MINDMAZE System Architecture Specification - Defined by Lead Architect Model (Antigravity).*
