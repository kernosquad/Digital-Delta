import 'dart:convert';

class PendingAuthAction {
  final int id;
  final String type;
  final String email;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const PendingAuthAction({
    required this.id,
    required this.type,
    required this.email,
    required this.payload,
    required this.createdAt,
  });

  factory PendingAuthAction.fromRow(Map<String, Object?> row) {
    return PendingAuthAction(
      id: row['id'] as int,
      type: row['type'] as String,
      email: row['email'] as String,
      payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
