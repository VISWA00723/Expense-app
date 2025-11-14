class ExpenseModel {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String? notes;
  final String date; // ISO format: yyyy-mm-dd
  final String createdAt;

  ExpenseModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.notes,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'notes': notes,
      'date': date,
      'createdAt': createdAt,
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      notes: json['notes'],
      date: json['date'],
      createdAt: json['createdAt'],
    );
  }
}

class AIResponse {
  final String answer;
  final Map<String, dynamic> summary;

  AIResponse({
    required this.answer,
    required this.summary,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      answer: json['answer'] ?? '',
      summary: json['summary'] ?? {},
    );
  }
}
