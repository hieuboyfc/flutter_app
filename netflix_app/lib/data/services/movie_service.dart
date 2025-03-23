import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thư viện SharedPreferences

import '../models/movie_model.dart';

class MovieService {
  static List<MovieModel>? _cachedMovies; // Cache để tránh load nhiều lần

  // Hàm tải tất cả phim từ JSON (nếu chưa có cache)
  static Future<List<MovieModel>> loadMovies() async {
    if (_cachedMovies != null) return _cachedMovies!; // Dùng cache nếu có

    try {
      final String response = await rootBundle.loadString('assets/json/movies.json');
      final List<dynamic> data = json.decode(response);
      _cachedMovies = data.map((json) => MovieModel.fromJson(json)).toList();
      return _cachedMovies!;
    } catch (e) {
      print("Lỗi khi tải phim: $e");
      return [];
    }
  }

  static Future<List<MovieModel>> loadMoviesByCategory(int categoryId) async {
    final List<MovieModel> movies = await MovieService.loadMovies();
    return movies.where((m) => m.categoryId == categoryId).toList();
  }

  // Hàm tải phim theo ngày trong tuần
  static Future<List<MovieModel>> loadMoviesByDay(int day) async {
    final List<MovieModel> movies = await loadMovies();
    return movies.where((m) => m.weekDay == day).toList();
  }

  // Hàm tải phim hot (rating >= 8.0)
  static Future<List<MovieModel>> loadHotMovies() async {
    final List<MovieModel> movies = await loadMovies();
    return movies.where((m) => m.rating >= 8.0).toList();
  }

  // Hàm tải phim mới (chỉ có 1 tập)
  static Future<List<MovieModel>> loadNewMovies() async {
    final List<MovieModel> movies = await loadMovies();
    return movies.where((m) => m.episodes == 1).toList();
  }

  static Future<List<MovieModel>> loadIsWatchedMovies() async {
    final List<MovieModel> movies = await loadMovies();
    return movies.where((m) => m.isWatched).toList();
  }

  // Hàm tải danh sách phim đã lưu từ SharedPreferences
  static Future<List<MovieModel>> loadSavedMovies(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Lấy danh sách ID phim đã lưu từ SharedPreferences dưới dạng List<int>
      List<int>? savedMovieIds =
          prefs.getStringList('saved_movies_$userId')?.map((e) => int.parse(e)).toList();

      if (savedMovieIds == null || savedMovieIds.isEmpty) {
        return []; // Nếu không có phim đã lưu, trả về danh sách rỗng
      }

      // Tải tất cả các phim và lọc ra những phim đã lưu
      final List<MovieModel> movies = await loadMovies();
      List<MovieModel> savedMovies =
          movies.where((movie) {
            return savedMovieIds.contains(movie.id); // So sánh ID phim
          }).toList();

      return savedMovies;
    } catch (e) {
      print("Lỗi khi tải phim đã lưu: $e");
      return [];
    }
  }

  // Hàm làm mới dữ liệu (khi cần cập nhật)
  static Future<void> refreshMovies() async {
    _cachedMovies = null;
    await loadMovies();
  }

  // Hàm lưu phim vào danh sách đã lưu (SharedPreferences)
  static Future<void> saveMovieByUser(String userId, MovieModel movie) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Lấy danh sách phim đã lưu trước đó, nếu có
      List<String>? savedMovieIds = prefs.getStringList('saved_movies_$userId') ?? [];

      // Thêm ID của phim vào danh sách nếu chưa có
      if (!savedMovieIds.contains(movie.id.toString())) {
        savedMovieIds.add(movie.id.toString());
        await prefs.setStringList('saved_movies_$userId', savedMovieIds);
      }
    } catch (e) {
      print("Lỗi khi lưu phim: $e");
    }
  }

  // Hàm xóa phim khỏi danh sách đã lưu
  static Future<void> removeSavedMovieByUser(String userId, MovieModel movie) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Lấy danh sách phim đã lưu trước đó, nếu có
      List<String>? savedMovieIds = prefs.getStringList('saved_movies_$userId') ?? [];

      // Xóa ID của phim khỏi danh sách
      savedMovieIds.remove(movie.id.toString());
      await prefs.setStringList('saved_movies_$userId', savedMovieIds);
    } catch (e) {
      print("Lỗi khi xóa phim: $e");
    }
  }

  // Lưu thông tin phim vào SharedPreferences
  static Future<void> saveMovie(MovieModel movie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Chuyển movie thành JSON
    Map<String, dynamic> movieJson = movie.toJson();
    String movieString = jsonEncode(movieJson);

    // Lưu thông tin phim vào SharedPreferences, key là 'movie_${movie.id}'
    prefs.setString('movie_${movie.id}', movieString);
  }
}
