import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/comment_model.dart';

class CommentService {

  Future<List<CommentModel>> loadComments() async {
    String jsonString = await rootBundle.loadString('assets/comments.json');
    final jsonData = json.decode(jsonString);

    List<CommentModel> comments = (jsonData['comments'] as List)
        .map((commentJson) => CommentModel.fromJson(commentJson))
        .toList();

    return comments;
  }

}
