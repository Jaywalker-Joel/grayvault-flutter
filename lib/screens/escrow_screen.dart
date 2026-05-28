import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class EscrowScreen extends StatefulWidget {
  const EscrowScreen({super.key});

  @override
  State<EscrowScreen> createState() => _EscrowScreenState();
}

class _EscrowScreenState extends State<EscrowScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _locks = [];
  bool _loading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // ── Design tokens (match wallet_screen exactly) ──────────────────────────
  static const _bg        = Color(0xFF111111);
  static const _card      = Color(0xFF1A1A1A);
  static const _sheet     = Color(0xFF1E1E1E);
  static const _border    = Color(0xFF2A2A2A);
  static const _input     = Color(0xFF2A2A2A);
  static const _muted     = Color(0xFF888888);
  static const _dimmed    = Color(0xFF555555);
  static const _ghost     = Color(0xFF333333);
  static const _green     = Color(0xFF1D9E75);
  static const _greenDark = Color(0xFF085041);
  static const _greenSoft = Color(0xFF9FE1CB);
  static const _blue      = Color(0xFF378ADD);
  static const _red       = Color(0xFFD85A30);
  static const _purple    = Color(0xFFAA88FF);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadLocks();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLocks() async {
    try {
      final api = context.read<AuthService>().api;
      final data = await api.getLocks();
      setState(() {
        _locks = data['locks'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _fmt(double amount) =>
      'GHS ${NumberFormat('#,##0.00').format(amount)}';

  double get _totalLocked => _locks.fold(
      0.0, (sum, l) => sum + ((l['amount'] ?? 0) as num).toDouble());

  int get _timeLocksCount =>
      _locks.where((l) => l['type'] == 'time').length;

  int get _goalLocksCount =>
      _locks.where((l) => l['type'] == 'goal').length;

  // ── Release lock ──────────────────────────────────────────────────────────
  Future<void> _releaseLock(dynamic lock) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Release Funds?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Release ${_fmt((lock['amount'] ?? 0).toDouble())} from "${lock['name']}"?',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Release'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = context.read<AuthService>().api;
      await api.releaseLock(lock['id']);
      _loadLocks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Funds released to wallet ✓'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ── Create lock bottom sheet ──────────────────────────────────────────────
  void _showCreateLockSheet() {
    String lockType = 'time';
    final nameCtrl    = TextEditingController();
    final amountCtrl  = TextEditingController();
    final daysCtrl    = TextEditingController();
    final targetCtrl  = TextEditingController();
    final reasonCtrl  = TextEditingController();
    bool submitting   = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_outline, color: _green, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Lock',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      Text('Commit funds to a goal or timeline',
                          style: TextStyle(color: _muted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lock type toggle
              Row(children: [
                _typeChip('⏱  Time-based', 'time', lockType,
                    () => setModal(() => lockType = 'time')),
                const SizedBox(width: 8),
                _typeChip('🎯  Goal-based', 'goal', lockType,
                    () => setModal(() => lockType = 'goal')),
              ]),
              const SizedBox(height: 20),

              _sheetField(nameCtrl, 'Lock name', 'e.g. Rent savings, Emergency fund'),
              const SizedBox(height: 14),
              _sheetField(amountCtrl, 'Amount (GHS)', 'e.g. 300.00',
                  TextInputType.number),
              const SizedBox(height: 14),

              if (lockType == 'time') ...[
                _sheetField(daysCtrl, 'Lock duration (days)',
                    'e.g. 7 for one week', TextInputType.number),
                const SizedBox(height: 14),
              ],
              if (lockType == 'goal') ...[
                _sheetField(targetCtrl, 'Savings target (GHS)',
                    'e.g. 800.00 — your goal amount', TextInputType.number),
                const SizedBox(height: 14),
              ],

              _sheetField(reasonCtrl, 'Reason (optional)',
                  'Why are you locking this?'),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: submitting
                      ? null
                      : () async {
                          final name   = nameCtrl.text.trim();
                          final amount = double.tryParse(amountCtrl.text) ?? 0;
                          if (name.isEmpty || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Name and amount are required'),
                                backgroundColor: _red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            return;
                          }
                          setModal(() => submitting = true);
                          try {
                            final api = context.read<AuthService>().api;
                            if (lockType == 'time') {
                              final days = int.tryParse(daysCtrl.text) ?? 7;
                              await api.createTimeLock(
                                  name, amount, days, reasonCtrl.text);
                            } else {
                              final target =
                                  double.tryParse(targetCtrl.text) ?? amount;
                              await api.createGoalLock(
                                  name, amount, target, reasonCtrl.text);
                            }
                            if (mounted) Navigator.pop(context);
                            _loadLocks();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Lock created ✓'),
                                  backgroundColor: _green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          } catch (e) {
                            setModal(() => submitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: _red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Create Lock',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value, String current, VoidCallback onTap) {
    final selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? _green.withOpacity(0.12) : _input,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _green : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? _green : _muted,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label, String hint,
      [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _muted, fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 0.4)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 13),
            filled: true,
            fillColor: _input,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateLockSheet,
        backgroundColor: _green,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLocks,
        color: _green,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _green))
            : _locks.isEmpty
                ? _buildEmptyState()
                : _buildContent(),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated vault icon
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: _ghost,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border, width: 1.5),
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: Color(0xFF444444), size: 40),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('No active locks',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Lock funds to build discipline\nand reach your goals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _muted, fontSize: 13, height: 1.5)),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _showCreateLockSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.lock_outline, size: 17),
                  label: const Text('Create your first lock',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 8),
        _buildStatsRow(),
        const SizedBox(height: 24),
        const Text('Active Locks',
            style: TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ..._locks.map((lock) => _buildLockCard(lock)),
        const SizedBox(height: 80), // FAB clearance
      ],
    );
  }

  // ── Summary hero card (mirrors wallet balance card) ───────────────────────
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _greenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Locked',
                  style: TextStyle(color: _greenSoft, fontSize: 13)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: _greenSoft, size: 12),
                    const SizedBox(width: 4),
                    Text('${_locks.length} lock${_locks.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: _greenSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(_totalLocked),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          const Text('Committed & protected',
              style: TextStyle(color: _greenSoft, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Time lock / Goal lock stat chips ─────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
              Icons.timer_outlined, '${_timeLocksCount} Time', _green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
              Icons.flag_outlined, '${_goalLocksCount} Goal', _blue),
        ),
      ],
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Lock card ─────────────────────────────────────────────────────────────
  Widget _buildLockCard(Map<String, dynamic> lock) {
    final isGoal    = lock['type'] == 'goal';
    final canRelease = lock['can_release'] == true;
    final amount    = (lock['amount'] ?? 0 as num).toDouble();

    final double progress = isGoal
        ? ((lock['goal_current'] ?? 0 as num).toDouble() /
                ((lock['goal_target'] ?? 1 as num).toDouble()))
            .clamp(0.0, 1.0)
        : 0.0;

    final int daysLeft = lock['days_remaining'] ?? 0;
    final Color accentColor = isGoal ? _blue : _green;
    final Color badgeBg = isGoal
        ? _blue.withOpacity(0.12)
        : _green.withOpacity(0.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canRelease ? _green.withOpacity(0.5) : _border,
          width: canRelease ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: icon + name + type badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        isGoal ? Icons.flag_outlined : Icons.timer_outlined,
                        color: accentColor,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lock['name'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          if ((lock['reason'] ?? '').toString().isNotEmpty)
                            Text(lock['reason'],
                                style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isGoal ? 'Goal' : 'Time',
                        style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Row 2: amount (large)
                Text(_fmt(amount),
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3)),
                const SizedBox(height: 12),

                // Row 3: progress / countdown
                if (isGoal) ...[
                  // Goal progress bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt((lock['goal_current'] ?? 0 as num).toDouble()),
                        style: const TextStyle(
                            color: _muted, fontSize: 11),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: _blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _fmt((lock['goal_target'] ?? 0 as num).toDouble()),
                        style: const TextStyle(
                            color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: _border,
                      color: _blue,
                      minHeight: 7,
                    ),
                  ),
                ] else ...[
                  // Countdown row
                  Row(
                    children: [
                      Icon(
                        canRelease
                            ? Icons.lock_open_outlined
                            : Icons.hourglass_empty_outlined,
                        color: canRelease ? _green : _muted,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        canRelease
                            ? 'Ready to release'
                            : '$daysLeft day${daysLeft == 1 ? '' : 's'} remaining',
                        style: TextStyle(
                            color: canRelease ? _green : _muted,
                            fontSize: 12,
                            fontWeight: canRelease
                                ? FontWeight.w600
                                : FontWeight.w400),
                      ),
                      if (!canRelease && daysLeft <= 3) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _purple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Soon',
                              style: TextStyle(
                                  color: _purple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Release button — full width, inset bottom stripe
          if (canRelease) ...[
            Container(height: 1, color: _border),
            InkWell(
              onTap: () => _releaseLock(lock),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A1F19),
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_open_outlined,
                        color: _green, size: 15),
                    SizedBox(width: 6),
                    Text('Release Funds',
                        style: TextStyle(
                            color: _green,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
