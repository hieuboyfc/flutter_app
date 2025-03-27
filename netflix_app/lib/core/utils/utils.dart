String getTitleFromKey(String keyTitle) {
  switch (keyTitle) {
    case "movies_by_day":
      return "📅 Phim Theo Ngày";
    case "hot_movies":
      return "🔥 Phim Hot";
    case "new_movies":
      return "🎬 Phim Mới";
    case "saved_movies":
      return "💾 Phim Đã Lưu";
    default:
      return "Danh Sách Phim";
  }
}

List<String> weekDays = [
  "Thứ 2",
  "Thứ 3",
  "Thứ 4",
  "Thứ 5",
  "Thứ 6",
  "Thứ 7",
  "Chủ nhật",
];
