import 'package:flutter/material.dart';

class ControllerPad extends StatelessWidget {
  final Function(String direction) onMove;
  final VoidCallback onTriggerDecoy;
  final VoidCallback onTriggerStealth;
  final int decoyCount;
  final bool isStealthActive;

  const ControllerPad({
    super.key,
    required this.onMove,
    required this.onTriggerDecoy,
    required this.onTriggerStealth,
    required this.decoyCount,
    required this.isStealthActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF090A0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2030), width: 2),
      ),
      child: Row(
        children: [
          // Nav D-PAD Cross
          Expanded(
            flex: 4,
            child: AspectRatio(
              aspectRatio: 1.2,
              child: Stack(
                children: [
                  // CENTER SPACE
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF101424),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.circle, color: Color(0xFF00E5FF), size: 10),
                      ),
                    ),
                  ),
                  
                  // UP BUTTON
                  Align(
                    alignment: Alignment.topCenter,
                    child: _buildDpadButton(
                      icon: Icons.keyboard_arrow_up,
                      onPressed: () => onMove('UP'),
                    ),
                  ),
                  
                  // DOWN BUTTON
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildDpadButton(
                      icon: Icons.keyboard_arrow_down,
                      onPressed: () => onMove('DOWN'),
                    ),
                  ),
                  
                  // LEFT BUTTON
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildDpadButton(
                      icon: Icons.keyboard_arrow_left,
                      onPressed: () => onMove('LEFT'),
                    ),
                  ),
                  
                  // RIGHT BUTTON
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildDpadButton(
                      icon: Icons.keyboard_arrow_right,
                      onPressed: () => onMove('RIGHT'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),
          const VerticalDivider(color: Color(0xFF1B2030), width: 1),
          const SizedBox(width: 12),

          // Rogue AI Hacking Abilities Panel
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAbilityButton(
                  title: 'ACOUSTIC DECOY',
                  subtitle: '$decoyCount CHARGES REMAINING',
                  icon: Icons.sensors,
                  accentColor: const Color(0xFFFFB300),
                  onPressed: decoyCount > 0 ? onTriggerDecoy : null,
                ),
                const SizedBox(height: 8),
                _buildAbilityButton(
                  title: 'STEALTH CLOAK',
                  subtitle: isStealthActive ? 'ACTIVE NOW (2 TURNS)' : 'READY',
                  icon: Icons.blur_on,
                  accentColor: isStealthActive ? const Color(0xFF00FF66) : const Color(0xFF00E5FF),
                  onPressed: isStealthActive ? null : onTriggerStealth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDpadButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1D2235)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF00E5FF), size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildAbilityButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback? onPressed,
  }) {
    bool isDisabled = onPressed == null;

    return Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: isDisabled ? const Color(0xFF0C0E16).withOpacity(0.5) : const Color(0xFF0C0E16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDisabled ? const Color(0xFF121626) : accentColor.withOpacity(0.4),
        ),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(
              icon,
              color: isDisabled ? const Color(0xFF4C505C) : accentColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDisabled ? const Color(0xFF4C505C) : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDisabled ? const Color(0xFF303440) : accentColor.withOpacity(0.8),
                      fontSize: 8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
