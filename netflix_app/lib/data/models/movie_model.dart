class MovieModel {
  final int id;
  final String title;
  final String image;
  final int episodes;
  final double rating;
  final int weekDay;
  final int categoryId;
  final bool isHot;
  final bool isNew;
  final bool isWatched;

  MovieModel({
    required this.id,
    required this.title,
    required this.image,
    required this.episodes,
    required this.rating,
    required this.weekDay,
    required this.categoryId,
    this.isHot = false, // Mặc định là false
    this.isNew = false, // Mặc định là false
    this.isWatched = false, // Mặc định là false,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      image: json['image'] ?? '',
      episodes: json['episodes'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      weekDay: json['weekDay'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
      isHot: json['isHot'] ?? false,
      isNew: json['isNew'] ?? false,
      isWatched: json['isWatched'] ?? false,
    );
  }

  // Chuyển đổi đối tượng MovieModel thành JSON để lưu trữ hoặc gửi tới API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'episodes': episodes,
      'rating': rating,
      'weekDay': weekDay,
      'categoryId': categoryId,
      'isHot': isHot,
      'isNew': isNew,
      'isWatched': isWatched,
    };
  }
}
