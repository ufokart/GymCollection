import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter_json/flutter_json.dart';

class Member {
  final int id;
  final String name;
  final String email;
  final String phoneNo;
  final String gender;
  final String batch;
  final DateTime createdAt;
  final String gymId;
  final String image;
  final String joiningDate;
  final String dob;
  final String address;
  final int planId;
  final int status; // Changed to int
  final bool renew; // Changed to bool
  final String expiredAt;
  final String amountType;

  Member(
      {required this.id,
      required this.name,
      required this.email,
      required this.phoneNo,
      required this.gender,
      required this.batch,
      required this.createdAt,
      required this.gymId,
      required this.image,
      required this.joiningDate,
      required this.dob,
      required this.address,
      required this.planId,
      required this.status, // Added to constructor
      required this.renew, // Added to constructor
      required this.expiredAt,
      required this.amountType});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNo: json['phone_no'],
      gender: json['gender'],
      batch: json['batch'],
      createdAt: DateTime.parse(json['created_at']),
      gymId: json['gym_id'],
      image: json['image'] ?? "",
      joiningDate: json['joining_date'],
      dob: json['dob'],
      address: json['address'],
      planId: json['plan_id'],
      status: json['status'] ?? 1,
      // Added to fromJson
      renew: json['renew_plan'] ?? false,
      expiredAt: json['expiredAt'] ?? "", // Added to fromJson
      amountType: json['amount_type'] ?? ""
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_no': phoneNo,
      'gender': gender,
      'batch': batch,
      'created_at': createdAt.toIso8601String(),
      'gym_id': gymId,
      'joining_date': joiningDate,
      'dob': dob,
      'address': address,
      'plan_id': planId,
      'status': status, // Added to toJson
      'renew_plan': renew,
      'expiredAt': expiredAt, // Added to toJson
      'amount_type': amountType,
    };
  }
}
