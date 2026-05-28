import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = context.read<AuthService>().api;
      final summary = await api.getSummary();
      setState(() { _summary = summary; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _fmt(double amount) =>
      'GHS ${NumberFormat('#,##0.00').format(amount)}';

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionTile(Icons.arrow_downward, 'Receive', const Color(0xFF1D9E75),
                () { Navigator.pop(context); _showTransactionDialog('income'); }),
            const SizedBox(height: 12),
            _actionTile(Icons.arrow_upward, 'Send / Expense', const Color(0xFFD85A30),
                () { Navigator.pop(context); _showTransactionDialog('expense'); }),
            const SizedBox(height: 12),
            _actionTile(Icons.swap_horiz, 'Transfer', const Color(0xFF378ADD),
                () { Navigator.pop(context); _showTransactionDialog('transfer'); }),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showTransactionDialog(String type) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          type == 'income' ? 'Receive Funds' :
          type == 'expense' ? 'Log Expense' : 'Transfer',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(amountCtrl, 'Amount (GHS)', TextInputType.number),
            const SizedBox(height: 12),
            if (type != 'transfer')
              _dialogField(categoryCtrl, 'Category (e.g. Food, Salary)'),
            if (type != 'transfer') const SizedBox(height: 12),
            _dialogField(descCtrl, 'Description'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75), foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              try {
                final api = context.read<AuthService>().api;
                if (type == 'income') {
                  await api.logIncome(amount, categoryCtrl.text.isEmpty ? 'General' : categoryCtrl.text, descCtrl.text);
                } else if (type == 'expense') {
                  await api.logExpense(amount, categoryCtrl.text.isEmpty ? 'General' : categoryCtrl.text, descCtrl.text);
                } else {
                  await api.logTransfer(amount, descCtrl.text);
                }
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}'),
                        backgroundColor: const Color(0xFFD85A30)),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint,
      [TextInputType type = TextInputType.text]) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      floatingActionButton: FloatingActionButton(
        onPressed: _showActionSheet,
        backgroundColor: const Color(0xFF1D9E75),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF1D9E75),
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Balance card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF085041),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Balance',
                          style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        _fmt((_summary?['balance'] ?? 0).toDouble()),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Mobile Money Wallet',
                          style: TextStyle(color: Color(0xFF9FE1CB), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _showActionSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF2A2A2A)),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Transaction'),
                  ),
                ),
                const SizedBox(height: 24),

                // Summary stats
                const Text('Summary',
                    style: TextStyle(color: Color(0xFF888888),
                        fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statCard('Total In',
                        (_summary?['total_income'] ?? 0).toDouble(), const Color(0xFF1D9E75))),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('Total Out',
                        (_summary?['total_expenses'] ?? 0).toDouble(), const Color(0xFFD85A30))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _statCard('Locked',
                        (_summary?['total_locked'] ?? 0).toDouble(), const Color(0xFF378ADD))),
                    const SizedBox(width: 10),
                    Expanded(child: _statCard('Released',
                        (_summary?['total_released'] ?? 0).toDouble(), const Color(0xFF888888))),
                  ],
                ),
              ],
            ),
      ),
    );
  }

  Widget _statCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
          const SizedBox(height: 6),
          Text(_fmt(amount),
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
