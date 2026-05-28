import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.131.92:8000';
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Attach token to every request automatically
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register(String username, String password) async {
    final res = await _dio.post('/auth/register', data: {
      'username': username,
      'password': password,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data;
  }

  // ── Wallet ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBalance() async {
    final res = await _dio.get('/wallet');
    return res.data;
  }

  Future<Map<String, dynamic>> getSummary() async {
    final res = await _dio.get('/wallet/summary');
    return res.data;
  }

  Future<Map<String, dynamic>> logIncome(
      double amount, String category, String description) async {
    final res = await _dio.post('/wallet/income', data: {
      'amount': amount,
      'category': category,
      'description': description,
      'reference': '',
    });
    return res.data;
  }

  Future<Map<String, dynamic>> logExpense(
      double amount, String category, String description) async {
    final res = await _dio.post('/wallet/expense', data: {
      'amount': amount,
      'category': category,
      'description': description,
      'reference': '',
    });
    return res.data;
  }

  Future<Map<String, dynamic>> logTransfer(
      double amount, String description) async {
    final res = await _dio.post('/wallet/transfer', data: {
      'amount': amount,
      'description': description,
      'reference': '',
    });
    return res.data;
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTransactions({int limit = 50, String? type}) async {
    final res = await _dio.get('/transactions', queryParameters: {
      'limit': limit,
      if (type != null) 'type': type,
    });
    return res.data;
  }

  // ── Escrow ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createTimeLock(
      String name, double amount, int days, String reason) async {
    final res = await _dio.post('/escrow/time-lock', data: {
      'name': name,
      'amount': amount,
      'days': days,
      'reason': reason,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> createGoalLock(
      String name, double amount, double target, String reason) async {
    final res = await _dio.post('/escrow/goal-lock', data: {
      'name': name,
      'amount': amount,
      'target': target,
      'reason': reason,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getLocks({String status = 'active'}) async {
    final res = await _dio.get('/escrow', queryParameters: {'status': status});
    return res.data;
  }

  Future<Map<String, dynamic>> checkLock(int lockId) async {
    final res = await _dio.get('/escrow/$lockId');
    return res.data;
  }

  Future<Map<String, dynamic>> releaseLock(int lockId, {bool force = false}) async {
    final res = await _dio.post('/escrow/$lockId/release', data: {'force': force});
    return res.data;
  }

  Future<Map<String, dynamic>> addToGoal(int lockId, double amount) async {
    final res = await _dio.post('/escrow/$lockId/add', data: {'amount': amount});
    return res.data;
  }

  // ── MoMo ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> momoReceive(
      double amount, String phone, String description) async {
    final res = await _dio.post('/momo/receive', data: {
      'amount': amount,
      'phone': phone,
      'description': description,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> momoSend(
      double amount, String phone, String description) async {
    final res = await _dio.post('/momo/send', data: {
      'amount': amount,
      'phone': phone,
      'description': description,
    });
    return res.data;
  }

  // ── Advisor ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> askAdvisor(String message, {bool onlineMode = false}) async {
    final res = await _dio.post('/advisor/chat', data: {
      'message': message,
      'online_mode': onlineMode,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getAdvisorAnalysis({bool onlineMode = false}) async {
    final res = await _dio.get('/advisor/analysis', queryParameters: {
      'online_mode': onlineMode,
    });
    return res.data;
  }
}