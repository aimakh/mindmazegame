import 'package:flutter/material.dart';
import '../models/level_data.dart';

class GridBoard extends StatelessWidget {
  final List<List<TileType>> grid;
  final Position playerPos;
  final List<Position> sentinelPositions;
  final Set<Position> sentinelLOS; // Set of coordinates currently in Sentinel sight
  final Map<String, List<Position>> trapPositions;
  final Function(Position) onTileTap;

  const GridBoard({
    super.key,
    required this.grid,
    required this.playerPos,
    required this.sentinelPositions,
    required this.sentinelLOS,
    required this.trapPositions,
    required this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090A0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2030), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.05),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Column(
          children: List.generate(12, (y) {
            return Expanded(
              child: Row(
                children: List.generate(12, (x) {
                  Position pos = Position(x, y);
                  TileType type = grid[y][x];
                  
                  // Dynamically resolve overlay entities
                  bool isPlayer = pos == playerPos;
                  bool isSentinel = sentinelPositions.contains(pos);
                  bool isInLOS = sentinelLOS.contains(pos);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTileTap(pos),
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: _resolveTileBackgroundColor(type, isPlayer, isSentinel, isInLOS),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _resolveTileBorderColor(type, isPlayer, isSentinel, isInLOS),
                            width: isPlayer || isSentinel ? 2 : 1,
                          ),
                          boxShadow: _resolveTileShadows(type, isPlayer, isSentinel, isInLOS),
                        ),
                        child: Center(
                          child: _buildTileIcon(type, isPlayer, isSentinel),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Color _resolveTileBackgroundColor(TileType type, bool isPlayer, bool isSentinel, bool isInLOS) {
    if (isPlayer) return const Color(0xFF001E26);
    if (isSentinel) return const Color(0xFF260515);
    
    // Laser searchlight sweep backdrop overlay
    if (isInLOS) {
      return const Color(0xFFFF2E93).withOpacity(0.18);
    }

    switch (type) {
      case TileType.wall:
        return const Color(0xFF101424);
      case TileType.freezeTrap:
      case TileType.timedTrap:
        return const Color(0xFF261D00);
      case TileType.oneWayDoor:
        return const Color(0xFF1D002B);
      case TileType.exit:
        return const Color(0xFF0F002B);
      default:
        return const Color(0xFF090A0F);
    }
  }

  Color _resolveTileBorderColor(TileType type, bool isPlayer, bool isSentinel, bool isInLOS) {
    if (isPlayer) return const Color(0xFF00E5FF);
    if (isSentinel) return const Color(0xFFFF2E93);
    if (isInLOS) return const Color(0xFFFF2E93).withOpacity(0.4);

    switch (type) {
      case TileType.wall:
        return const Color(0xFF1B2030);
      case TileType.node:
        return const Color(0xFF00FF66).withOpacity(0.3);
      case TileType.freezeTrap:
      case TileType.timedTrap:
        return const Color(0xFFFFB300).withOpacity(0.4);
      case TileType.oneWayDoor:
        return const Color(0xFFBD00FF).withOpacity(0.4);
      case TileType.exit:
        return const Color(0xFFBD00FF);
      default:
        return const Color(0xFF0F121C);
    }
  }

  List<BoxShadow>? _resolveTileShadows(TileType type, bool isPlayer, bool isSentinel, bool isInLOS) {
    if (isPlayer) {
      return [
        BoxShadow(
          color: const Color(0xFF00E5FF).withOpacity(0.3),
          blurRadius: 8,
        )
      ];
    }
    if (isSentinel) {
      return [
        BoxShadow(
          color: const Color(0xFFFF2E93).withOpacity(0.3),
          blurRadius: 8,
        )
      ];
    }

    switch (type) {
      case TileType.node:
        return [
          BoxShadow(
            color: const Color(0xFF00FF66).withOpacity(0.15),
            blurRadius: 4,
          )
        ];
      case TileType.exit:
        return [
          BoxShadow(
            color: const Color(0xFFBD00FF).withOpacity(0.2),
            blurRadius: 6,
          )
        ];
      default:
        return null;
    }
  }

  Widget? _buildTileIcon(TileType type, bool isPlayer, bool isSentinel) {
    if (isPlayer) {
      return const Icon(
        Icons.developer_board,
        color: Color(0xFF00E5FF),
        size: 16,
      );
    }
    if (isSentinel) {
      return const Icon(
        Icons.security,
        color: Color(0xFFFF2E93),
        size: 16,
      );
    }

    switch (type) {
      case TileType.node:
        return const Icon(
          Icons.radio_button_checked,
          color: Color(0xFF00FF66),
          size: 12,
        );
      case TileType.freezeTrap:
        return const Icon(
          Icons.ac_unit,
          color: Color(0xFFFFB300),
          size: 12,
        );
      case TileType.timedTrap:
        return const Icon(
          Icons.timer,
          color: Color(0xFFFFB300),
          size: 12,
        );
      case TileType.oneWayDoor:
        return const Icon(
          Icons.login,
          color: Color(0xFFBD00FF),
          size: 12,
        );
      case TileType.exit:
        return const Icon(
          Icons.vpn_key,
          color: Color(0xFFBD00FF),
          size: 12,
        );
      default:
        return null;
    }
  }
}
