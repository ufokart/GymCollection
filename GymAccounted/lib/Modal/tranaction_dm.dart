class Transaction {
  final int id;
  final String gymId;
  final int planId;
  final String amountType;
  final int amount;
  final DateTime createdAt;
  final int memberId;
  final String date;
  final String planName;
  final String planLimit;
  final String memberName;
  final String memberPhone;
  final String days;

  Transaction({
    required this.id,
    required this.gymId,
    required this.planId,
    required this.amountType,
    required this.amount,
    required this.createdAt,
    required this.memberId,
    required this.date,
    required this.planName,
    required this.planLimit,
    required this.memberName,
    required this.memberPhone,
    required this.days,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0, // Default value for id
      gymId: json['gym_id'] ?? '', // Default value for gymId
      planId: json['plan_id'] ?? 0, // Default value for planId
      amountType: json['amount_type'] ?? 'Unknown', // Default value for amountType
      amount: (json['amount'] != null) ? int.parse(json['amount'].toString()) : 0, // Default value for amount
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()), // Default to current time if null
      memberId: json['member_id'] ?? 0, // Default value for memberId
      date: json['date'] ?? DateTime.now().toIso8601String(), // Default to current date if null
      planName: json['plan_name'] ?? 'No Plan', // Default value for planName
      planLimit: json['plan_limit'] ?? '0', // Default value for planLimit
      memberName: json['member_name'] ?? 'Unknown', // Default value for memberName
      memberPhone: json['member_phone_no'] ?? 'N/A',
      days: json['days'] ?? '0'// Default value for memberPhone
    );
  }
}
