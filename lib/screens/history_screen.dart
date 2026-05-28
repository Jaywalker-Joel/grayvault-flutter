import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _transactions = [];
  bool _loading = true;
  String? _activeFilter;

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'value': null},
    {'label': 'Income', 'value': 'income'},
    {'label': 'Expense', 'value': 'expense'},
    {'label': 'Transfer', 'value': 'transfer'},
    {'label': 'Locks', 'value': 'escrow_lock'},
    {'label': 'Releases', 'value': 'escrow_release'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final api = context.read<AuthService>().api;
      final data = await api.getTransactions(type: _activeFilter);
      setState(() { _transactions = data['transactions'] ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'income': return const Color(0xFF1D9E75);
      case 'expense': return const Color(0xFFD85A30);
      case 'transfer': return const Color(0xFF378ADD);
      case 'escrow_lock': return const Color(0xFFAA88FF);
      case 'escrow_release': return const Color(0xFF9FE1CB);
      default: return const Color(0xFF888888);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'income': return Icons.arrow_downward;
      case 'expense': return Icons.arrow_upward;
      case 'transfer': return Icons.swap_horiz;
      case 'escrow_lock': return Icons.lock_outline;
      case 'escrow_release': return Icons.lock_open_outlined;
      default: return Icons.circle_outlined;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'income': return 'Income';
      case 'expense': return 'Expense';
      case 'transfer': return 'Transfer';
      case 'escrow_lock': return 'Locked';
      case 'escrow_release': return 'Released';
      default: return type;
    }
  }

  String _sign(String type) {
    return ['income', 'escrow_release'].contains(type) ? '+' : '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (_, i) {
                final f = _filters[i];
                final selected = _activeFilter == f['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeFilter = f['value'];
                      _loading = true;
                    });
                    _loadTransactions();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1D9E75).withOpacity(0.15)
                          : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1D9E75)
                            : const Color(0xFF2A2A2A),
                      ),
                    ),
                    child: Text(
                      f['label'],
                      style: TextStyle(
                        color: selected ? const Color(0xFF1D9E75) : const Color(0xFF888888),
                        fontSize: 12, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Transaction list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              color: const Color(0xFF1D9E75),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D9E75)))
                  : _transactions.isEmpty
                      ? const Center(
                          child: Text('No transactions found',
                              style: TextStyle(color: Color(0xFF555555))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _transactions.length,
                          itemBuilder: (_, i) => _buildTxItem(_transactions[i]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxItem(Map<String, dynamic> tx) {
    final type = tx['type'] ?? '';
    final color = _typeColor(type);
    final amount = (tx['amount'] ?? 0).toDouble();
    final sign = _sign(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon(type), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['description']?.isNotEmpty == true
                      ? tx['description']
                      : _typeLabel(type),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx['category'] ?? ''} • ${tx['created_at'] ?? ''}',
                  style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign GHS ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'GHS ${(tx['balance_after'] ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF444444), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
