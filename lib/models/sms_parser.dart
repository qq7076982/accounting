import '../models/record.dart';

class SmsParser {
  // 邮储银行解析 -宽松匹配
  // 支出：【邮储银行】26年05月29日11:21您尾号8116账户快捷支付-支付宝，支出金额100.00元，余额83528.21元
  // 收入：【邮储银行】26年05月27日13:02湖北空分工程科技有限公司账户6618向您尾号8116账户他行汇入，收入金额16246.07元，余额84696.59元

  static Record? parse(String sms) {
    if (!sms.contains('邮储银行')) return null;

    // 清理所有多余空格、换行
    final cleanSms = sms.replaceAll(RegExp(r'[\s\n\r]+'), '');

    final isExpense = cleanSms.contains('支出金额');
    final isIncome = cleanSms.contains('收入金额') && (cleanSms.contains('汇入') || cleanSms.contains('存入'));

    if (!isExpense && !isIncome) return null;

    // 金额 - 宽松匹配，支持各种写法
    // "支出金额100.00元" 或 "支出100.00元"
    double? amount;
    final amountPatterns = [
      RegExp(r'支出金额?(\d+\.?\d*)元'),
      RegExp(r'收入金额?(\d+\.?\d*)元'),
    ];

    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(cleanSms);
      if (match != null) {
        amount = double.tryParse(match.group(1) ?? '');
        break;
      }
    }

    if (amount == null || amount <= 0) return null;

    // 日期 - 支持 "26年05月29日11:21" 或 "2026年05月29日11:21"
    DateTime? date;
    final dateMatch = RegExp(r'(\d{2,4})年(\d{1,2})月(\d{1,2})日(\d{1,2}):(\d{2})').firstMatch(cleanSms);
    if (dateMatch != null) {
      var year = int.parse(dateMatch.group(1)!);
      if (year < 100) year += 2000; // "26年" -> 2026
      final month = int.parse(dateMatch.group(2)!);
      final day = int.parse(dateMatch.group(3)!);
      final hour = int.parse(dateMatch.group(4)!);
      final minute = int.parse(dateMatch.group(5)!);
      date = DateTime(year, month, day, hour, minute);
    }

    // 分类
    String category = '其他';
    if (cleanSms.contains('快捷支付') || cleanSms.contains('支付宝') || cleanSms.contains('微信支付') || cleanSms.contains('银联') || cleanSms.contains('云闪付')) {
      category = '购物';
    }
    if (cleanSms.contains('汇入') || cleanSms.contains('存入') || cleanSms.contains('转账存入')) {
      category = '工资';
    }
    if (cleanSms.contains('餐饮') || cleanSms.contains('超市') || cleanSms.contains('商城')) {
      category = '餐饮';
    }
    if (cleanSms.contains('交通') || cleanSms.contains('加油') || cleanSms.contains('停车')) {
      category = '交通';
    }
    if (cleanSms.contains('娱乐') || cleanSms.contains('影院') || cleanSms.contains('游戏')) {
      category = '娱乐';
    }
    if (cleanSms.contains('医疗') || cleanSms.contains('药店') || cleanSms.contains('医院')) {
      category = '医疗';
    }

    return Record(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: isExpense ? RecordType.expense : RecordType.income,
      category: category,
      note: isExpense ? '快捷支付' : '他行汇入',
      date: date ?? DateTime.now(),
    );
  }
}