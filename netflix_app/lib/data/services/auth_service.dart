import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static const String _usersKey = "users";

  // Đăng ký tài khoản
  static Future<String> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    Map<String, String> users =
        usersJson != null ? Map<String, String>.from(json.decode(usersJson)) : {};

    if (users.containsKey(username)) {
      return "Tên đăng nhập đã tồn tại!";
    }

    users[username] = password;
    await prefs.setString(_usersKey, json.encode(users));

    return "Đăng ký thành công!";
  }

  // Đăng nhập
  static Future<String> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    Map<String, String> users =
        usersJson != null ? Map<String, String>.from(json.decode(usersJson)) : {};

    if (!users.containsKey(username)) {
      return "Tài khoản không tồn tại!";
    }

    if (users[username] != password) {
      return "Mật khẩu không đúng!";
    }

    return "Đăng nhập thành công!";
  }

  // Lưu tài khoản đăng nhập
  static Future<void> saveLoggedInUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("loggedInUser", username);
  }

  // Kiểm tra trạng thái đăng nhập
  static Future<String?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("loggedInUser");
  }

  // Đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("loggedInUser");
  }
}
