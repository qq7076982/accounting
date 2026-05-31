import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/record.dart';

class EditRecordScreen extends StatefulWidget {
  final Record record;
  const EditRecordScreen({super.key, required this.record});
  @override
  State<EditRecordScreen> createState() => _EditRecordScreenState();
}

class _EditRecordScreenState extends State<EditRecordScreen> {
  late RecordType _type;
  late String _category;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _type = widget.record.type;
    _category = widget.record.category;
    _amountController = TextEditingController(text: widget.record.amount.toString());
    _noteController = TextEditingController(text: widget.record.note);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _type == RecordType.income ? incomeCategories : expenseCategories;

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }

    final updated = Record(
      id: widget.record.id,
      amount: amount,
      type: _type,
      category: _category,
      note: _noteController.text.trim(),
      date: widget.record.date,
    );

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('records');
    if (data != null) {
      List<Record> records = (json.decode(data) as List).map((e) => Record.fromJson(e)).toList();
      final idx = records.indexWhere((r) => r.id == widget.record.id);
      if (idx >= 0) records[idx] = updated;
      await prefs.setString('records', json.encode(records.map((r) => r.toJson()).toList()));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('修改成功')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
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

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('records');
      if (data != null) {
        List<Record> records = (json.decode(data) as List).map((e) => Record.fromJson(e)).toList();
        records.removeWhere((r) => r.id == widget.record.id);
        await prefs.setString('records', json.encode(records.map((r) => r.toJson()).toList()));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('编辑记录'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildCategoryGrid(),
            const SizedBox(height: 20),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildNoteField(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(child: _buildTypeButton('支出', RecordType.expense, Colors.red)),
          Expanded(child: _buildTypeButton('收入', RecordType.income, Colors.green)),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, RecordType type, Color color) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() {
        _type = type;
        _category = _categories.first;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('类别', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) => _buildCategoryChip(c)).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    final iconMap = {'餐饮': '🍜', '交通':'🚗', '购物': '🛒', '工资': '💰', '奖金': '🎁', '投资': '📈', '房租': '🏠', '娱乐': '🎮', '医疗': '💊', '通讯': '📱', '红包': '🧧','其他':'📝'};
    final selected = _category == category;
    return GestureDetector(
      onTap: () => setState(() => _category = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (_type == RecordType.income ? Colors.green : Colors.red) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(iconMap[category] ?? '📝'),
            const SizedBox(width: 6),
            Text(category, style: TextStyle(color: selected ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('金额', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('¥', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(hintText: '0.00', border: InputBorder.none),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('备注', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: '添加备注...', border: InputBorder.none),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _type == RecordType.income ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('保存修改', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}