import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netflix_app/data/models/category_model.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/data/services/category_service.dart';
import 'package:netflix_app/data/services/movie_service.dart';
import 'package:netflix_app/presentation/widgets/common/pagination_widget.dart';
import 'package:netflix_app/presentation/widgets/home/content/movie_grid.dart';

class MovieCategoryScreen extends StatefulWidget {
  final int categoryId;

  const MovieCategoryScreen({super.key, required this.categoryId});

  @override
  MovieCategoryScreenState createState() => MovieCategoryScreenState();
}

class MovieCategoryScreenState extends State<MovieCategoryScreen> {
  late int _selectedCategoryId;
  late Future<CategoryModel?> _categoryFuture; // Future cho Category
  late Future<List<CategoryModel>> _categoriesFuture; // Future cho Category
  int _currentPage = 1; // Số trang hiện tại
  int _pageSize = 1; // Số lượng phim mỗi trang
  bool _isLoading = false; // Biến kiểm tra trạng thái tải dữ liệu
  List<MovieModel> _movies = []; // Danh sách các bộ phim
  int _totalPages =
      1; // Tổng số trang, có thể tính được từ tổng số phim / pageSize

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _categoryFuture = CategoryService.loadCategoryById(_selectedCategoryId);
    _categoriesFuture = CategoryService.loadCategories();
    _loadMovies(); // Tải phim cho trang đầu tiên
  }

  // Hàm tải danh sách phim từ API (với phân trang)
  void _loadMovies() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final allMovies =
        await MovieService.loadAllMovies(); // Lấy toàn bộ danh sách phim trước
    final movies = await MovieService.loadMoviesByCategoryWithPagination(
      _selectedCategoryId,
      _currentPage,
      _pageSize,
    );

    setState(() {
      _isLoading = false;
      _movies = movies;
      int totalMovies =
          allMovies.where((m) => m.categoryId == _selectedCategoryId).length;
      _totalPages = (totalMovies / _pageSize).ceil(); // Tính lại số trang
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      // Gọi phương thức để tải lại danh sách phim hoặc dữ liệu khác.
      _loadMovies();
    });
  }

  // Hàm hiển thị tiêu đề đầy đủ
  void _showFullTitleDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Tên đầy đủ"),
          content: Text(title),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }

  void _showGenreDropdown(TapDownDetails details) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = details.globalPosition; // Vị trí icon

    final categories = await _categoriesFuture; // Lấy danh sách thể loại

    final selectedCategory = await showMenu<CategoryModel>(
      context: context,
      color: Colors.black87, // Đặt nền tối giúp menu không bị mờ
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + 10,
        overlay.size.width - position.dx,
        0,
      ),
      items: [
        PopupMenuItem(
          // enabled: false, // Không chọn được, chỉ chứa danh sách có cuộn
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 260, // Giới hạn chiều cao để không bị tràn
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    categories.map((category) {
                      bool isSelected = category.id == _selectedCategoryId;

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(
                            context,
                            category,
                          ); // Đóng menu khi chọn
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.red.withValues(
                                      alpha: 0.9,
                                    ) // Màu nổi bật khi chọn
                                    : Colors
                                        .black87, // Màu nền tối giúp không bị mờ
                            borderRadius: BorderRadius.circular(10),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Colors.red.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder:
                                    (child, animation) => ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                child: Icon(
                                  isSelected ? Icons.check_circle : Icons.movie,
                                  key: ValueKey(isSelected),
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.redAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Khoảng cách giữa icon & text
                              Expanded(
                                // Bao phủ toàn bộ width
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[300],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );

    if (selectedCategory != null) {
      setState(() {
        _selectedCategoryId = selectedCategory.id;
        _categoryFuture = CategoryService.loadCategoryById(_selectedCategoryId);
        _currentPage = 1;
        _loadMovies();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<CategoryModel?>(
          future: _categoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading...");
            } else if (snapshot.hasError || !snapshot.hasData) {
              return const Text("No category found");
            }
            return Text(
              snapshot.data!.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white, // Màu chữ nhẹ nhàng hơn
              ),
            );
          },
        ),
        actions: [
          GestureDetector(
            onTapDown: (TapDownDetails details) {
              _showGenreDropdown(details);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.list, size: 28), // Icon 3 gạch
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          _totalPages > 0
              ?
              // 🔹 Dropdown để chọn số bản ghi hiển thị mỗi trang
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Số phim mỗi trang:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70, // Màu chữ nhẹ nhàng hơn
                      ),
                    ),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87, // Nền tối giống Netflix
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Bo góc mềm mại
                        border: Border.all(
                          color: Colors.redAccent,
                          width: 1.5,
                        ), // Viền đỏ nổi bật
                      ),
                      child: DropdownButton<int>(
                        value: _pageSize,
                        dropdownColor: Colors.black87,
                        // Nền dropdown tối hơn
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.redAccent,
                        ),
                        underline: Container(),
                        // Ẩn gạch chân
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        // Chữ trắng
                        items:
                            [1, 10, 20, 30, 50].map((size) {
                              return DropdownMenuItem<int>(
                                value: size,
                                child: Text("$size phim"),
                              );
                            }).toList(),
                        onChanged: (newSize) {
                          if (newSize != null) {
                            setState(() {
                              _pageSize = newSize;
                              _currentPage = 1;
                              _loadMovies();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              )
              : Text("Không tìm thấy phim"),

          Expanded(
            child: MovieGrid(
              movies: _movies,
              onMovieTap: (title) => _showFullTitleDialog(context, title),
            ), // Hiển thị danh sách phim
          ),

          // Sử dụng PaginationWidget ở đây
          PaginationWidget(
            currentPage: _currentPage,
            totalPages: _totalPages,
            onPageChanged: _onPageChanged, // Truyền vào callback
          ),
          // Hiển thị phân trang nếu có nhiều trang
        ],
      ),
    );
  }
}
