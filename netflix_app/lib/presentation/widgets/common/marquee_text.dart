import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double velocity; // Tốc độ cuộn

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.velocity = 80.0, // Tốc độ cuộn mặc định
  });

  @override
  MarqueeTextState createState() => MarqueeTextState();
}

class MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _textWidth = 0;
  late double _totalWidth;

  @override
  void initState() {
    super.initState();

    _initAnimation();
  }

  // Tính toán chiều rộng của văn bản
  void _initAnimation() {
    _textWidth = _getTextWidth(widget.text, widget.style);

    // Tổng chiều rộng của cả hai đoạn văn bản (văn bản chính và bản sao)
    _totalWidth = _textWidth * 2;

    // Tính toán thời gian cuộn, chia cho velocity để đảm bảo tốc độ mượt mà
    double durationInSeconds = _totalWidth / widget.velocity;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: durationInSeconds.round()),
    )..repeat(); // Lặp lại animation

    // Animation sẽ chạy từ 0 đến chiều rộng của cả hai văn bản (để cuộn liên tục)
    _animation = Tween<double>(
      begin: 0.0,
      end: -_textWidth,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  double _getTextWidth(String text, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra nếu _controller chưa được khởi tạo thì không vẽ widget
    if (!_controller.isAnimating) {
      return Container(); // Hoặc một widget nào đó như "loading spinner"
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 5,
      color: Colors.black87,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.movie, // Biểu tượng phim
              color: Colors.white,
              size: 30, // Biểu tượng lớn
            ),
            SizedBox(width: 15), // Khoảng cách giữa biểu tượng và chữ
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      children: [
                        // Đoạn văn bản đầu tiên
                        Transform.translate(
                          offset: Offset(_animation.value, 0),
                          child: Text(widget.text, style: widget.style),
                        ),
                        // Đoạn văn bản thứ hai (bản sao của đoạn văn bản đầu tiên)
                        Transform.translate(
                          offset: Offset(_animation.value + 5, 0),
                          child: Text(widget.text, style: widget.style),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
