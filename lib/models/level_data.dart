import 'dart:math';

enum TileType {
  wall,
  floor,
  player,
  sentinel,
  node,
  freezeTrap,
  decoyNode,
  timedTrap,
  oneWayDoor,
  exit,
}

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  double distanceTo(Position other) {
    return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2));
  }

  int manhattanDistance(Position other) {
    return (x - other.x).abs() + (y - other.y).abs();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '($x,$y)';

  List<int> toJson() => [x, y];

  factory Position.fromJson(List<dynamic> json) {
    return Position(json[0] as int, json[1] as int);
  }
}

class LevelLayout {
  final String levelId;
  final List<List<TileType>> grid;
  final List<Position> nodePositions;
  final List<Position> sentinelSpawns;
  final Map<String, List<Position>> trapPositions;
  final Position exitPosition;
  final Position playerStart;
  final double estimatedWinRate;
  final String difficultyJustification;
  final String mechanicIntroduced;
  final String generationTrace;

  LevelLayout({
    required this.levelId,
    required this.grid,
    required this.nodePositions,
    required this.sentinelSpawns,
    required this.trapPositions,
    required this.exitPosition,
    required this.playerStart,
    required this.estimatedWinRate,
    required this.difficultyJustification,
    required this.mechanicIntroduced,
    required this.generationTrace,
  });

  /// Deep copy level grid
  List<List<TileType>> getClonedGrid() {
    return List.generate(
      grid.length,
      (x) => List.generate(grid[x].length, (y) => grid[x][y]),
    );
  }

  /// Helper to convert ASCII rows to structural Layout class
  static LevelLayout fromAscii({
    required String id,
    required List<String> asciiGrid,
    required double winRate,
    required String justification,
    required String mechanic,
    required String trace,
  }) {
    List<List<TileType>> finalGrid = List.generate(
      12,
      (_) => List.generate(12, (_) => TileType.floor),
    );

    List<Position> nodes = [];
    List<Position> sentinels = [];
    List<Position> freeze = [];
    List<Position> decoy = [];
    List<Position> timed = [];
    List<Position> oneWay = [];
    Position start = const Position(1, 1);
    Position exit = const Position(11, 10);

    for (int y = 0; y < 12; y++) {
      String row = asciiGrid[y].replaceAll(' ', '');
      for (int x = 0; x < 12; x++) {
        String char = row[x];
        Position pos = Position(x, y);

        switch (char) {
          case '#':
            finalGrid[y][x] = TileType.wall;
            break;
          case 'P':
            finalGrid[y][x] = TileType.player;
            start = pos;
            break;
          case 'E':
            finalGrid[y][x] = TileType.exit;
            exit = pos;
            break;
          case 'N':
            finalGrid[y][x] = TileType.node;
            nodes.add(pos);
            break;
          case 'S':
            finalGrid[y][x] = TileType.sentinel;
            sentinels.add(pos);
            break;
          case 'F':
            finalGrid[y][x] = TileType.freezeTrap;
            freeze.add(pos);
            break;
          case 'D':
            finalGrid[y][x] = TileType.decoyNode;
            decoy.add(pos);
            break;
          case 'T':
            finalGrid[y][x] = TileType.timedTrap;
            timed.add(pos);
            break;
          case 'O':
            finalGrid[y][x] = TileType.oneWayDoor;
            oneWay.add(pos);
            break;
          default:
            finalGrid[y][x] = TileType.floor;
        }
      }
    }

    return LevelLayout(
      levelId: id,
      grid: finalGrid,
      nodePositions: nodes,
      sentinelSpawns: sentinels,
      trapPositions: {
        'freeze': freeze,
        'decoy': decoy,
        'timed': timed,
        'one_way': oneWay,
      },
      exitPosition: exit,
      playerStart: start,
      estimatedWinRate: winRate,
      difficultyJustification: justification,
      mechanicIntroduced: mechanic,
      generationTrace: trace,
    );
  }
}
