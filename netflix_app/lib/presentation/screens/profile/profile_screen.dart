import 'package:flutter/material.dart';

import '../../screens/base/base_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      initialIndex: 3, // Profile sẽ là tab thứ 4
      showHeader: false,
      body: const Text(
        'Thông tin cá nhân',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ), // Nội dung của ProfileScreen
    );
  }
}
