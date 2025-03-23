import 'package:flutter/material.dart';

import '../../../data/models/movie_model.dart';
import '../../../widgets/home/header/header_widget.dart';
import '../../../widgets/home/header/search_popup.dart';
import '../../../widgets/home/content/movie_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MovieModel> _searchResults = [];
  int _selectedIndex = 0; // Chỉ số tab hiện tại
  OverlayEntry? _searchOverlay;

  static const List<Widget> _widgetOptions = <Widget>[
    Text('Trang Chủ', style: TextStyle(fontSize: 24, color: Colors.white)),
    Text('Tìm kiếm', style: TextStyle(fontSize: 24, color: Colors.white)),
    Text('Danh sách của tôi', style: TextStyle(fontSize: 24, color: Colors.white)),
    Text('Thông tin cá nhân', style: TextStyle(fontSize: 24, color: Colors.white)),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// 🔥 Widget tùy chỉnh item điều hướng
  Widget _buildNavItem(IconData icon, IconData selectedIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 30,
              color: isSelected ? Colors.red : Colors.white,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 🔥 Hiển thị popup ở trên cùng màn hình bằng Overlay
  void _showSearchPopup() {
    if (_searchOverlay != null) {
      _searchOverlay!.remove();
    }

    OverlayState overlayState = Overlay.of(context);
    _searchOverlay = OverlayEntry(
      builder:
          (context) => SearchPopup(
            searchResults: _searchResults,
            onClose: () {
              _searchOverlay?.remove();
              _searchOverlay = null;
            },
          ),
    );

    overlayState.insert(_searchOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(color: Colors.black), // Background thay vì Scaffold
          Column(
            children: [
              // Header
              HeaderWidget(
                onSearchResults: (movies) {
                  setState(() {
                    _searchResults = movies;
                  });
                  if (_searchResults.isNotEmpty) {
                    _showSearchPopup();
                  }
                },
              ),
              // Nội dung màn hình chính
              Expanded(
                child:
                    _selectedIndex == 0
                        ? MovieContent()
                        : Center(child: _widgetOptions.elementAt(_selectedIndex)),
              ),
            ],
          ),
        ],
      ),

      // 🔥 Điều hướng cải tiến
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Trang Chủ', 0),
            _buildNavItem(Icons.search, Icons.search, 'Tìm kiếm', 1),
            _buildNavItem(Icons.playlist_add_check, Icons.playlist_add_check, 'Danh sách', 2),
            _buildNavItem(Icons.person_outline, Icons.person, 'Cá nhân', 3),
          ],
        ),
      ),
    );
  }

}
