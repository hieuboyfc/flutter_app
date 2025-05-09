class CategoryModel {
  final int id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(id: json['id'] ?? 0, name: json['name'] ?? 'Unknown');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
