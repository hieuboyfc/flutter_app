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
  final List<String> genres;
  final List<String> actors;
  final String releaseDate;
  final int voteCount;
  final String overview;
  final String posterPath;

  MovieModel({
    required this.id,
    required this.title,
    required this.image,
    required this.episodes,
    required this.rating,
    required this.weekDay,
    required this.categoryId,
    this.isHot = false,
    this.isNew = false,
    this.isWatched = false,
    required this.genres,
    required this.actors,
    required this.releaseDate,
    required this.voteCount,
    required this.overview,
    required this.posterPath,
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
      genres: List<String>.from(json['genres'] ?? []),
      actors: List<String>.from(json['actors'] ?? []),
      releaseDate: json['releaseDate'] ?? 'N/A',
      voteCount: json['voteCount'] ?? 0,
      overview: json['overview'] ?? '',
      posterPath: json['posterPath'] ?? '',
    );
  }

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
      'genres': genres,
      'actors': actors,
      'releaseDate': releaseDate,
      'voteCount': voteCount,
      'overview': overview,
      'posterPath': posterPath,
    };
  }
}
