import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'sms_import_screen.dart';

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
  bool _checkingUpdate = false;
  String? _updateStatus;

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

  Future<void> _checkUpdate() async {
    setState(() {
      _checkingUpdate = true;
      _updateStatus = null;
    });

    try {
      const tokenFile = '/Users/xie/Desktop/github_token.txt';
      final file = File(tokenFile);
      if (!await file.exists()) {
        setState(() => _updateStatus = 'Token文件不存在');
        return;
      }
      final token = (await file.readAsString()).trim();

      // Get latest run
      final runsRes = await http.get(
        Uri.parse('https://api.github.com/repos/qq7076982/accounting/actions/runs'),
        headers: {'Authorization': 'token $token', 'Accept': 'application/vnd.github.v3+json'},
      );
      if (runsRes.statusCode != 200) {
        setState(() => _updateStatus = '网络错误: ${runsRes.statusCode}');
        return;
      }

      final runsData = json.decode(runsRes.body);
      final latestRun = runsData['workflow_runs'][0];
      if (latestRun['conclusion'] != 'success') {
        setState(() => _updateStatus = '最新版本编译失败，请稍后重试');
        return;
      }

      // Get artifact
      final artifactRes = await http.get(
        Uri.parse('https://api.github.com/repos/qq7076982/accounting/actions/artifacts'),
        headers: {'Authorization': 'token $token', 'Accept': 'application/vnd.github.v3+json'},
      );
      if (artifactRes.statusCode != 200) {
        setState(() => _updateStatus = '获取下载链接失败');
        return;
      }

      final artifactData = json.decode(artifactRes.body);
      if (artifactData['total_count'] == 0) {
        setState(() => _updateStatus = '未找到APK文件');
        return;
      }

      final artifactId = artifactData['artifacts'][0]['id'];
      final downloadUrl = artifactData['artifacts'][0]['archive_url'];

      setState(() {
        _updateStatus = '有新版本！正在准备下载...';
      });

      // Download APK
      final downloadRes = await http.get(
        Uri.parse('https://api.github.com/repos/qq7076982/accounting/actions/artifacts/$artifactId/zip'),
        headers: {'Authorization': 'token $token', 'Accept': 'application/vnd.github.v3+json'},
      );

      if (downloadRes.statusCode == 302 || downloadRes.statusCode == 200) {
        final apkPath = '/tmp/accounting-update.apk';
        await File(apkPath).writeAsBytes(downloadRes.bodyBytes);

        setState(() {
          _updateStatus = '新版本APK已下载: $apkPath';
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('APK已下载，请到 /tmp 目录手动安装'),
          duration: const Duration(seconds: 5),
        ));
      } else {
        setState(() => _updateStatus = '下载失败: ${downloadRes.statusCode}');
      }
    } catch (e) {
      setState(() => _updateStatus = '检查更新失败: $e');
    } finally {
      setState(() => _checkingUpdate = false);
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
              icon:'💬',
              title: '显示励志语',
              subtitle: '首页余额上方显示',
              value: _quoteEnabled,
              onChanged: _toggleQuote,
            ),
            _buildListTile(
              icon:'✏️',
              title: '修改励志语',
              subtitle: _quote,
              onTap: _editQuote,
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('短信导入', [
            _buildListTile(
              icon:'📨',
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
              icon:'📦',
              title: '检查更新',
              subtitle: _checkingUpdate ? '检查中...' : (_updateStatus ?? '点击检查新版本'),
              trailing: _checkingUpdate
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: _checkingUpdate ? null : _checkUpdate,
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