class Membership {
  final int id; // Make id optional
  final String gymId;
  final String memberId;
  final String planId;
  final String joiningDate;
  final String status;

  Membership({
    this.id = 0, // Default value
    required this.gymId,
    required this.memberId,
    required this.planId,
    required this.joiningDate,
    required this.status,
  });

  factory Membership.fromJson(Map<String, dynamic> map) {
    return Membership(
      id: map['id'] ?? 0, // Provide a default value if id is null
      gymId: map['gym_id'],
      memberId: map['member_id'],
      planId: map['plan_id'],
      joiningDate: map['joining_date'],
      status: map['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Include id
      'gym_id': gymId,
      'member_id': memberId,
      'plan_id': planId,
      'joining_date': joiningDate,
      'status': status,
    };
  }
}
