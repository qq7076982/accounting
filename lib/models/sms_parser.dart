import '../models/record.dart';

class SmsParser {
  // 邮储银行解析（宽松匹配，允许多余空格）
  // 支出：【邮储银行】26年05月29日11:21您尾号8116账户快捷支付-支付宝，支出金额100.00元，余额83528.21元
  // 收入：【邮储银行】26年05月27日13:02湖北空分工程科技有限公司账户6618向您尾号8116账户他行汇入，收入金额16246.07元，余额84696.59元

  static Record? parse(String sms) {
    if (!sms.contains('邮储银行')) return null;

    final cleanSms = sms.replaceAll(RegExp(r'\s+'), '');

    final isExpense = cleanSms.contains('支出金额');
    final isIncome = cleanSms.contains('收入金额') && cleanSms.contains('汇入');

    if (!isExpense && !isIncome) return null;

    // 金额匹配
    final amountMatch = RegExp(r'[支收]入金额(\d+\.?\d*)元').firstMatch(cleanSms);
    if (amountMatch == null) return null;
    final amount = double.tryParse(amountMatch.group(1) ?? '');
    if (amount == null || amount <= 0) return null;

    // 日期匹配
    DateTime? date;
    final dateMatch = RegExp(r'(\d{2})年(\d{2})月(\d{2})日(\d{2}):(\d{2})').firstMatch(cleanSms);
    if (dateMatch != null) {
      final year = 2000 + int.parse(dateMatch.group(1)!);
      final month = int.parse(dateMatch.group(2)!);
      final day = int.parse(dateMatch.group(3)!);
      final hour = int.parse(dateMatch.group(4)!);
      final minute = int.parse(dateMatch.group(5)!);
      date = DateTime(year, month, day, hour, minute);
    }

    // 分类
    String category = '其他';
    if (cleanSms.contains('快捷支付') || cleanSms.contains('支付宝') || cleanSms.contains('微信') || cleanSms.contains('银联')) {
      category = '购物';
    }
    if (cleanSms.contains('汇入') || cleanSms.contains('工资') || cleanSms.contains('转账存入')) {
      category = '工资';
    }
    if (cleanSms.contains('餐饮') || cleanSms.contains('消费')) {
      category = '餐饮';
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