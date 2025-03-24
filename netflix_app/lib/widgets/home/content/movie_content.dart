import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:netflix_app/data/models/category_model.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/data/services/auth_service.dart';
import 'package:netflix_app/data/services/category_service.dart';
import 'package:netflix_app/data/services/movie_service.dart';
import 'package:netflix_app/widgets/home/content/movie_category_content.dart';

class MovieContent extends StatefulWidget {
  const MovieContent({super.key});

  @override
  _MovieContentState createState() => _MovieContentState();
}

class _MovieContentState extends State<MovieContent> {
  String? loggedInUser;
  int _currentSlide = 0;
  int _selectedDay = 0;

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
  late Future<List<MovieModel>> _savedMoviesFuture; // Biến cho phim đã lưu
  late Future<List<CategoryModel>> _categoriesFuture; // Biến cho thể loại

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
    return Scaffold(
      // Đảm bảo Scaffold bao quanh
      appBar: AppBar(title: const Text("Movies")),
      body: ListView(
        controller: _scrollController,
        key: PageStorageKey<String>("movie_content"),
        children: [
          FutureBuilder<List<MovieModel>>(
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
                children: [
                  _buildFeaturedMoviesSlider(snapshot.data!),
                  _buildCategorySelector(),
                  _buildWeekdayMovies(),
                  _buildFutureMovieList(
                    "movies_by_day",
                    _moviesByDayFuture,
                    isSmall: true,
                  ),
                  _buildFutureMovieList("hot_movies", _hotMoviesFuture),
                  _buildFutureMovieList("new_movies", _newMoviesFuture),
                  if (loggedInUser != null)
                    _buildFutureMovieList("saved_movies", _savedMoviesFuture),
                ],
              );
            },
          ),
        ],
      ),
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
    return FutureBuilder<List<CategoryModel>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const Center(child: Text("Không có thể loại!"));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                snapshot.data!.map((category) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MovieCategoryContent(
                                categoryId: category.id,
                                categoryName: category.name,
                              ),
                        ),
                      );
                    },
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
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      },
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
                borderRadius: BorderRadius.circular(20),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    _refreshMovieList(keyTitle);
                  },
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
      height: isSmall ? 180 : 220, // Điều chỉnh chiều cao
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Container(
            width: isSmall ? 150 : 180, // Điều chỉnh chiều rộng
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
              // Căn chỉnh nội dung vào dưới cùng
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lớp phủ mờ bao phủ toàn bộ phần text
                Container(
                  width: double.infinity,
                  // Đảm bảo lớp phủ bao phủ toàn bộ container
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên bộ phim
                      Text(
                        movie.title, // Tên bộ phim
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Thêm độ giãn cách giữa tên phim và dòng dưới
                      SizedBox(height: 4),
                      // Khoảng cách giữa tên bộ phim và dòng số tập + sao đánh giá

                      // Dòng số tập và sao đánh giá
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // Giãn cách số tập và sao
                        children: [
                          // Số tập
                          Text(
                            'Tập: ${movie.episodes}', // Hiển thị số tập
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          // Sao đánh giá (Ví dụ 5.5 sao)
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

  void _refreshMovieList(String keyTitle) {
    setState(() {
      switch (keyTitle) {
        case "movies_by_day":
          _moviesByDayFuture = MovieService.loadMoviesByDay(_selectedDay);
          break;
        case "hot_movies":
          _hotMoviesFuture = MovieService.loadHotMovies();
          break;
        case "new_movies":
          _newMoviesFuture = MovieService.loadNewMovies();
          break;
        case "saved_movies":
          if (loggedInUser != null) {
            _savedMoviesFuture = MovieService.loadSavedMovies(loggedInUser!);
          }
          break;
      }
    });
  }
}
