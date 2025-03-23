import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/category_model.dart';

class CategoryService {
  // Hàm tải danh sách thể loại phim từ JSON
  static Future<List<CategoryModel>> loadCategories() async {
    try {
      final String response = await rootBundle.loadString('assets/json/categories.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      print("Lỗi khi tải thể loại phim: $e");
      return [];
    }
  }
}
