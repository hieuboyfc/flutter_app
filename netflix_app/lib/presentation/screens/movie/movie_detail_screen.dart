import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netflix_app/data/models/movie_model.dart';
import 'package:netflix_app/data/services/movie_service.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  MovieDetailScreenState createState() => MovieDetailScreenState();
}

class MovieDetailScreenState extends State<MovieDetailScreen> {
  late Future<MovieModel?> movieFuture;

  @override
  void initState() {
    super.initState();
    movieFuture = MovieService.getById(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết phim"),
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
      body: FutureBuilder<MovieModel?>(
        future: movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Không tìm thấy dữ liệu"));
          }

          final movie = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📌 Ảnh + Thông tin phim (Căn giữa, tự co giãn)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 📌 Căn giữa toàn bộ nội dung
                  crossAxisAlignment: CrossAxisAlignment.start, // 📌 Chữ sẽ nằm trên cùng
                  children: [
                    // 📌 Ảnh phim
                    Flexible(
                      flex: 2, // Chia tỉ lệ 2:3 giữa ảnh và chữ
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.network(
                          movie.image,
                          width: double.infinity, // 📌 Đảm bảo ảnh co giãn tốt
                          height: 270,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // 📌 Khoảng cách giữa ảnh và chữ
                    const SizedBox(width: 20),

                    // 📌 Thông tin phim (Căn giữa)
                    Flexible(
                      flex: 3, // Chia tỉ lệ 2:3 giữa ảnh và chữ
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // 📌 Căn giữa chữ
                        children: [
                          Text(
                            movie.title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center, // 📌 Căn giữa văn bản
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Thể loại: ${movie.genres.join(", ")}",
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center, // 📌 Căn giữa văn bản
                          ),
                          Text(
                            "Ngày phát hành: ${movie.releaseDate}",
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "Đánh giá: ${movie.rating} ⭐ (${movie.voteCount} lượt)",
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "Diễn viên: ${movie.actors.join(", ")}",
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 📌 2️⃣ Nội dung phim
                const Text(
                  "Nội dung:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(movie.overview, style: const TextStyle(fontSize: 16)),

                const SizedBox(height: 24),

                // 📌 3️⃣ Nút xem phim + Thêm vào yêu thích
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Xem phim"),
                      onPressed: () {
                        // TODO: Chuyển sang trang xem phim
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.favorite_border),
                      label: const Text("Thêm vào yêu thích"),
                      onPressed: () {
                        // TODO: Xử lý thêm vào danh sách yêu thích
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 📌 4️⃣ Bình luận (Tạm thời là danh sách giả lập)
                const Text(
                  "Bình luận:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._buildFakeComments(),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🔥 Danh sách bình luận + Trả lời bình luận
  List<Widget> _buildFakeComments() {
    List<Map<String, dynamic>> fakeComments = [
      {
        "name": "Nguyễn Văn A",
        "comment": "Phim rất hay!",
        "replies": [
          {"name": "Trần Thị B", "comment": "Đúng rồi, mình cũng thích lắm!"},
          {"name": "Lê Văn C", "comment": "Bạn coi ở đâu thế?"},
        ],
      },
      {
        "name": "Trần Thị D",
        "comment": "Mình thích diễn viên chính ❤️",
        "replies": [
          {"name": "Nguyễn Văn E", "comment": "Chuẩn luôn, diễn quá đỉnh!"},
        ],
      },
      {"name": "Lê Văn F", "comment": "Cảnh quay mãn nhãn quá!", "replies": []},
    ];

    return fakeComments.map((cmt) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📌 Bình luận chính
          _buildCommentItem(cmt["name"], cmt["comment"]),

          // 📌 Danh sách câu trả lời (nếu có)
          if (cmt["replies"].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40), // 📌 Lùi vào để làm reply
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    cmt["replies"]
                        .map<Widget>((reply) => _buildCommentItem(reply["name"], reply["comment"]))
                        .toList(),
              ),
            ),

          // 📌 Khoảng cách giữa các bình luận
          const SizedBox(height: 8),
        ],
      );
    }).toList();
  }

  // ✅ Widget hiển thị 1 bình luận
  Widget _buildCommentItem(String name, String comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ảnh đại diện
        const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 8),

        // Nội dung bình luận
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(comment),
            ],
          ),
        ),
      ],
    );
  }
}
