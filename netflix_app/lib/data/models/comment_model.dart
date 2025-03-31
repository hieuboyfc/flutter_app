enum ReactionType {
  like, // 👍 Thích
  love, // ❤️ Yêu thích
  haha, // 😂 Vui
  wow, // 😮 Ngạc nhiên
  sad, // 😢 Buồn
  angry, // 😡 Phẫn nộ
}

class CommentModel {
  final String id;
  final String userName;
  final String avatarUrl;
  String content;
  final DateTime timestamp;
  List<CommentModel> replies;
  ReactionType? userReaction;
  bool edited;
  String? originalContent;

  CommentModel({
    required this.id,
    required this.userName,
    required this.avatarUrl,
    required this.content,
    required this.timestamp,
    this.replies = const [],
    this.userReaction,
    this.edited = false,
    this.originalContent,
  });

  // Phương thức từ JSON
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      userName: json['userName'],
      avatarUrl: json['avatarUrl'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      replies:
          (json['replies'] as List)
              .map((replyJson) => CommentModel.fromJson(replyJson))
              .toList(),
      userReaction:
          json['userReaction'] != null
              ? ReactionType.values[json['userReaction']]
              : null,
      edited: json['edited'] ?? false,
      originalContent: json['originalContent'],
    );
  }

  // Phương thức chuyển đối tượng thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'userReaction':
          userReaction != null
              ? ReactionType.values.indexOf(userReaction!)
              : null,
      'edited': edited,
      'originalContent': originalContent,
    };
  }

  // Tạo bản sao của comment để sửa
  CommentModel copyWith({
    String? content,
    ReactionType? userReaction,
    bool? edited,
  }) {
    return CommentModel(
      id: this.id,
      userName: this.userName,
      avatarUrl: this.avatarUrl,
      content: content ?? this.content,
      timestamp: this.timestamp,
      replies: this.replies,
      userReaction: userReaction ?? this.userReaction,
      edited: edited ?? this.edited,
      originalContent: this.originalContent ?? this.content,
    );
  }
}
