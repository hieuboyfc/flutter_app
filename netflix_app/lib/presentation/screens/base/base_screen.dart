import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/presentation/widgets/home/header/header_widget.dart';
import 'package:netflix_app/presentation/widgets/home/header/search_popup.dart';

class BaseScreen extends StatefulWidget {
  final Widget body;
  final int initialIndex;
  final bool showHeader;

  const BaseScreen({super.key, required this.body, this.initialIndex = 0, this.showHeader = true});

  @override
  BaseScreenState createState() => BaseScreenState();
}

class BaseScreenState extends State<BaseScreen> {
  int _selectedIndex = 0;
  OverlayEntry? _searchOverlay;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Set initial index
  }

  @override
  void dispose() {
    _searchOverlay?.remove(); // Clean up when the widget is disposed
    super.dispose();
  }

  // Handle tapping on a navigation item
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });

    // Handle navigation based on the selected index
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/playlist');
        break;
      case 3:
        context.go('/profile');
        break;
      default:
        context.go('/splash');
    }
  }

  Widget _buildNavItem(IconData icon, IconData selectedIcon, String label, int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        _onItemTapped(index); // Handle navigation on tap
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.transparent, // Giữ màu nền của container ngoài
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container bao bọc icon, áp dụng lớp phủ màu đỏ khi được chọn
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding:
                  isSelected
                      ? EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15)
                      : EdgeInsets.all(0),
              // Tạo không gian cho lớp phủ
              decoration: BoxDecoration(
                color: isSelected ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(10), // Góc bo tròn phù hợp với icon
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: 30,
                color: isSelected ? Colors.red : Colors.white,
              ),
            ),
            // AnimatedOpacity cho text vẫn giữ nguyên
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.red, // Text màu đỏ khi chọn
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(color: Colors.black),
          Column(
            children: [
              if (widget.showHeader)
                HeaderWidget(
                  onSearchResults: (movies) {
                    _showSearchPopup(movies);
                  },
                ),
              Expanded(child: widget.body), // Here we use the body passed in
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
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

  void _showSearchPopup(List<MovieModel> searchResults) {
    if (_searchOverlay != null) {
      _searchOverlay!.remove(); // Remove existing overlay if any
      _searchOverlay = null;
    }

    if (searchResults.isNotEmpty) {
      // Insert the new overlay if there are search results
      OverlayState overlayState = Overlay.of(context);
      _searchOverlay = OverlayEntry(
        builder:
            (context) => SearchPopup(
              searchResults: searchResults,
              onClose: () {
                _searchOverlay?.remove(); // Remove overlay when close
                _searchOverlay = null;
              },
            ),
      );
      overlayState.insert(_searchOverlay!); // Show the overlay
    }
  }
}
