import 'package:flutter/material.dart';
import 'package:netflix_app/core/config/app_routes.dart';
import 'package:netflix_app/core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Đảm bảo khởi tạo đúng
  await AppLogger.init(); // Khởi tạo hệ thống log

  AppLogger.info("Ứng dụng Netflix App khởi động");

  runApp(NetflixApp());
}

class NetflixApp extends StatelessWidget {
  const NetflixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Netflix App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      routerConfig: appRouter,
    );
  }
}
