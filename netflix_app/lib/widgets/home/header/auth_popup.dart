import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';

class AuthPopup extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String username) onLoginSuccess;

  const AuthPopup({super.key, required this.onClose, required this.onLoginSuccess});

  @override
  _AuthPopupState createState() => _AuthPopupState();
}

class _AuthPopupState extends State<AuthPopup> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  String errorMessage = '';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      String username = usernameController.text.trim();
      String password = passwordController.text.trim();
      String result;

      if (isLogin) {
        result = await AuthService.login(username, password);
      } else {
        String confirmPassword = confirmPasswordController.text.trim();
        if (password != confirmPassword) {
          setState(() {
            errorMessage = "Mật khẩu không khớp!";
            isLoading = false;
          });
          return;
        }
        result = await AuthService.register(username, password);
      }

      if (result == "Đăng nhập thành công!" || result == "Đăng ký thành công!") {
        await AuthService.saveLoggedInUser(username);
        widget.onLoginSuccess(username);

        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onClose();
        });
      } else {
        setState(() {
          errorMessage = result;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (!isLoading) {
                _animationController.reverse().then((_) => widget.onClose());
              }
            },
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ),
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                width: 320,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút X để đóng popup
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: isLoading ? null : widget.onClose,
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                      ),

                      Text(
                        isLogin ? "Đăng nhập" : "Đăng ký",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(labelText: "Tên đăng nhập"),
                        validator: (value) => value!.isEmpty ? "Vui lòng nhập tên đăng nhập" : null,
                      ),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "Mật khẩu"),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Vui lòng nhập mật khẩu";
                          if (value.length < 6) return "Mật khẩu phải có ít nhất 6 ký tự";
                          return null;
                        },
                      ),
                      if (!isLogin)
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: "Xác nhận mật khẩu"),
                          validator:
                              (value) =>
                                  value != passwordController.text ? "Mật khẩu không khớp" : null,
                        ),
                      const SizedBox(height: 10),
                      if (errorMessage.isNotEmpty)
                        Text(errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: isLoading ? null : _handleAuth,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.redAccent, Colors.red],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child:
                                isLoading
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      isLogin ? "Đăng nhập" : "Đăng ký",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  setState(() {
                                    isLogin = !isLogin;
                                    errorMessage = "";
                                  });
                                },
                        child: Text(
                          isLogin
                              ? "Chưa có tài khoản? Đăng ký ngay"
                              : "Đã có tài khoản? Đăng nhập",
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
