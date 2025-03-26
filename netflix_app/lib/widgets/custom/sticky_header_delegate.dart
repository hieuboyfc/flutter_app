import 'package:flutter/material.dart';

// Tạo Delegate cho SliverPersistentHeader
class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 5), // Điều chỉnh padding nếu cần
      child: Center(child: child), // Đảm bảo căn giữa nội dung
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
