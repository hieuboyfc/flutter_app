import 'package:flutter/material.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/data/services/movie_service.dart';

class MovieCategoryContent extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const MovieCategoryContent({super.key, required this.categoryId, required this.categoryName});

  @override
  _MovieCategoryContentState createState() => _MovieCategoryContentState();
}

class _MovieCategoryContentState extends State<MovieCategoryContent> {
  late Future<List<MovieModel>> _categoryMoviesFuture;

  @override
  void initState() {
    super.initState();
    _categoryMoviesFuture = MovieService.loadMoviesByCategory(widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Đảm bảo có Scaffold bao quanh widget
      appBar: AppBar(
        title: Text(widget.categoryName), // Tiêu đề danh mục
      ),
      body: ListView(
        children: [
          FutureBuilder<List<MovieModel>>(
            future: _categoryMoviesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Không có phim nào trong thể loại này!"));
              }

              return Column(
                children:
                    snapshot.data!.map((movie) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: ListTile(
                          title: Text(movie.title),
                          subtitle: Text("Số tập: ${movie.episodes}"),
                          leading: Image.network(movie.image),
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
