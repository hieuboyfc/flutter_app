import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netflix_app/data/models/category_model.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/data/services/auth_service.dart';
import 'package:netflix_app/data/services/category_service.dart';
import 'package:netflix_app/data/services/movie_service.dart';
import 'package:netflix_app/utils/utils.dart';
import 'package:netflix_app/widgets/custom/sticky_header_delegate.dart';

import '../../screens/base/base_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String? loggedInUser;
  int _currentSlide = 0;
  int _selectedDay = 0;
  bool _isRefreshing = false;

  Map<String, bool> isRefreshingMap = {
    "movies_by_day": false,
    "hot_movies": false,
    "new_movies": false,
    "saved_movies": false,
  };

  final Map<String, ScrollController> _scrollControllers = {};
  final Map<String, int> _currentPage = {};
  final Map<String, int> _totalPages = {};
  final Map<String, bool> _isLoadingMore = {};

  late Future<List<CategoryModel>> _categoriesFuture;
  List<MovieModel> _movies = [];
  List<MovieModel> _hotMovies = [];
  List<MovieModel> _newMovies = [];
  List<MovieModel> _moviesByDay = [];
  List<MovieModel> _savedMovies = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _categoriesFuture = CategoryService.loadCategories();
    // Gọi phương thức bất đồng bộ sau khi widget đã được khởi tạo
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    // Chờ các dữ liệu mới
    List<MovieModel> movies = await MovieService.loadMovies();
    List<MovieModel> hotMovies = await MovieService.loadHotMovies();
    List<MovieModel> newMovies = await MovieService.loadNewMovies();
    List<MovieModel> moviesByDay = await MovieService.loadMoviesByDay(
      _selectedDay,
    );

    List<MovieModel> savedMovies = [];
    if (loggedInUser != null) {
      savedMovies = await MovieService.loadSavedMovies(loggedInUser!);
    }

    // Cập nhật lại state sau khi dữ liệu đã được tải
    setState(() {
      _movies = movies;
      _hotMovies = hotMovies;
      _newMovies = newMovies;
      _moviesByDay = moviesByDay;
      _savedMovies = savedMovies;
    });

    _initScrollControllers();
    _initPaginationState();
  }

  void _initScrollControllers() {
    List<String> movieByKeyTitles = [
      "movies_by_day",
      "hot_movies",
      "new_movies",
      "saved_movies",
    ];

    for (var keyTitle in movieByKeyTitles) {
      _scrollControllers[keyTitle] =
          ScrollController()..addListener(() {
            if (_scrollControllers[keyTitle]!.position.pixels >=
                    _scrollControllers[keyTitle]!.position.maxScrollExtent -
                        100 &&
                !_isLoadingMore[keyTitle]!) {
              _loadMoreMovies(keyTitle);
            }
          });
    }
  }

  void _initPaginationState() {
    List<String> movieByKeyTitles = [
      "movies_by_day",
      "hot_movies",
      "new_movies",
      "saved_movies",
    ];

    for (var keyTitle in movieByKeyTitles) {
      _currentPage[keyTitle] = 1; // Bắt đầu từ trang 1
      _totalPages[keyTitle] = 10; // Giả sử có 10 trang (lấy từ API)
      _isLoadingMore[keyTitle] = false;
    }
  }

  Future<void> _loadMoreMovies(String keyTitle) async {
    // Kiểm tra trạng thái tải và số trang
    if (_isLoadingMore[keyTitle]! ||
        _currentPage[keyTitle]! >= _totalPages[keyTitle]!) {
      return;
    }

    // Cập nhật trạng thái đang tải dữ liệu
    setState(() {
      _isLoadingMore[keyTitle] = true;
    });

    int newPage = _currentPage[keyTitle]! + 1;

    late Future<List<MovieModel>> newMoviesFuture;

    // Lấy dữ liệu mới tùy theo keyTitle
    if (keyTitle == "hot_movies") {
      newMoviesFuture = MovieService.loadHotMovies(page: newPage);
    } else if (keyTitle == "new_movies") {
      newMoviesFuture = MovieService.loadNewMovies(page: newPage);
    } else if (keyTitle == "movies_by_day") {
      newMoviesFuture = MovieService.loadMoviesByDay(
        _selectedDay,
        page: newPage,
      );
    } else if (keyTitle == "saved_movies" && loggedInUser != null) {
      newMoviesFuture = MovieService.loadSavedMovies(
        loggedInUser!,
        page: newPage,
      );
    }

    // Đợi Future hoàn thành và xử lý kết quả
    try {
      List<MovieModel> newMovies = await newMoviesFuture;

      setState(() {
        // Cập nhật các danh sách phim
        if (keyTitle == "hot_movies") {
          _hotMovies.addAll(newMovies); // Thêm dữ liệu mới vào danh sách cũ
        } else if (keyTitle == "new_movies") {
          _newMovies.addAll(newMovies); // Thêm dữ liệu mới vào danh sách cũ
        } else if (keyTitle == "movies_by_day") {
          _moviesByDay.addAll(newMovies); // Thêm dữ liệu mới vào danh sách cũ
        } else if (keyTitle == "saved_movies" && loggedInUser != null) {
          _savedMovies.addAll(newMovies); // Thêm dữ liệu mới vào danh sách cũ
        }

        // Cập nhật trạng thái
        _currentPage[keyTitle] = newPage; // Cập nhật số trang
        _isLoadingMore[keyTitle] = false; // Tắt trạng thái đang tải
      });
    } catch (e) {
      setState(() {
        _isLoadingMore[keyTitle] = false; // Nếu có lỗi, tắt trạng thái đang tải
      });
      print("Error loading more movies: $e");
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true; // Bắt đầu tải lại dữ liệu
    });

    try {
      // Chờ các dữ liệu mới
      List<MovieModel> movies = await MovieService.loadMovies();
      List<MovieModel> hotMovies = await MovieService.loadHotMovies();
      List<MovieModel> newMovies = await MovieService.loadNewMovies();
      List<MovieModel> moviesByDay = await MovieService.loadMoviesByDay(
        _selectedDay,
      );

      List<MovieModel> savedMovies = [];
      if (loggedInUser != null) {
        savedMovies = await MovieService.loadSavedMovies(loggedInUser!);
      }

      // Sau khi dữ liệu đã tải xong, cập nhật state
      setState(() {
        _categoriesFuture = CategoryService.loadCategories();
        _movies = movies;
        _hotMovies = hotMovies;
        _newMovies = newMovies;
        _moviesByDay = moviesByDay;
        _savedMovies = savedMovies;

        _isRefreshing = false; // Tắt trạng thái đang làm mới
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false; // Tắt trạng thái làm mới nếu có lỗi
      });
      print("Error refreshing data: $e");
    }
  }

  void _checkLoginStatus() async {
    String? user = await AuthService.getLoggedInUser();
    setState(() {
      loggedInUser = user;
    });

    if (user != null) {
      _loadSavedMovies(user);
    }
  }

  void _loadSavedMovies(String userId) async {
    List<MovieModel> savedMovies = await MovieService.loadSavedMovies(userId);
    setState(() {
      _savedMovies = savedMovies;
    });
  }

  void _updateMoviesByDay(int dayIndex) async {
    List<MovieModel> moviesByDay = await MovieService.loadMoviesByDay(dayIndex);
    setState(() {
      _selectedDay = dayIndex;
      _moviesByDay = moviesByDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BaseScreen(
          initialIndex: 0,
          showHeader: true,
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: CustomScrollView(
              key: const PageStorageKey<String>("movie_content"),
              slivers: [
                // Danh sách phim chính
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  sliver: SliverToBoxAdapter(
                    child:
                        _movies.isEmpty
                            ? const Center(child: Text("Không có phim nào!"))
                            : Column(
                              children: [_buildFeaturedMoviesSlider(_movies)],
                            ),
                  ),
                ),

                // Ghim _buildCategorySelector() khi cuộn xuống
                SliverPersistentHeader(
                  pinned: true, // Giữ cố định khi cuộn
                  floating: false,
                  delegate: StickyHeaderDelegate(
                    child: _buildCategorySelector(),
                    height: 50.0, // Chiều cao của header
                  ),
                ),

                // Danh sách phim khác
                SliverToBoxAdapter(child: _buildWeekdayMovies()),
                SliverToBoxAdapter(
                  child: _buildMovies(
                    "movies_by_day",
                    _moviesByDay,
                    isSmall: true,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMovies("hot_movies", _hotMovies),
                ),
                SliverToBoxAdapter(
                  child: _buildMovies("new_movies", _newMovies),
                ),
                if (loggedInUser != null)
                  SliverToBoxAdapter(
                    child: _buildMovies("saved_movies", _savedMovies),
                  ),
              ],
            ),
          ),
        ),

        // Lớp loading bao phủ toàn bộ màn hình khi _isRefreshing == true
        if (_isRefreshing)
          Container(
            color: Colors.black.withValues(alpha: 0.5), // Lớp che mờ
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedMoviesSlider(List<MovieModel> movies) {
    return CarouselSlider(
      items:
          movies.map((movie) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(movie.image),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Column(
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Số tập: ${movie.episodes}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < movie.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.yellow,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      options: CarouselOptions(
        height: 250,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        onPageChanged: (index, reason) {
          setState(() {
            _currentSlide = index;
          });
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 40, // Điều chỉnh chiều cao để phù hợp với header
      child: FutureBuilder<List<CategoryModel>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.red));
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "Không có thể loại!",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              double totalWidth =
                  snapshot.data!.length * 120.0; // Ước tính chiều rộng tổng
              bool shouldCenter =
                  totalWidth <
                  constraints.maxWidth; // Kiểm tra có cần căn giữa không

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment:
                      shouldCenter
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                  children:
                      snapshot.data!.map((category) {
                        return GestureDetector(
                          onTap: () {
                            context.go('/movie/category/${category.id}');
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWeekdayMovies() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = weekDays.length * 100.0; // Ước tính tổng chiều rộng
        bool shouldCenter = totalWidth < constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: shouldCenter ? constraints.maxWidth : null,
            alignment: shouldCenter ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              // Để Row chỉ chiếm đúng kích thước cần thiết
              mainAxisAlignment:
                  shouldCenter
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
              children: List.generate(weekDays.length, (index) {
                return GestureDetector(
                  onTap: () => _updateMoviesByDay(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _selectedDay == index
                              ? Colors.redAccent
                              : Colors.grey,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      weekDays[index],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovies(
    String keyTitle,
    List<MovieModel> movies, {
    bool isSmall = false,
  }) {
    if (movies.isEmpty) {
      return const Center(child: Text("Không có phim nào!"));
    }
    return _buildMovieList(keyTitle, movies, isSmall);
  }

  Widget _buildMovieList(
    String keyTitle,
    List<MovieModel> movies,
    bool isSmall,
  ) {
    String title = getTitleFromKey(keyTitle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tiêu đề danh mục
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Giống Netflix
                ),
              ),

              // Nút "Xem thêm"
              GestureDetector(
                onTap: () {
                  // Điều hướng đến danh sách đầy đủ của danh mục phim
                  context.go('/movie/type/$keyTitle');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                  child: Text(
                    "Xem thêm",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildMovieListContent(keyTitle, movies, isSmall),
      ],
    );
  }

  Widget _buildMovieListContent(
    String keyTitle,
    List<MovieModel> movies,
    bool isSmall,
  ) {
    return SizedBox(
      height: isSmall ? 180 : 220,
      child: ListView.builder(
        controller: _scrollControllers[keyTitle],
        scrollDirection: Axis.horizontal,
        itemCount: movies.length + (_isLoadingMore[keyTitle]! ? 1 : 0),
        // +1 để hiển thị loading,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Container(
            width: isSmall ? 150 : 180,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(movie.image),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tập: ${movie.episodes}',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          Row(
                            children: List.generate(5, (starIndex) {
                              if (starIndex < movie.rating.floor()) {
                                return Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.yellow,
                                );
                              } else if (starIndex == movie.rating.floor() &&
                                  movie.rating % 1 >= 0.5) {
                                return Icon(
                                  Icons.star_half,
                                  size: 14,
                                  color: Colors.yellow,
                                );
                              } else {
                                return Icon(
                                  Icons.star_border,
                                  size: 14,
                                  color: Colors.yellow,
                                );
                              }
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
