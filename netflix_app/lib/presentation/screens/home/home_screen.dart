import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netflix_app/data/models/category_model.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/data/services/auth_service.dart';
import 'package:netflix_app/data/services/category_service.dart';
import 'package:netflix_app/data/services/movie_service.dart';

import '../../screens/base/base_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  late Future<List<MovieModel>> _moviesFuture;
  late Future<List<MovieModel>> _moviesByDayFuture;
  late Future<List<MovieModel>> _hotMoviesFuture;
  late Future<List<MovieModel>> _newMoviesFuture;
  late Future<List<MovieModel>> _savedMoviesFuture;
  late Future<List<CategoryModel>> _categoriesFuture;

  final List<String> _weekDays = [
    "Thứ 2",
    "Thứ 3",
    "Thứ 4",
    "Thứ 5",
    "Thứ 6",
    "Thứ 7",
    "Chủ nhật",
  ];

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _moviesFuture = MovieService.loadMovies();
    _moviesByDayFuture = MovieService.loadMoviesByDay(_selectedDay);
    _hotMoviesFuture = MovieService.loadHotMovies();
    _newMoviesFuture = MovieService.loadNewMovies();
    _categoriesFuture = CategoryService.loadCategories();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true; // Bắt đầu tải lại dữ liệu
    });

    await Future.delayed(Duration(seconds: 1)); // Giả lập thời gian chờ API

    setState(() {
      _moviesFuture = MovieService.loadMovies();
      _moviesByDayFuture = MovieService.loadMoviesByDay(_selectedDay);
      _hotMoviesFuture = MovieService.loadHotMovies();
      _newMoviesFuture = MovieService.loadNewMovies();
      if (loggedInUser != null) {
        _savedMoviesFuture = MovieService.loadSavedMovies(loggedInUser!);
      }
      _isRefreshing = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _loadSavedMovies(String userId) {
    setState(() {
      _savedMoviesFuture = MovieService.loadSavedMovies(userId);
    });
  }

  void _updateMoviesByDay(int dayIndex) {
    setState(() {
      _selectedDay = dayIndex;
      _moviesByDayFuture = MovieService.loadMoviesByDay(dayIndex);
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
                SliverToBoxAdapter(
                  child: FutureBuilder<List<MovieModel>>(
                    future: _moviesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const Center(child: Text("Không có phim nào!"));
                      }

                      return Column(
                        children: [_buildFeaturedMoviesSlider(snapshot.data!)],
                      );
                    },
                  ),
                ),

                // Ghim _buildCategorySelector() khi cuộn xuống
                SliverPersistentHeader(
                  pinned: true, // Giữ cố định khi cuộn
                  floating: false,
                  delegate: _StickyHeaderDelegate(
                    child: _buildCategorySelector(),
                    height: 50.0, // Chiều cao của header
                  ),
                ),

                // Danh sách phim khác
                SliverToBoxAdapter(child: _buildWeekdayMovies()),
                SliverToBoxAdapter(
                  child: _buildFutureMovieList(
                    "movies_by_day",
                    _moviesByDayFuture,
                    isSmall: true,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildFutureMovieList("hot_movies", _hotMoviesFuture),
                ),
                SliverToBoxAdapter(
                  child: _buildFutureMovieList("new_movies", _newMoviesFuture),
                ),
                if (loggedInUser != null)
                  SliverToBoxAdapter(
                    child: _buildFutureMovieList(
                      "saved_movies",
                      _savedMoviesFuture,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Lớp loading bao phủ toàn bộ màn hình khi _isRefreshing == true
        if (_isRefreshing)
          Container(
            color: Colors.black.withOpacity(0.5), // Lớp che mờ
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
                                  color: Colors.redAccent.withOpacity(0.3),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_weekDays.length, (index) {
          return GestureDetector(
            onTap: () => _updateMoviesByDay(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: _selectedDay == index ? Colors.redAccent : Colors.grey,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _weekDays[index],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFutureMovieList(
    String keyTitle,
    Future<List<MovieModel>> futureMovies, {
    bool isSmall = false,
  }) {
    return FutureBuilder<List<MovieModel>>(
      future: futureMovies,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const Center(child: Text("Không có phim nào!"));
        }
        return _buildMovieList(keyTitle, snapshot.data!, isSmall);
      },
    );
  }

  Widget _buildMovieList(
    String keyTitle,
    List<MovieModel> movies,
    bool isSmall,
  ) {
    String title = _getTitleFromKey(keyTitle);

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
                  context.go('/movie/list-by/$keyTitle');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
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
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
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
                    color: Colors.black.withOpacity(0.6),
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

  String _getTitleFromKey(String keyTitle) {
    switch (keyTitle) {
      case "movies_by_day":
        return "📅 Phim Theo Ngày";
      case "hot_movies":
        return "🔥 Phim Hot";
      case "new_movies":
        return "🎬 Phim Mới";
      case "saved_movies":
        return "💾 Phim Đã Lưu";
      default:
        return "Danh Sách Phim";
    }
  }
}

// Tạo Delegate cho SliverPersistentHeader
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 5), // Điều chỉnh padding nếu cần
      child: Center(child: child), // Đảm bảo căn giữa nội dung
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
