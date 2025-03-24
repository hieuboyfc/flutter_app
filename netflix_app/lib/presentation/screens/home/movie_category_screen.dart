import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netflix_app/data/models/category_model.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/data/services/category_service.dart';
import 'package:netflix_app/data/services/movie_service.dart';

class MovieCategoryScreen extends StatefulWidget {
  final int categoryId;

  const MovieCategoryScreen({super.key, required this.categoryId});

  @override
  _MovieCategoryScreenState createState() => _MovieCategoryScreenState();
}

class _MovieCategoryScreenState extends State<MovieCategoryScreen> {
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
        await MovieService.loadMovies(); // Lấy toàn bộ danh sách phim trước
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

  Widget _buildMovieGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double itemSpacing = 8.0 * 3; // Khoảng cách giữa 4 item
        double itemWidth =
            (screenWidth - itemSpacing - 16) / 4.05; // 16 là padding
        double itemHeight = itemWidth * 1.5; // Tỷ lệ phù hợp

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: itemWidth / (itemHeight + 40), // Giảm chiều cao
            ),
            physics: const ClampingScrollPhysics(),
            itemCount: _movies.length,
            itemBuilder: (context, index) {
              final movie = _movies[index];
              return GestureDetector(
                onTap: () {
                  _showFullTitleDialog(context, movie.title);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _showFullTitleDialog(context, movie.title);
                      },
                      child: Container(
                        width: itemWidth,
                        height: itemHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(movie.image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Tooltip(
                      message: movie.title,
                      // Hiển thị tiêu đề đầy đủ khi giữ chuột
                      child: Text(
                        movie.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tập: ${movie.episodes}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${movie.rating}/5 ⭐', // Hiển thị số điểm bên phải
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
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

  Widget _buildPagination() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Nếu lỗi xảy ra theo chiều ngang
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20), // Đẩy lên một chút
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_totalPages > 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentPage > 1) _buildPageButton("❮", _currentPage - 1),
                  for (int i = 1; i <= _totalPages; i++)
                    _buildPageButton("$i", i, isSelected: i == _currentPage),
                  if (_currentPage < _totalPages)
                    _buildPageButton("❯", _currentPage + 1),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton(String text, int page, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      // Giảm khoảng cách giữa các nút
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.red : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          // Giảm bo góc
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          // Giảm padding để nút nhỏ hơn
          minimumSize: const Size(30, 25),
          // Kích thước tối thiểu
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          // Giảm font size
          elevation: isSelected ? 3 : 1, // Hiệu ứng nổi hơn khi được chọn
        ),
        onPressed: () {
          if (_currentPage != page) {
            setState(() {
              _currentPage = page;
              _loadMovies();
            });
          }
        },
        child: Text(text),
      ),
    );
  }

  void _showGenreDropdown(TapDownDetails details) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = details.globalPosition; // Vị trí icon

    final categories = await _categoriesFuture; // Lấy danh sách thể loại

    final selectedCategory = await showMenu<CategoryModel>(
      context: context,
      color: Colors.black87, // Nền tối phong cách Netflix
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + 10,
        overlay.size.width - position.dx,
        0,
      ),
      items:
          categories.map((category) {
            return PopupMenuItem<CategoryModel>(
              value: category,
              child: ListTile(
                leading: const Icon(Icons.movie, color: Colors.red, size: 24),
                // Icon đỏ đậm
                title: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ), // Chữ trắng đậm
                ),
              ),
            );
          }).toList(),
    );

    if (selectedCategory != null) {
      setState(() {
        _selectedCategoryId = selectedCategory.id; // Cập nhật categoryId mới
        _categoryFuture = CategoryService.loadCategoryById(_selectedCategoryId);
        _currentPage = 1; // Reset về trang đầu
        _loadMovies(); // Gọi lại load phim
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
            return Text(snapshot.data!.name);
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
          // 🔹 Dropdown để chọn số bản ghi hiển thị mỗi trang
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Số phim mỗi trang: "),
                DropdownButton<int>(
                  value: _pageSize,
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
                        _currentPage = 1; // Reset về trang đầu khi đổi số lượng
                        _loadMovies(); // Load lại dữ liệu
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _buildMovieGrid(), // Hiển thị danh sách phim
          ),

          _buildPagination(),
          // Hiển thị phân trang nếu có nhiều trang
        ],
      ),
    );
  }
}
