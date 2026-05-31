import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/record.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> with WidgetsBindingObserver {
  List<Record> _records = [];
  bool _loading = true;
  String _filter = '全部';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecords();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRecords();
    }
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
    if (_filter == '收入') return _records.where((r) => r.type == RecordType.income).toList();
    if (_filter == '支出') return _records.where((r) => r.type == RecordType.expense).toList();
    return _records;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('记录'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: ['全部', '收入', '支出'].map((f) => GestureDetector(
          onTap: () => setState(() => _filter = f),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _filter == f ? Colors.deepPurple : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(f, style: TextStyle(color: _filter == f ? Colors.white : Colors.grey.shade700)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return const Center(child: Text('暂无记录', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final r = _filtered[index];
          return _buildRecordItem(r);
        },
      ),
    );
  }

  Widget _buildRecordItem(Record r) {
    final isIncome = r.type == RecordType.income;
    final iconMap = {'餐饮': '🍜', '交通':'🚗', '购物': '🛒', '工资': '💰', '奖金': '🎁', '投资': '📈', '房租': '🏠', '娱乐': '🎮', '医疗': '💊', '通讯': '📱', '红包': '🧧', '其他':'📝'};
    return Dismissible(
      key: Key(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
        child: const Text('删除', style: TextStyle(color: Colors.white)),
      ),
      onDismissed: (_) => _deleteRecord(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(iconMap[r.category] ?? '📝', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.category, style: const TextStyle(fontWeight: FontWeight.w500)),
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
  }
}