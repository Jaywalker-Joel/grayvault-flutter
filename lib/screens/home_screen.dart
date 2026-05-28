import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'wallet_screen.dart';
import 'escrow_screen.dart';
import 'history_screen.dart';
import 'advisor_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    WalletScreen(),
    EscrowScreen(),
    HistoryScreen(),
    AdvisorScreen(),
  ];

  // Watch auth state — if logged out, navigate to login
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthService>();
    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const LoginScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 350),
            ),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          'GRAYVAULT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D9E75),
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton(
              icon: const Icon(Icons.person_outline, color: Color(0xFF888888)),
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => <PopupMenuEntry>[
                PopupMenuItem(
                  enabled: false,
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D9E75).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person,
                            color: Color(0xFF1D9E75), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        auth.username ?? '',
                        style: const TextStyle(
                          color: Color(0xFF1D9E75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  onTap: () async {
                    await context.read<AuthService>().logout();
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Color(0xFFD85A30), size: 18),
                      SizedBox(width: 10),
                      Text('Logout',
                          style: TextStyle(color: Color(0xFFD85A30))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        indicatorColor: const Color(0xFF1D9E75).withOpacity(0.15),
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet,
                color: Color(0xFF1D9E75)),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock, color: Color(0xFF1D9E75)),
            label: 'Escrow',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon:
                Icon(Icons.receipt_long, color: Color(0xFF1D9E75)),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon:
                Icon(Icons.psychology, color: Color(0xFF1D9E75)),
            label: 'Advisor',
          ),
        ],
      ),
    );
  }
}
