import 'package:flutter/material.dart';
import 'package:netflix_app/data/models/movie_model.dart';

class SearchPopup extends StatelessWidget {
  final List<MovieModel> searchResults;
  final VoidCallback onClose;

  const SearchPopup({super.key, required this.searchResults, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Vùng click ra ngoài để đóng popup
        Positioned.fill(
          top: 60, // Không che header
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),

        // Popup kết quả tìm kiếm
        Positioned(
          left: 20,
          right: 20,
          top: 100,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    searchResults.isEmpty
                        ? [
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Không tìm thấy kết quả',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ]
                        : searchResults.map((movie) {
                          return GestureDetector(
                            onTap: onClose,
                            child: ListTile(
                              leading: Image.network(movie.image, width: 50, fit: BoxFit.cover),
                              title: Text(movie.title, style: const TextStyle(color: Colors.white)),
                            ),
                          );
                        }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
