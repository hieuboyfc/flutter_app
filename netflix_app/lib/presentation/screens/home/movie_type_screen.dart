import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netflix_app/data/models/category_model.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/data/services/category_service.dart';
import 'package:netflix_app/data/services/movie_service.dart';
import 'package:netflix_app/utils/utils.dart';
import 'package:netflix_app/widgets/custom/pagination_widget.dart';
import 'package:netflix_app/widgets/home/content/movie_grid.dart';

class MovieTypeScreen extends StatefulWidget {
  final String code;

  const MovieTypeScreen({super.key, required this.code});

  @override
  MovieTypeScreenState createState() => MovieTypeScreenState();
}

class MovieTypeScreenState extends State<MovieTypeScreen> {
  late int _selectedCategoryId = 0;
  late Future<CategoryModel?> _categoryFuture; // Future cho Category
  late Future<List<CategoryModel>> _categoriesFuture; // Future cho Category
  late String _title;
  int _currentPage = 1; // Số trang hiện tại
  int _pageSize = 1; // Số lượng phim mỗi trang
  bool _isLoading = false; // Biến kiểm tra trạng thái tải dữ liệu
  List<MovieModel> _movies = []; // Danh sách các bộ phim
  int _totalPages =
      1; // Tổng số trang, có thể tính được từ tổng số phim / pageSize

  @override
  void initState() {
    super.initState();
    if (_selectedCategoryId != 0) {
      _categoryFuture = CategoryService.loadCategoryById(_selectedCategoryId);
    } else {
      _categoryFuture = Future.value(null);
    }
    _categoriesFuture = CategoryService.loadCategories();
    _title = getTitleFromKey(widget.code);
    _loadMovies(); // Tải phim cho trang đầu tiên
  }

  // Hàm tải danh sách phim từ API (với phân trang)
  void _loadMovies() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Lấy toàn bộ danh sách phim trước
    final allMovies = await MovieService.loadAllMovies();

    final movies = await MovieService.loadMoviesByWithPagination(
      _selectedCategoryId,
      widget.code,
      _currentPage,
      _pageSize,
    );

    setState(() {
      _isLoading = false;
      _movies = movies;
      int totalMovies = allMovies.length;
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
                          setState(() {
                            // Nếu đã chọn danh mục hiện tại, reset
                            if (_selectedCategoryId == category.id) {
                              _selectedCategoryId = 0;
                              _categoryFuture = Future.value(
                                null,
                              ); // Xóa dữ liệu category
                            } else {
                              // Cập nhật danh mục mới
                              _selectedCategoryId = category.id;
                              _categoryFuture =
                                  CategoryService.loadCategoryById(
                                    _selectedCategoryId,
                                  );
                            }
                          });
                          Navigator.pop(
                            context,
                            category,
                          ); // Đóng menu khi chọn
                          _currentPage = 1;
                          _loadMovies(); // Lọc lại các bộ phim
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
                                    : Colors.black87,
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
                              Expanded(
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

    // Nếu không có category nào được chọn, set lại dữ liệu category về null
    if (selectedCategory == null) {
      setState(() {
        _selectedCategoryId = 0;
        _categoryFuture = Future.value(null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _title.isNotEmpty ? _title : "Loading...",
              // Nếu _title không rỗng, hiển thị _title, nếu không hiển thị "Loading..."
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white, // Màu chữ nhẹ nhàng hơn
              ),
            ),

            const SizedBox(width: 8),

            // Sử dụng FutureBuilder để hiển thị tên thể loại từ _categoryFuture
            FutureBuilder<CategoryModel?>(
              future: _categoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    "Loading...",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const Text("");
                }
                final category = snapshot.data;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ), // Khoảng cách trong viền
                  decoration: BoxDecoration(
                    color: Colors.redAccent, // Màu nền đỏ
                    border: Border.all(
                      color: Colors.redAccent, // Màu viền đỏ đậm
                      width: 2, // Độ dày viền
                    ),
                    borderRadius: BorderRadius.circular(8), // Bo góc viền
                  ),
                  child: Text(
                    category?.name ?? 'Danh mục không xác định',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white, // Màu chữ trắng
                      fontWeight: FontWeight.w500, // Làm chữ đậm
                    ),
                  ),
                );
              },
            ),
          ],
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
                        fontWeight: FontWeight.bold,
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
