class PurchasedPlansDm {
  final String gymId;
  final String subscriptionId;
  final String date;
  final String status;
  final String expireDate;
  final String price;
  final String name;

  PurchasedPlansDm({
    required this.gymId,
    required this.subscriptionId,
    required this.date,
    required this.status,
    required this.expireDate,
    required this.price,
    required this.name,
  });

  // Factory method to create a Subscription from a JSON object
  factory PurchasedPlansDm.fromJson(Map<String, dynamic> json) {
    return PurchasedPlansDm(
      gymId: json['gym_id'] ?? '', // Provide default values if null
      subscriptionId: json['subscription_id'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      expireDate: json['expire_date'] ?? '',
      price: json['price'] ?? '',
      name: json['name'] ?? '',
    );
  }

  // Method to convert a Subscription to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'gym_id': gymId,
      'subscription_id': subscriptionId,
      'date': date,
      'status': status,
      'expire_date': expireDate,
      'price': price,
      'name': name,
    };
  }
}
