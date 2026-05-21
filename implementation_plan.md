# Implementation Plan: MINDMAZE Flutter Game Client

This plan details the architecture and file layout to create a premium, mobile-first **Flutter application** for **MINDMAZE: The Adaptive Intelligence Arena**. The app features a playable 12x12 procedurally generated grid puzzle, dynamic adversarial pathfinding, live real-time metrics tracking, and a gorgeous, glowing neon console displaying the observable reasoning profiles of the six cognitive agents.

---

## Game Design & Visual System

*   **Aesthetic Theme**: High-fidelity dark mode with neon accent colors.
    *   *Primary (Dark)*: Deep obsidian black/navy (`0xFF090A0F`)
    *   *Rogue AI (Player)*: Vibrant Cyan/Teal (`0xFF00E5FF`)
    *   *Sentinel AI (Hunter)*: Hot Crimson/Magenta (`0xFFFF2E93`)
    *   *Data Nodes (Objectives)*: Electric Green (`0xFF00FF66`)
    *   *Traps & Hazards*: Neon Amber/Yellow (`0xFFFFB300`)
    *   *One-Way Doors*: Laser Violet (`0xFFBD00FF`)
*   **Layout**: Double-panel responsive system. On mobile, a tabbed interface or scroll view transitions between the **Tactical Grid Map** and the **AI Cognitive Console (Live Panel)**. On tablets/desktops, they sit side-by-side.

---

## Proposed System Architecture

```
                            ┌───────────────────────────────────┐
                            │            pubspec.yaml           │
                            └─────────────────┬─────────────────┘
                                              │
                                              ▼
                            ┌───────────────────────────────────┐
                            │            lib/main.dart          │
                            └─────────────────┬─────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
      ┌───────────────────────────┐ ┌───────────────────┐ ┌───────────────────────────┐
      │        lib/models/        │ │    lib/agents/    │ │      lib/components/      │
      ├───────────────────────────┤ ├───────────────────┤ ├───────────────────────────┤
      │ • agent_state.dart        │ │ • sentinel.dart   │ │ • grid_board.dart         │
      │ • level_data.dart         │ │ • architect.dart  │ │ • live_panel.dart         │
      │ • game_metrics.dart       │ └───────────────────┘ │ • controller_pad.dart     │
      └───────────────────────────┘                       └───────────────────────────┘
                                              │
                                              ▼
                            ┌───────────────────────────────────┐
                            │        lib/screens/game.dart      │
                            └───────────────────────────────────┘
```

### 1. File Structure Specifications

#### `pubspec.yaml`
Registers dependencies including standard Cupertino/Material libraries, state management (`provider` or standard inherited values), pathfinding helpers, and Google Fonts (`google_fonts` for typography visual excellence).

#### [lib/models/agent_state.dart](file:///c:/Users/HP/Desktop/mindmaze/lib/models/agent_state.dart) [NEW]
Contains structural schemas representing agent cognitive trace states:
*   `AgentTrace`: Handles properties `observe`, `infer`, `decide`, `act`, and `evaluate`.
*   `MasterAgentConsole`: Manages the trace logs for all six required agents.

#### [lib/models/level_data.dart](file:///c:/Users/HP/Desktop/mindmaze/lib/models/level_data.dart) [NEW]
Represents the procedural grid state:
*   `GridTile`: Enums representing Wall, Floor, Node, Sentinel, Player, Freeze, Decoy, Timed, One-Way.
*   `LevelLayout`: Represents a 12x12 array map containing active game items and verification flags.

#### [lib/models/game_metrics.dart](file:///c:/Users/HP/Desktop/mindmaze/lib/models/game_metrics.dart) [NEW]
Keeps real-time metrics collected per player turn:
*   `player_path_history`: Last 10 coordinates.
*   `corner_usage`: Hugging ratio.
*   `speed_pattern`: Step timing.
*   `win_loss_ratio`, `stress_index`, and `time_in_sentinel_los`.

#### [lib/agents/architect.dart](file:///c:/Users/HP/Desktop/mindmaze/lib/agents/architect.dart) [NEW]
Procedurally generates 12x12 mazes. Integrates the **GridArchitect** templates (Maze, Open, Corridor, Hybrid) based on player weaknesses and applies a BFS check to verify exits.

#### [lib/agents/sentinel.dart](file:///c:/Users/HP/Desktop/mindmaze/lib/agents/sentinel.dart) [NEW]
Calculates adversarial hunting steps:
*   Applies a localized A* or BFS algorithm to locate/intercept the player.
*   Performs dynamic classification to label the player as a **Ghost**, **Rusher**, **Collector**, or **Chaotic** and adjusts its speed/vision range parameter packages.
*   Maintains historical persistent fingerprints in simulated local storage.

#### [lib/components/grid_board.dart](file:///c:/Users/HP/Desktop/mindmaze/lib/components/grid_board.dart) [NEW]
A custom-painted or grid-built board component. Features:
*   Neon glow shaders for wall structures.
*   Soft particles for collected nodes.
*   Radial gradients highlighting Sentinel Line of Sight (LOS) and searchlight cones.

#### [lib/components/live_panel.dart](file:///c:/Users/HP/Desktop/mindmaze/lib/components/live_panel.dart) [NEW]
Renders the terminal console stream. Displays individual agent cards that glow and update in real-time, scrolling automatically as new cognitive traces are generated.

#### [lib/screens/game.dart](file:///c:/Users/HP/Desktop/mindmaze/lib/screens/game.dart) [NEW]
Main gameplay canvas containing game loop ticking timers, swipe/keyboard action listeners, HUD overlays, restart/level-up dialogs, and adaptive speed scalers.

---

## User Review Required

> [!IMPORTANT]
> The game logic will execute entirely on the client-side inside the Flutter application. The adversarial algorithms (Sentinel path prediction) and layout generation (GridArchitect cellular mazes) will be computed in clean Dart helpers. This removes external server latency, delivering an extremely crisp 60fps experience on mobile devices.

---

## Verification Plan

### Manual Verification
1.  **Level Generation Check**: Initiate game loops, ensuring the QC step triggers successfully (all levels are solvable, no dead-end traps blocking exit reachability).
2.  **Stealth Hunting Loops**: Verify that the Sentinel follows the player stealthily, and that alerts fire when stepping into Sentinel's illuminated vision cone.
3.  **Behavior Shift Assessment**: Play as a cautious slow edge-hugger, then sprint suddenly. Verify that the dynamic side-panel reports:
    *   Transition: `Ghost -> Rusher`
    *   Tactical Decide change: `Expand Eastern sweep -> Rusher Cut-off`
4.  **Device Layouts**: Verify that running the application on Web/Desktop shows side-by-side viewports, and Mobile flips between the Grid Map and Live Panel seamlessly.
