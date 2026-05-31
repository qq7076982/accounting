import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/add_record_screen.dart';
import 'screens/sms_import_screen.dart';
import 'screens/settings_screen.dart';
import 'models/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const AccountingApp());
}

class AccountingApp extends StatelessWidget {
  const AccountingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF667EEA),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'PingFang SC',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecordScreen()));
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    } else {
      setState(() => _currentIndex = index > 4 ? index - 1 : index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildTab('首页', 0),
              _buildTab('记录', 1),
              _buildTab('统计', 2),
            ],
          ),
        ),
        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFF667EEA) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF667EEA) : Colors.grey,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _currentIndex,
      children: const [
        HomeScreen(),
        RecordsTabView(),
        StatsTabView(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomAction(Icons.receipt_long, '记一笔', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecordScreen()))),
              _buildBottomAction(Icons.upload_file, '短信导入', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsImportScreen()))),
              _buildBottomAction(Icons.settings, '设置', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF667EEA), size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF667EEA))),
        ],
      ),
    );
  }
}

// Records tab embedded view
class RecordsTabView extends StatefulWidget {
  const RecordsTabView({super.key});
  @override
  State<RecordsTabView> createState() => _RecordsTabViewState();
}

class _RecordsTabViewState extends State<RecordsTabView> {
  List<Record> _records = [];
  bool _loading = true;
  String _filter = '全部';
  String _dateFilter = '全部';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('records');
    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      setState(() {
        _records = jsonList.map((e) => Record.fromJson(e)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  List<Record> get _filtered {
    var list = _records;
    if (_filter == '收入') list = list.where((r) => r.type == RecordType.income).toList();
    if (_filter == '支出') list = list.where((r) => r.type == RecordType.expense).toList();
    final now = DateTime.now();
    if (_dateFilter == '本周') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      list = list.where((r) => r.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
    } else if (_dateFilter == '本月') {
      list = list.where((r) => r.date.year == now.year && r.date.month == now.month).toList();
    } else if (_dateFilter == '本年') {
      list = list.where((r) => r.date.year == now.year).toList();
    }
    return list;
  }

  Future<void> _deleteRecord(Record record) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('records');
    if (data != null) {
      List<Record> records = (json.decode(data) as List).map((e) => Record.fromJson(e)).toList();
      records.removeWhere((r) => r.id == record.id);
      await prefs.setString('records', json.encode(records.map((r) => r.toJson()).toList()));
      await _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['全部', '本周', '本月', '本年'].map((f) => GestureDetector(
                    onTap: () => setState(() => _dateFilter = f),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _dateFilter == f ? const Color(0xFF667EEA) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f, style: TextStyle(fontSize: 12, color: _dateFilter == f ? Colors.white : Colors.grey.shade700)),
                    ),
                  )).toList(),
                ),
              ),
              Row(
                children: ['全部', '收入', '支出'].map((f) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _filter == f ? const Color(0xFF667EEA) : Colors.transparent, width: 2)),
                      ),
                      child: Center(
                        child: Text(f, style: TextStyle(fontSize: 13, color: _filter == f ? const Color(0xFF667EEA) : Colors.grey)),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) return const Center(child: Text('暂无记录', style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final r = _filtered[index];
        final isIncome = r.type == RecordType.income;
        final iconMap = {'餐饮': '🍜', '交通':'🚗', '购物': '🛒', '工资': '💰', '奖金': '🎁', '投资': '📈', '房租': '🏠', '娱乐': '🎮', '医疗': '💊', '通讯': '📱', '红包': '🧧','其他':'📝'};
        return Dismissible(
          key: Key(r.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
          confirmDismiss: (_) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('删除确认'),
                content: const Text('确定删除这条记录吗？'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirmed == true) await _deleteRecord(r);
            return false;
          },
          onDismissed: (_) {},
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Text(iconMap[r.category] ?? '📝', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.category, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      Text('${r.date.month}/${r.date.day} ${r.note}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}¥${r.amount.toStringAsFixed(2)}',
                  style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Stats tab embedded view
class StatsTabView extends StatefulWidget {
  const StatsTabView({super.key});
  @override
  State<StatsTabView> createState() => _StatsTabViewState();
}

class _StatsTabViewState extends State<StatsTabView> {
  List<Record> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('records');
    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      setState(() {
        _records = jsonList.map((e) => Record.fromJson(e)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  double get _totalIncome => _records.where((r) => r.type == RecordType.income).fold(0.0, (s, r) => s + r.amount);
  double get _totalExpense => _records.where((r) => r.type == RecordType.expense).fold(0.0, (s, r) => s + r.amount);

  Map<String, double> get _expenseByCategory {
    final map = <String, double>{};
    for (final r in _records.where((r) => r.type == RecordType.expense)) {
      map[r.category] = (map[r.category] ?? 0) + r.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_records.isEmpty) return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildOverview(),
          const SizedBox(height: 16),
          _buildExpenseChart(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: Column(children: [
            const Text('总收入', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('¥${_totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ])),
          Container(width: 1, height: 36, color: Colors.white30),
          Expanded(child: Column(children: [
            const Text('总支出', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('¥${_totalExpense.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ])),
          Container(width: 1, height: 36, color: Colors.white30),
          Expanded(child: Column(children: [
            const Text('结余', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Text('¥${(_totalIncome - _totalExpense).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ])),
        ],
      ),
    );
  }

  Widget _buildExpenseChart() {
    final data = _expenseByCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = _totalExpense;
    final colorList = ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF', '#FF9F40', '#FF6384', '#C9CBCF'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('支出构成', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: data.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final pct = total > 0 ? item.value / total * 100 : 0.0;
              final color = Color(int.parse(colorList[idx % colorList.length].substring(1), radix: 16) + 0xFF000000);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.key)),
                      Text('¥${item.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: pct / 100, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}