import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter_json/flutter_json.dart';

class Plan {
  final int id;
  final String planName;
  final int planLimit;
  final String planPrice;
  final String gymId;

  Plan({
    required this.id,
    required this.planName,
    required this.planLimit,
    required this.planPrice,
    required this.gymId,
  });

  // You can add methods for serialization and deserialization if needed
  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'],
      planName: json['plan_name'],
      planLimit: json['plan_limit'],
      planPrice: json['plan_price'],
      gymId: json['gym_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'plan_limit': planLimit,
      'plan_price': planPrice,
      'gym_id':gymId,
    };
  }
}
