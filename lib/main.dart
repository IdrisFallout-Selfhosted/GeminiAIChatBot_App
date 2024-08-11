import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import SplashScreen from splash_screen.dart

void main() {
  runApp(const GeminiAIChatBot());
}

class GeminiAIChatBot extends StatelessWidget {
  const GeminiAIChatBot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeminiAIChatBot',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Color(0xFF4CAF50),
        ),
      ),
      home: const SplashScreen(), // Display SplashScreen initially
    );
  }
}
