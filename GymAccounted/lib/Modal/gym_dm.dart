class Gym {
  final int id;
  final String userId;
  final String name;
  final String image;
  final String phoneNo;
  final String email;
  final bool active;
  final String address;

  Gym({
    required this.id,
    required this.userId,
    required this.name,
    required this.image,
    required this.phoneNo,
    required this.email,
    required this.active,
    required this.address,
  });

  // Factory constructor for creating a User instance from a JSON object
  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      image: json['image'],
      phoneNo: json['phone_no'],
      email: json['email'],
      active: json['active'],
      address: json['address'],
    );
  }

  // Method to convert a User instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'image': image,
      'phone_no': phoneNo,
      'email': email,
      'active': active,
      'address': address,
    };
  }
}