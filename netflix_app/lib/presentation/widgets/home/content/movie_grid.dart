import 'package:flutter/material.dart';
import 'package:netflix_app/data/models/movie_model.dart';

class MovieGrid extends StatelessWidget {
  final List<MovieModel> movies;
  final Function(String) onMovieTap; // Callback khi người dùng click vào movie

  const MovieGrid({super.key, required this.movies, required this.onMovieTap});

  @override
  Widget build(BuildContext context) {
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
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () {
                  onMovieTap(movie.title); // Callback khi nhấn vào movie
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        onMovieTap(movie.title);
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
                          '${movie.rating}/5 ⭐',
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
}
