import 'dart:math';

import 'package:flutter/material.dart';
import 'package:netflix_app/data/models/comment_model.dart';

class CommentSection extends StatefulWidget {
  final int movieId;

  const CommentSection({super.key, required this.movieId});

  @override
  CommentSectionState createState() => CommentSectionState();
}

class CommentSectionState extends State<CommentSection> {
  List<CommentModel> allComments = [];
  List<CommentModel> displayedComments = [];
  final int initialCommentsToShow = 10;
  Map<String, CommentModel> tempReplies = {};

  @override
  void initState() {
    super.initState();
    _loadComments(widget.movieId);
  }

  void _loadComments(int movieId) {
    List<CommentModel> mockComments = List.generate(50, (index) {
      return CommentModel(
        id: 'cmt$index',
        userName: 'User $index',
        avatarUrl: 'https://i.pravatar.cc/150?img=${index % 70}',
        content: 'Bình luận cho phim $movieId - $index',
        timestamp: DateTime.now().subtract(Duration(minutes: index * 5)),
        replies: [],
        userReaction: null,
        edited: false,
        originalContent: null,
      );
    });

    setState(() {
      allComments = mockComments;
      displayedComments = allComments.take(initialCommentsToShow).toList();
    });
  }

  void _loadMoreComments() {
    int currentLength = displayedComments.length;
    int nextLength = min(currentLength + 10, allComments.length);
    setState(() {
      displayedComments = allComments.take(nextLength).toList();
    });
  }

  void _setReaction(CommentModel comment, ReactionType? reaction) {
    setState(() {
      if (comment.userReaction == reaction) {
        comment.userReaction = null; // If already liked, un-like it.
      } else {
        comment.userReaction = reaction;
      }
    });
  }

  void _showReactionMenu(CommentModel comment, BuildContext context) {
    final reactions = {
      ReactionType.like: "👍",
      ReactionType.love: "❤️",
      ReactionType.wow: "😲",
      ReactionType.haha: "😂",
      ReactionType.sad: "😢",
      ReactionType.angry: "😡",
    };

    showModalBottomSheet(
      context: context,
      builder:
          (_) => SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  reactions.entries.map((entry) {
                    return GestureDetector(
                      onTap: () {
                        _setReaction(comment, entry.key);
                        Navigator.pop(context);
                      },
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 30,
                          color:
                              comment.userReaction == entry.key
                                  ? Colors.blue
                                  : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _toggleReplyBox(CommentModel comment) {
    setState(() {
      // Kiểm tra xem đã có reply tạm thời cho comment này chưa
      if (tempReplies.containsKey(comment.id)) {
        // Nếu đã có thì không thêm nữa
        return;
      } else {
        // Nếu chưa có, thêm reply tạm thời vào map
        tempReplies[comment.id] = CommentModel(
          id: 'temp_reply',
          userName: '',
          avatarUrl: 'https://i.pravatar.cc/150?img=1',
          content: '',
          timestamp: DateTime.now(),
        );
      }
    });
  }

  void _addReply(CommentModel parentComment) {
    setState(() {
      // Kiểm tra xem reply tạm thời có tồn tại không
      if (tempReplies.containsKey(parentComment.id)) {
        CommentModel reply = tempReplies[parentComment.id]!;

        // Thêm bình luận vào replies của parentComment
        parentComment.replies.add(
          CommentModel(
            id: 'reply_${parentComment.id}_${parentComment.replies.length}',
            userName: 'User Reply',
            avatarUrl: 'https://i.pravatar.cc/150?img=2',
            content: reply.content,
            // Nội dung người dùng đã nhập
            timestamp: DateTime.now(),
          ),
        );

        // Sau khi gửi, xóa reply tạm thời khỏi map
        tempReplies.remove(parentComment.id);
      }
    });
  }

  void _cancelReply(CommentModel parentComment) {
    setState(() {
      // Xóa reply tạm thời nếu người dùng hủy
      tempReplies.remove(parentComment.id);
    });
  }

  void _editComment(CommentModel comment) {
    showDialog(
      context: context,
      builder: (_) {
        TextEditingController controller = TextEditingController(
          text: comment.content,
        );
        return AlertDialog(
          title: Text('Sửa bình luận'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Nhập bình luận mới'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  comment.originalContent = comment.content;
                  comment.content = controller.text;
                  comment.edited = true;
                });
                Navigator.pop(context);
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: displayedComments.length + 1, // Thêm 1 cho ô nhập liệu
      itemBuilder: (context, index) {
        // Ô nhập liệu luôn hiển thị ở đầu
        if (index == 0) {
          return _buildNewCommentInput(); // Ô nhập liệu
        }

        final comment =
            displayedComments[index - 1]; // Lấy bình luận sau ô nhập liệu

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommentTile(comment), // Hiển thị bình luận
            if (comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Column(
                  children: comment.replies.map(_buildCommentTile).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  // Widget để hiển thị ô nhập liệu mới
  Widget _buildNewCommentInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Căn trái cho tên người dùng và ô nhập liệu
        children: [
          // Tên người đăng nhập
          Padding(
            padding: const EdgeInsets.only(left: 58.0, bottom: 8.0, top: 4.0),
            child: Text(
              'ZimJi', // Tên người đăng nhập (có thể lấy từ user profile)
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          // Row chứa avatar và ô nhập liệu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Đảm bảo căn chỉnh avatar và input cùng hàng
            children: [
              // Avatar của người dùng (tăng kích thước avatar)
              CircleAvatar(
                backgroundImage: NetworkImage(''),
                // Thêm URL avatar của người dùng
                radius: 24, // Tăng kích thước avatar (đặt radius lớn hơn)
              ),
              const SizedBox(width: 8),
              // Expanded để TextField chiếm hết không gian còn lại
              Expanded(
                child: SizedBox(
                  height: 80, // Đặt chiều cao cho TextField (giống TextArea)
                  child: TextField(
                    onChanged: (text) {
                      // Cập nhật nội dung bình luận
                      setState(() {
                        // Cập nhật bình luận mới
                      });
                    },
                    maxLines: 5, // Để TextField có thể mở rộng lên tới 5 dòng
                    minLines: 3, // Đảm bảo chiều cao tối thiểu
                    decoration: InputDecoration(
                      hintText: "Viết bình luận...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Row chứa nút gửi và hủy, căn phải
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            // Giảm khoảng cách giữa ô nhập liệu và nút
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              // Căn các nút về phía bên phải
              children: [
                TextButton(
                  onPressed: () {
                    // Gửi bình luận
                  },
                  child: const Text("Gửi"),
                ),
                const SizedBox(width: 8),
                // Khoảng cách nhỏ giữa "Gửi" và "Nhập lại"
                TextButton(
                  onPressed: () {
                    // Hủy bình luận
                  },
                  child: const Text("Nhập lại"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(CommentModel comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CircleAvatar
          CircleAvatar(
            backgroundImage: NetworkImage(comment.avatarUrl),
            radius: 24, // Điều chỉnh kích thước để đảm bảo CircleAvatar lớn hơn
          ),
          const SizedBox(width: 8),
          // Expanded để Container và CircleAvatar có kích thước đều nhau
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(comment.content),
                      if (comment.edited)
                        Text(
                          '(Đã chỉnh sửa)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onLongPress: () => _showReactionMenu(comment, context),
                      child: TextButton.icon(
                        onPressed:
                            () => _setReaction(comment, ReactionType.like),
                        icon: Icon(getReactionIcon(comment.userReaction)),
                        label: Text(getReactionText(comment.userReaction)),
                        style: TextButton.styleFrom(
                          foregroundColor: getReactionColor(
                            comment.userReaction,
                          ), // Lấy màu sắc từ reaction
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _toggleReplyBox(comment),
                      child: const Text(
                        "Trả lời",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _editComment(comment),
                      child: const Text("Sửa", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                // Nếu có reply (trả lời), hiển thị TextField và nút hủy
                if (tempReplies.containsKey(comment.id))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Căn trái cho toàn bộ Column
                    children: [
                      // Tên người đăng nhập (hiển thị trên đầu ô nhập liệu)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 46.0,
                          bottom: 6.0,
                          top: 10.0,
                        ),
                        // Thêm khoảng cách từ trên cho tên người đăng nhập
                        child: Text(
                          'ZimJi', // Tên người đăng nhập
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // Row chứa avatar và TextField để nhập phản hồi
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        // Căn giữa để Avatar và TextField đều căn chỉnh đúng
                        children: [
                          // Avatar của người đăng nhập
                          CircleAvatar(
                            backgroundImage: NetworkImage(''),
                            // Avatar người đăng nhập
                            radius: 18, // Đặt radius phù hợp
                          ),
                          const SizedBox(width: 8),
                          // Expanded để TextField chiếm hết không gian còn lại
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              // Đảm bảo chiều cao của container để nó ngang bằng với avatar
                              child: TextField(
                                onChanged: (text) {
                                  setState(() {
                                    // Cập nhật nội dung tạm thời vào tempReplies
                                    tempReplies[comment.id]?.content = text;
                                  });
                                },
                                controller: TextEditingController(
                                  text: tempReplies[comment.id]?.content ?? '',
                                ),
                                decoration: InputDecoration(
                                  hintText: "Viết phản hồi...",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Row chứa các nút "Gửi" và "Hủy" căn phải
                      Row(
                        children: [
                          Spacer(), // Spacer giúp đẩy các nút về phía bên phải
                          TextButton(
                            onPressed: () {
                              if (tempReplies[comment.id]?.content.isNotEmpty ??
                                  false) {
                                _addReply(comment); // Gửi reply khi bấm "Gửi"
                              }
                            },
                            child: const Text("Gửi"),
                          ),
                          TextButton(
                            onPressed: () => _cancelReply(comment), // Hủy reply
                            child: const Text("Hủy"),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm lấy icon reaction tương ứng
  IconData getReactionIcon(ReactionType? reaction) {
    switch (reaction) {
      case ReactionType.love:
        return Icons.favorite;
      case ReactionType.haha:
        return Icons.emoji_emotions;
      case ReactionType.wow:
        return Icons.emoji_objects;
      case ReactionType.sad:
        return Icons.sentiment_dissatisfied;
      case ReactionType.angry:
        return Icons.emoji_flags;
      default:
        return Icons.thumb_up;
    }
  }

  // Hàm lấy màu cho reaction
  Color getReactionColor(ReactionType? reaction) {
    switch (reaction) {
      case ReactionType.like:
        return Colors.blue;
      case ReactionType.love:
        return Colors.red;
      case ReactionType.wow:
        return Colors.amber;
      case ReactionType.haha:
        return Colors.yellow;
      case ReactionType.sad:
        return Colors.blueGrey;
      case ReactionType.angry:
        return Colors.redAccent;
      default:
        return Colors.white60;
    }
  }

  // Hàm lấy text cho reaction
  String getReactionText(ReactionType? reaction) {
    switch (reaction) {
      case ReactionType.love:
        return "Yêu thích";
      case ReactionType.haha:
        return "Haha";
      case ReactionType.wow:
        return "Wow";
      case ReactionType.sad:
        return "Buồn";
      case ReactionType.angry:
        return "Phẫn nộ";
      default:
        return "Thích";
    }
  }
}
