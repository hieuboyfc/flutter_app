import 'package:flutter/material.dart';
import 'package:netflix_app/presentation/screens/splash/splash_screen.dart';
import 'package:netflix_app/presentation/screens/home/home_screen.dart';
import 'package:netflix_app/presentation/screens/profile/profile_screen.dart';

void main() {
  runApp(const NetflixApp());
}

class NetflixApp extends StatelessWidget {
  const NetflixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netflix App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
