enum RecordType { income, expense }

class Record {
  final String id;
  final double amount;
  final RecordType type;
  final String category;
  final String note;
  final DateTime date;

  Record({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type.index,
    'category': category,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory Record.fromJson(Map<String, dynamic> json) => Record(
    id: json['id'],
    amount: (json['amount'] as num).toDouble(),
    type: RecordType.values[json['type']],
    category: json['category'],
    note: json['note'] ?? '',
    date: DateTime.parse(json['date']),
  );
}

const incomeCategories = ['工资', '奖金', '投资', '红包', '其他'];
const expenseCategories = ['餐饮', '交通', '购物', '房租', '娱乐', '医疗', '通讯', '其他'];