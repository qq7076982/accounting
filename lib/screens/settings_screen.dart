import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'sms_import_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _quoteKey = 'motivational_quote';
  static const String _quoteEnabledKey = 'quote_enabled';
  static const String _defaultQuote = '理财不是一夜暴富，而是让财富慢慢增值';

  String _quote = _defaultQuote;
  bool _quoteEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _quote = prefs.getString(_quoteKey) ?? _defaultQuote;
      _quoteEnabled = (prefs.getString(_quoteEnabledKey) ?? 'true') == 'true';
    });
  }

  Future<void> _saveQuote(String quote) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quoteKey, quote);
    setState(() => _quote = quote);
  }

  Future<void> _toggleQuote(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quoteEnabledKey, enabled.toString());
    setState(() => _quoteEnabled = enabled);
  }

  Future<void> _editQuote() async {
    final controller = TextEditingController(text: _quote);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改励志语'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(hintText: '输入理财励志语...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _saveQuote(result);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('修改成功')));
    }
  }

  Future<void> _openDownloadPage() async {
    const url = 'https://github.com/qq7076982/accounting/releases';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开链接，请手动访问 GitHub')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('理财励志语', [
            _buildSwitchTile(
              icon: '💬',
              title: '显示励志语',
              subtitle: '首页余额上方显示',
              value: _quoteEnabled,
              onChanged: _toggleQuote,
            ),
            _buildListTile(
              icon: '✏️',
              title: '修改励志语',
              subtitle: _quote,
              onTap: _editQuote,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('短信导入', [
            _buildListTile(
              icon: '📨',
              title: '从短信导入',
              subtitle: '粘贴银行短信批量导入记录',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SmsImportScreen()));
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('版本更新', [
            _buildListTile(
              icon: '📦',
              title: '检查更新',
              subtitle: '点击查看最新版本',
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: _openDownloadPage,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('关于', [
            _buildListTile(
              icon: 'ℹ️',
              title: '记账本',
              subtitle: '版本 1.0.0',
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF667EEA)),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 20)),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}