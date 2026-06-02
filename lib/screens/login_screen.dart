import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final auth = context.read<AuthService>();
      if (_isRegisterMode) {
        await auth.register(username, password);
        setState(() => _isRegisterMode = false);
        _showSnack('Account created! Please log in.');
      } else {
        await auth.login(username, password);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      String errorMsg;
      if (e is DioException) {
        if (e.response != null) {
          final detail = e.response?.data['detail']?.toString() ?? '';
          if (detail.contains('Invalid username or password')) {
            errorMsg = 'Invalid username or password.';
          } else if (detail.contains('already taken')) {
            errorMsg = 'Username already taken.';
          } else if (detail.isNotEmpty) {
            errorMsg = detail;
          } else {
            errorMsg = 'Server error: ${e.response?.statusCode}';
          }
        } else {
          errorMsg = 'Network error: ${e.type} — ${e.message}';
        }
      } else {
        errorMsg = 'Unexpected error: ${e.toString()}';
      }
      setState(() => _errorMessage = errorMsg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

String _parseError(dynamic e) {
  String msg = e.toString();
  try {
    if (e.runtimeType.toString().contains('Dio')) {
      final response = (e as dynamic).response;
      if (response != null) {
        final detail = response.data['detail']?.toString() ?? '';
        msg = detail;
      }
    }
  } catch (_) {}
  
  if (msg.contains('Invalid username or password')) return 'Invalid username or password.';
  if (msg.contains('already taken')) return 'Username already taken.';
  if (msg.contains('at least 6')) return 'Password must be at least 6 characters.';
  if (msg.contains('Connection') || msg.contains('SocketException') || msg.contains('connect')) 
    return 'Cannot connect to GRAYVAULT server. Is it running?';
  if (msg.isEmpty) return msg.isEmpty ? 'Something went wrong.' : msg;
  return msg;
}

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1D9E75),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Logo ────────────────────────────────────────────────
                Center(
                  child: Image.asset(
                    'assets/images/grayvault.png',
                    width: size.width * 0.42,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Greeting ─────────────────────────────────────────────
                Text(
                  _isRegisterMode ? 'Create your vault.' : 'Welcome back.',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRegisterMode
                      ? 'Set up your account to get started.'
                      : 'Log in to access your vault.',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 36),

                // ── Username ──────────────────────────────────────────────
                _buildLabel('Username'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _usernameController,
                  hint: 'jaywalker_joel',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),

                // ── Password ──────────────────────────────────────────────
                _buildLabel('Password'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _passwordController,
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF555555),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Error ─────────────────────────────────────────────────
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Color(0xFFD85A30), fontSize: 13),
                    ),
                  ),

                // ── Submit ────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _isRegisterMode ? 'Create Account' : 'Login',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Toggle ────────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isRegisterMode = !_isRegisterMode;
                      _errorMessage = null;
                    }),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF888888)),
                        children: [
                          TextSpan(
                            text: _isRegisterMode
                                ? 'Already have an account? '
                                : "Don't have an account? ",
                          ),
                          TextSpan(
                            text: _isRegisterMode ? 'Login' : 'Register',
                            style: const TextStyle(
                              color: Color(0xFF1D9E75),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Jaywalker Inc. brand mark ─────────────────────────────
                const SizedBox(height: 48),
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Jaywalker Inc.',
                    style: TextStyle(
                      color: Color(0xFF2A2A2A),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888888),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF444444)),
        prefixIcon: Icon(icon, color: const Color(0xFF555555), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
