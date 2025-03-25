import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thư viện SharedPreferences

import '../models/movie_model.dart';

class MovieService {
  static const int _pageSize = 10;
  static List<MovieModel>? _cachedMovies; // Cache để tránh load nhiều lần

  // Giả lập lấy danh sách phim
  static Future<List<MovieModel>> loadMovies({int page = 1}) async {
    // Giả lập dữ liệu từ file JSON
    final List<MovieModel> movies = await MovieService.loadAllMovies();

    // Tính toán chỉ mục bắt đầu và kết thúc cho phân trang
    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;

    // Lấy dữ liệu trong phạm vi trang hiện tại
    final paginatedMovies = movies.sublist(
      startIndex,
      endIndex <= movies.length ? endIndex : movies.length,
    );

    // Chuyển đổi dữ liệu từ JSON thành danh sách các MovieModel
    return paginatedMovies.toList();
  }

  // Tương tự, giả lập lấy phim theo ngày hoặc các loại phim khác
  static Future<List<MovieModel>> loadMoviesByDay(
    int dayIndex, {
    int page = 1,
  }) async {
    List<MovieModel> movies = await MovieService.loadAllMovies();
    movies = movies.where((item) => item.weekDay == dayIndex).toList();

    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final paginatedMovies = movies.sublist(
      startIndex,
      endIndex <= movies.length ? endIndex : movies.length,
    );

    return paginatedMovies.toList();
  }

  static Future<List<MovieModel>> loadHotMovies({int page = 1}) async {
    final List<MovieModel> movies = await MovieService.loadAllMovies();

    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final paginatedMovies = movies.sublist(
      startIndex,
      endIndex <= movies.length ? endIndex : movies.length,
    );

    return paginatedMovies.toList();
  }

  static Future<List<MovieModel>> loadNewMovies({int page = 1}) async {
    final List<MovieModel> movies = await MovieService.loadAllMovies();

    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final paginatedMovies = movies.sublist(
      startIndex,
      endIndex <= movies.length ? endIndex : movies.length,
    );

    return paginatedMovies.toList();
  }

  static Future<List<MovieModel>> loadSavedMovies(
    String userId, {
    int page = 1,
  }) async {
    final List<MovieModel> movies = await MovieService.loadAllMovies();

    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final paginatedMovies = movies.sublist(
      startIndex,
      endIndex <= movies.length ? endIndex : movies.length,
    );

    return paginatedMovies.toList();
  }

  // Hàm tải tất cả phim từ JSON (nếu chưa có cache)
  static Future<List<MovieModel>> loadAllMovies() async {
    if (_cachedMovies != null) return _cachedMovies!; // Dùng cache nếu có

    try {
      final String response = await rootBundle.loadString(
        'assets/json/movies.json',
      );
      final List<dynamic> data = json.decode(response);
      _cachedMovies = data.map((json) => MovieModel.fromJson(json)).toList();
      return _cachedMovies!;
    } catch (e) {
      print("Lỗi khi tải phim: $e");
      return [];
    }
  }

  // Hàm tải danh sách phim theo thể loại với phân trang
  static Future<List<MovieModel>> loadMoviesByCategoryWithPagination(
    int categoryId,
    int page,
    int pageSize,
  ) async {
    final List<MovieModel> movies = await MovieService.loadAllMovies();

    // Lọc phim theo thể loại
    final List<MovieModel> filteredMovies =
        movies.where((m) => m.categoryId == categoryId).toList();

    // Tính vị trí bắt đầu và kết thúc của trang
    int startIndex = (page - 1) * pageSize;
    int endIndex = startIndex + pageSize;

    if (startIndex >= filteredMovies.length) {
      return [];
    }

    return filteredMovies.sublist(
      startIndex,
      endIndex.clamp(0, filteredMovies.length),
    );
  }

  // Hàm tải danh sách phim theo thể loại với phân trang
  static Future<List<MovieModel>> loadMoviesByWithPagination(
    int categoryId,
    String keyTitle,
    int page,
    int pageSize,
  ) async {
    final List<MovieModel> movies = await MovieService.loadAllMovies();
    List<MovieModel> filterMovies = [];

    // Lọc phim theo tiêu chí
    switch (keyTitle) {
      case "hot_movies":
        filterMovies = movies.where((m) => m.rating >= 8.0).toList();
        break;
      case "new_movies":
        filterMovies = movies.where((m) => m.episodes == 1).toList();
        break;
      default:
        filterMovies = movies;
    }

    // Lọc phim theo thể loại
    final List<MovieModel> filteredMovies =
        filterMovies
            .where((m) => categoryId == 0 || m.categoryId == categoryId)
            .toList();

    // Tính vị trí bắt đầu và kết thúc của trang
    int startIndex = (page - 1) * pageSize;
    int endIndex = startIndex + pageSize;

    // Kiểm tra nếu startIndex vượt quá danh sách
    if (startIndex >= filteredMovies.length) {
      return [];
    }

    // Trả về danh sách con của các phim theo trang
    return filteredMovies.sublist(
      startIndex,
      endIndex.clamp(0, filteredMovies.length),
    );
  }

  static Future<List<MovieModel>> loadMoviesByCategory(int categoryId) async {
    final List<MovieModel> movies = await MovieService.loadAllMovies();
    return movies.where((m) => m.categoryId == categoryId).toList();
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
      List<String>? savedMovieIds =
          prefs.getStringList('saved_movies_$userId') ?? [];

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
  static Future<void> removeSavedMovieByUser(
    String userId,
    MovieModel movie,
  ) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // Lấy danh sách phim đã lưu trước đó, nếu có
      List<String>? savedMovieIds =
          prefs.getStringList('saved_movies_$userId') ?? [];

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
