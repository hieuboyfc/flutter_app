import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netflix_app/presentation/screens/base/base_screen.dart';
import 'package:netflix_app/presentation/screens/base/error_screen.dart';
import 'package:netflix_app/presentation/screens/home/home_screen.dart';
import 'package:netflix_app/presentation/screens/movie/movie_category_screen.dart';
import 'package:netflix_app/presentation/screens/movie/movie_detail_screen.dart';
import 'package:netflix_app/presentation/screens/movie/movie_type_screen.dart';
import 'package:netflix_app/presentation/screens/profile/profile_screen.dart';
import 'package:netflix_app/presentation/screens/splash/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash', // Màn hình mặc định
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/movie/category/:categoryId',
      builder: (BuildContext context, GoRouterState state) {
        final categoryId = int.parse(state.pathParameters['categoryId']!);
        return BaseScreen(
          initialIndex: 0,
          showHeader: true,
          body: MovieCategoryScreen(categoryId: categoryId),
        );
      },
    ),
    GoRoute(
      path: '/movie/type/:code',
      builder: (BuildContext context, GoRouterState state) {
        final code = state.pathParameters['code']!;
        return BaseScreen(initialIndex: 0, showHeader: true, body: MovieTypeScreen(code: code));
      },
    ),
    GoRoute(
      path: '/movie/detail/:movieId',
      builder: (BuildContext context, GoRouterState state) {
        final movieId = int.parse(state.pathParameters['movieId']!);
        return BaseScreen(
          initialIndex: 0,
          showHeader: true,
          body: MovieDetailScreen(movieId: movieId),
        );
      },
    ),
    GoRoute(
      path: '/search',
      builder:
          (context, state) =>
              const Text('Tìm kiếm', style: TextStyle(fontSize: 24, color: Colors.white)),
    ),
    GoRoute(
      path: '/playlist',
      builder:
          (context, state) =>
              const Text('Danh sách của tôi', style: TextStyle(fontSize: 24, color: Colors.white)),
    ),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
  // Định nghĩa một route catch-all cho các đường dẫn không hợp lệ
  errorBuilder: (context, state) {
    return const ErrorScreen();
  },
);
