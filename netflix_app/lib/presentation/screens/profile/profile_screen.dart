import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hồ sơ cá nhân"), backgroundColor: Colors.black),
      body: Center(
        child: const Text("Thông tin hồ sơ đang cập nhật...", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
