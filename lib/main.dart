import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/game.dart';

void main() {
  // Lock orientation to vertical portrait for mobile-first consistency
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set visual status bar colors to merge with the dark dashboard UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF06070B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MindMazeApp());
}

class MindMazeApp extends StatelessWidget {
  const MindMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MINDMAZE',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06070B),
        
        // Define Cyberpunk Neon Color Scheme
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF2E93),
          surface: Color(0xFF090A0F),
          error: Color(0xFFFF2E93),
        ),

        // Cyberpunk Monospace Typography Visual Excellence
        textTheme: GoogleFonts.shareTechMonoTextTheme(
          ThemeData.dark().textTheme.copyWith(
            bodyLarge: const TextStyle(color: Color(0xFFE4E6EB)),
            bodyMedium: const TextStyle(color: Color(0xFF808595)),
          ),
        ),

        dividerColor: const Color(0xFF121626),
      ),
      home: const GameScreen(),
    );
  }
}
