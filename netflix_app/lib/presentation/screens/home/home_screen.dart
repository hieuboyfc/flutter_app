import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netflix_app/core/utils/utils.dart';
import 'package:netflix_app/data/models/category_model.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/data/services/auth_service.dart';
import 'package:netflix_app/data/services/category_service.dart';
import 'package:netflix_app/data/services/movie_service.dart';
import 'package:netflix_app/presentation/screens/base/base_screen.dart';
import 'package:netflix_app/presentation/widgets/common/marquee_text.dart';
import 'package:netflix_app/presentation/widgets/common/sticky_header_delegate.dart';

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
  bool _isLoading = false;

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
  late Future<List<MovieModel>> _moviesFuture;

  List<MovieModel> moviesByDay = [];
  List<MovieModel> hotMovies = [];
  List<MovieModel> newMovies = [];
  List<MovieModel> savedMovies = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    // Khởi tạo các Future cho các danh sách dữ liệu
    _categoriesFuture = CategoryService.loadCategories();
    _moviesFuture = MovieService.loadMovies();

    _initData();
    _initScrollControllers();
    _initPaginationState();
  }

  Future<void> _initData() async {
    // Chờ các dữ liệu mới
    var fetchMoviesByDay = await MovieService.loadMoviesByDay(_selectedDay);
    var fetchHotMovies = await MovieService.loadHotMovies();
    var fetchNewMovies = await MovieService.loadNewMovies();

    List<MovieModel> fetchSavedMovies =
        loggedInUser != null ? await MovieService.loadSavedMovies(loggedInUser!) : [];

    setState(() {
      moviesByDay = fetchMoviesByDay;
      hotMovies = fetchHotMovies;
      newMovies = fetchNewMovies;
      savedMovies = fetchSavedMovies;
    });
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initScrollControllers() {
    List<String> movieByKeyTitles = ["movies_by_day", "hot_movies", "new_movies", "saved_movies"];

    for (var keyTitle in movieByKeyTitles) {
      _scrollControllers[keyTitle] =
          ScrollController()..addListener(() {
            if (_scrollControllers[keyTitle]!.position.pixels >=
                    _scrollControllers[keyTitle]!.position.maxScrollExtent - 100 &&
                !_isLoadingMore[keyTitle]!) {
              _loadMoreMovies(keyTitle);
            }
          });
    }
  }

  void _initPaginationState() {
    List<String> movieByKeyTitles = ["movies_by_day", "hot_movies", "new_movies", "saved_movies"];

    for (var keyTitle in movieByKeyTitles) {
      _currentPage[keyTitle] = 1;
      _totalPages[keyTitle] = 10;
      _isLoadingMore[keyTitle] = false;
    }
  }

  Future<void> _loadMoreMovies(String keyTitle) async {
    if (_isLoadingMore[keyTitle]! || _currentPage[keyTitle]! >= _totalPages[keyTitle]!) {
      return;
    }

    setState(() {
      _isLoadingMore[keyTitle] = true;
    });

    int newPage = _currentPage[keyTitle]! + 1;
    late Future<List<MovieModel>> moviesFuture;

    try {
      switch (keyTitle) {
        case "movies_by_day":
          moviesFuture = MovieService.loadMoviesByDay(_selectedDay, page: newPage);
          break;
        case "hot_movies":
          moviesFuture = MovieService.loadHotMovies(page: newPage);
          break;
        case "new_movies":
          moviesFuture = MovieService.loadNewMovies(page: newPage);
          break;
        case "saved_movies":
          if (loggedInUser != null) {
            moviesFuture = MovieService.loadSavedMovies(loggedInUser!, page: newPage);
          } else {
            print("Tránh việc gọi API nếu chưa có người dùng đăng nhập");
            return;
          }
          break;
        default:
          print("Trường hợp không hợp lệ");
          return;
      }

      List<MovieModel> fetchMovies = await moviesFuture;

      if (fetchMovies.isEmpty) {
        setState(() {
          _isLoadingMore[keyTitle] = false;
        });
        return;
      } else {
        await Future.delayed(Duration(milliseconds: 300));
      }

      setState(() {
        switch (keyTitle) {
          case "movies_by_day":
            moviesByDay.addAll(fetchMovies);
            break;
          case "hot_movies":
            hotMovies.addAll(fetchMovies);
            break;
          case "new_movies":
            newMovies.addAll(fetchMovies);
            break;
          case "saved_movies":
            if (loggedInUser != null) {
              savedMovies.addAll(fetchMovies);
            }
            break;
        }

        _currentPage[keyTitle] = newPage;
        _isLoadingMore[keyTitle] = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore[keyTitle] = false;
      });
      print("Error loading more movies: $e");
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(Duration(seconds: 1));

    try {
      setState(() {
        _categoriesFuture = CategoryService.loadCategories();
        _moviesFuture = MovieService.loadMovies();

        _initData();
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      print("Error refreshing data: $e");
    }
  }

  void _checkLoginStatus() async {
    String? userId = await AuthService.getLoggedInUser();
    setState(() {
      loggedInUser = userId;
    });

    if (userId != null) {
      _loadSavedMovies(userId);
    }
  }

  void _loadSavedMovies(String userId) async {
    var fetchSavedMovies = await MovieService.loadSavedMovies(userId);
    setState(() {
      savedMovies = fetchSavedMovies;
    });
  }

  void _updateMoviesByDay(int dayIndex) async {
    String keyTitle = 'movies_by_day';

    if (_isLoading) return;

    setState(() {
      moviesByDay = [];
      _isLoading = true;
      _selectedDay = dayIndex;
    });

    try {
      var fetchMovies = await MovieService.loadMoviesByDay(dayIndex);

      if (fetchMovies.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: 300));
      }

      // Cuộn về đầu nếu có dữ liệu
      if (fetchMovies.isNotEmpty && _scrollControllers[keyTitle]?.hasClients == true) {
        // Đảm bảo chỉ cuộn sau khi dữ liệu đã được tải xong
        _scrollControllers[keyTitle]?.jumpTo(0); // Cuộn về đầu
      }

      setState(() {
        moviesByDay = fetchMovies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error loading movies: $e");
    }
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
                // Danh sách phim Chính
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  // Thêm khoảng cách phía trên
                  sliver: SliverToBoxAdapter(
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
                        return Column(children: [_buildFeaturedMoviesSlider(snapshot.data!)]);
                      },
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

                // Chào mừng
                SliverToBoxAdapter(child: _buildWelcomeMovies()),

                // Danh sách phim khác theo ngày
                SliverToBoxAdapter(child: _buildWeekdayMovies()),
                SliverToBoxAdapter(
                  child: _buildMovieListSection(
                    keyTitle: 'movies_by_day',
                    movies: moviesByDay,
                    isLoading: _isLoading,
                  ),
                ),

                // Danh sách phim Hot
                SliverToBoxAdapter(child: _buildMovieList("hot_movies", hotMovies)),

                // Danh sách phim Mới
                SliverToBoxAdapter(child: _buildMovieList("new_movies", newMovies)),

                // Danh sách phim Đã lưu
                if (loggedInUser != null)
                  SliverToBoxAdapter(child: _buildMovieList("saved_movies", savedMovies)),
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
                image: DecorationImage(image: NetworkImage(movie.image), fit: BoxFit.cover),
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
                              index < movie.rating ? Icons.star : Icons.star_border,
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
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Không có thể loại!", style: TextStyle(color: Colors.white)));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              double totalWidth = snapshot.data!.length * 120.0; // Ước tính chiều rộng tổng
              bool shouldCenter =
                  totalWidth < constraints.maxWidth; // Kiểm tra có cần căn giữa không

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment:
                      shouldCenter ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children:
                      snapshot.data!.map((category) {
                        return GestureDetector(
                          onTap: () {
                            context.go('/movie/category/${category.id}');
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.redAccent, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(alpha: 0.3),
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

  Widget _buildWelcomeMovies() {
    return MarqueeText(
      text:
          "Chào mừng bạn đến với ứng dụng xem phim Netflix, hãy click vào quảng cáo để giúp ứng dụng phát triển hơn nhé <3.",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.5,
        shadows: [
          Shadow(blurRadius: 4.0, color: Colors.black.withValues(alpha: 0.6), offset: Offset(0, 2)),
        ],
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
              mainAxisAlignment: shouldCenter ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: List.generate(weekDays.length, (index) {
                // Kiểm tra xem index có hợp lệ không
                if (index >= 0 && index < weekDays.length) {
                  return GestureDetector(
                    onTap: () async => _updateMoviesByDay(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _selectedDay == index ? Colors.redAccent : Colors.grey,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        weekDays[index],
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  );
                } else {
                  // Trả về một widget trống nếu index không hợp lệ
                  return Container();
                }
              }),
            ),
          ),
        );
      },
    );
  }

  /*Widget _buildMovieListSection({
    required String keyTitle,
    required Future<List<MovieModel>> futureMovies,
    bool isLoading = false,
  }) {
    String title = getTitleFromKey(keyTitle);

    return FutureBuilder<List<MovieModel>>(
      future: futureMovies,
      builder: (context, snapshot) {
        // Kiểm tra kết nối dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Xử lý trường hợp lỗi hoặc không có dữ liệu
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Không có phim nào!"));
        }

        // Nếu có dữ liệu, hiển thị phim
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
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
                      child: const Text(
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
            // Hiển thị các bộ phim, bao bọc trong Stack để có thể làm mờ và hiển thị vòng quay
            Stack(
              children: [
                _buildMovieListContentByDay(
                  keyTitle,
                  snapshot.data!,
                  isLoading,
                ),
                if (isLoading) // Hiển thị vòng xoay khi đang tải
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5), // Mờ nền
                      child: const Center(
                        child:
                            CircularProgressIndicator(), // Vòng quay giữa màn hình
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }*/

  Widget _buildMovieListSection({
    required String keyTitle,
    required List<MovieModel> movies,
    bool isLoading = false,
  }) {
    String title = getTitleFromKey(keyTitle);
    // Nếu có dữ liệu, hiển thị phim
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.go('/movie/type/$keyTitle');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent, width: 1.5),
                  ),
                  child: const Text(
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
        // Hiển thị các bộ phim, bao bọc trong Stack để có thể làm mờ và hiển thị vòng quay
        Stack(
          children: [
            _buildMovieListContentByDay(keyTitle, movies, isLoading),
            if (isLoading) // Hiển thị vòng xoay khi đang tải
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5), // Mờ nền
                  child: const Center(
                    child: CircularProgressIndicator(), // Vòng quay giữa màn hình
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMovieListContentByDay(String keyTitle, List<MovieModel> movies, bool isLoading) {
    // Chỉ cuộn khi có dữ liệu và scrollController đã được gán
    /*if (movies.isNotEmpty && _scrollControllers[keyTitle]?.hasClients == true) {
      // Kiểm tra nếu scrollController đã được gán và có clients
      _scrollControllers[keyTitle]?.jumpTo(0); // Cuộn về đầu
    }*/

    return SizedBox(
      height: 180,
      child: ListView.builder(
        controller: _scrollControllers[keyTitle],
        scrollDirection: Axis.horizontal,
        itemCount: movies.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == movies.length) {
            return Center();
          }
          final movie = movies[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(movie.image), fit: BoxFit.cover),
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
                                return Icon(Icons.star, size: 14, color: Colors.yellow);
                              } else if (starIndex == movie.rating.floor() &&
                                  movie.rating % 1 >= 0.5) {
                                return Icon(Icons.star_half, size: 14, color: Colors.yellow);
                              } else {
                                return Icon(Icons.star_border, size: 14, color: Colors.yellow);
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

  /*Widget _buildFutureMovieList(String keyTitle,
      Future<List<MovieModel>> futureMovies,) {
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
        return _buildMovieList(keyTitle, snapshot.data!);
      },
    );
  }*/

  Widget _buildMovieList(String keyTitle, List<MovieModel> movies) {
    String title = getTitleFromKey(keyTitle);
    bool isLoading = _isLoadingMore[keyTitle]!;

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
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
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
        // Hiển thị các bộ phim, bao bọc trong Stack để có thể làm mờ và hiển thị vòng quay
        Stack(
          children: [
            _buildMovieListContent(keyTitle, movies),
            if (isLoading) // Hiển thị vòng xoay khi đang tải
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5), // Mờ nền
                  child: const Center(
                    child: CircularProgressIndicator(), // Vòng quay giữa màn hình
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMovieListContent(String keyTitle, List<MovieModel> movies) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        controller: _scrollControllers[keyTitle],
        scrollDirection: Axis.horizontal,
        itemCount: movies.length + (_isLoadingMore[keyTitle]! ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == movies.length) {
            // Hiển thị vòng xoay khi đang tải thêm
            return Center(child: CircularProgressIndicator());
          }
          final movie = movies[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(movie.image), fit: BoxFit.cover),
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
                                return Icon(Icons.star, size: 14, color: Colors.yellow);
                              } else if (starIndex == movie.rating.floor() &&
                                  movie.rating % 1 >= 0.5) {
                                return Icon(Icons.star_half, size: 14, color: Colors.yellow);
                              } else {
                                return Icon(Icons.star_border, size: 14, color: Colors.yellow);
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
