import 'package:flutter/material.dart';

import 'auth_popup.dart';
import '../../../data/models/movie_model.dart';
import '../../../data/services/movie_service.dart';
import '../../../presentation/screens/profile/profile_screen.dart';

class HeaderWidget extends StatefulWidget {
  final Function(List<MovieModel>) onSearchResults;

  const HeaderWidget({super.key, required this.onSearchResults});

  @override
  _HeaderWidgetState createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<MovieModel> _allMovies = [];

  String? _username;
  OverlayEntry? _authOverlay;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  void _showAuthPopup() {
    if (_authOverlay != null) {
      _authOverlay!.remove();
    }

    OverlayState overlayState = Overlay.of(context);
    _authOverlay = OverlayEntry(
      builder:
          (context) => AuthPopup(
            onClose: () {
              _authOverlay?.remove();
              _authOverlay = null;
            },
            onLoginSuccess: (username) {
              setState(() {
                _username = username;
              });
            },
          ),
    );

    overlayState.insert(_authOverlay!);
  }

  void _logout() {
    setState(() {
      _username = null;
    });
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  /// 🚀 Load danh sách phim từ JSON
  void _loadMovies() async {
    _allMovies = await MovieService.loadAllMovies();
  }

  /// 🔍 Lọc phim theo từ khóa
  void _filterMovies(String query) {
    List<MovieModel> filteredMovies =
        _allMovies
            .where(
              (movie) =>
                  movie.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
    widget.onSearchResults(filteredMovies);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔥 Logo Netflix
          Image.asset('assets/images/netflix_logo.png', width: 100),

          // 🔍 Ô tìm kiếm
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 15), // 📏 Giãn cách avatar
              child: TextField(
                controller: _searchController,
                onChanged: _filterMovies,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Tìm kiếm phim...",
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // 👤 Avatar (Ẩn tên, chỉ hiển thị khi click)
          _username == null
              ? GestureDetector(
                onTap: _showAuthPopup,
                child: const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(
                    'assets/images/default_avatar.png',
                  ),
                ),
              )
              : PopupMenuButton<int>(
                onSelected: (value) {
                  if (value == 1) {
                    _goToProfile();
                  } else if (value == 2) {
                    _logout();
                  }
                },
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                color: Colors.black87,
                itemBuilder:
                    (context) => [
                      // 🖼️ Hiển thị avatar + tên người dùng (Căn ngang)
                      PopupMenuItem<int>(
                        value: 0,
                        enabled: false,
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage(
                                'assets/images/user_avatar.png',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _username!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),

                      // ⚙️ Hồ sơ
                      PopupMenuItem<int>(
                        value: 1,
                        child: Row(
                          children: const [
                            Icon(Icons.settings, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              "Hồ sơ",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      // 🚪 Đăng xuất
                      PopupMenuItem<int>(
                        value: 2,
                        child: Row(
                          children: const [
                            Icon(Icons.exit_to_app, color: Colors.red),
                            SizedBox(width: 10),
                            Text(
                              "Đăng xuất",
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                child: const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('assets/images/user_avatar.png'),
                ),
              ),
        ],
      ),
    );
  }
}
