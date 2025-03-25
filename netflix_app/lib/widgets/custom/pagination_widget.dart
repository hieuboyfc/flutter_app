import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  PaginationWidget({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (currentPage > 1)
            _buildPageButton(Icons.chevron_left, currentPage - 1),
          for (int i = 1; i <= totalPages; i++)
            if (i == 1 ||
                i == totalPages ||
                (i >= currentPage - 1 && i <= currentPage + 1))
              _buildPageButton(null, i, isSelected: i == currentPage),
          if (currentPage < totalPages)
            _buildPageButton(Icons.chevron_right, currentPage + 1),
          if (totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                "$currentPage / $totalPages",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageButton(IconData? icon, int page, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          onPageChanged(page);
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isSelected ? Colors.red : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child:
              icon != null
                  ? Icon(icon, color: Colors.white, size: 20)
                  : Text(
                    "$page",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
        ),
      ),
    );
  }
}
