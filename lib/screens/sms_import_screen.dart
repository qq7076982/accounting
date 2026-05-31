import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/record.dart';
import '../models/sms_parser.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});
  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final _controller = TextEditingController();
  List<Record> _parsedRecords = [];
  String? _error;
  bool _importing = false;

  void _parseSms() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '请输入短信内容');
      return;
    }

    final records = <Record>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final record = SmsParser.parse(trimmed);
      if (record != null) records.add(record);
    }

    setState(() {
      _parsedRecords = records;
      _error = records.isEmpty ? '未能识别任何记录，请检查短信格式' : null;
    });
  }

  Future<void> _importRecords() async {
    if (_parsedRecords.isEmpty) return;
    setState(() => _importing = true);

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('records');
    List<Record> existing = [];
    if (data != null) {
      existing = (json.decode(data) as List).map((e) => Record.fromJson(e)).toList();
    }

    existing.insertAll(0, _parsedRecords);
    await prefs.setString('records', json.encode(existing.map((r) => r.toJson()).toList()));

    setState(() => _importing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 ${_parsedRecords.length} 条记录')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('短信导入'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 使用说明', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    '将银行短信粘贴到下方，一次可以粘贴多条，每条一行',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '支持：邮储银行（支出/收入）',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                controller: _controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '粘贴短信内容...\n\n示例：\n【邮储银行】26年05月29日11:21您尾号8116账户快捷支付-支付宝，支出金额100.00元，余额83528.21元',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _parseSms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('解析短信'),
              ),
            ),
            if (_parsedRecords.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildParsedList(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _importing ? null : _importRecords,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _importing
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text('导入 ${_parsedRecords.length} 条记录', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParsedList() {
    final iconMap = {'餐饮': '🍜', '交通':'🚗', '购物': '🛒', '工资': '💰', '奖金': '🎁', '投资': '📈', '房租': '🏠', '娱乐': '🎮', '医疗': '💊', '通讯': '📱', '红包': '🧧','其他':'📝'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('解析结果（${_parsedRecords.length} 条）', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._parsedRecords.map((r) {
          final isIncome = r.type == RecordType.income;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Text(iconMap[r.category] ?? '📝', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.category, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      Text('${r.date.month}/${r.date.day} ${r.note}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}¥${r.amount.toStringAsFixed(2)}',
                  style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}