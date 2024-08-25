import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Modal/UserModal.dart' as gymUser;
import 'package:gymaccounted/Modal/gym_dm.dart';

class Subscription {
  final int id;
  final String name;
  final String price;
  final String actualPrice;

  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.actualPrice,
  });

  factory Subscription.fromMap(Map<String, dynamic> data) {
    return Subscription(
      id: data['id'],
      name: data['name'],
      price: data['price'],
      actualPrice: data['price_actual'],
    );
  }
}