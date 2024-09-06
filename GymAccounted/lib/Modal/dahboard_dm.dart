import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:flutter_json/flutter_json.dart';

class DashboardMembershipSummary {
  final int todaysNewMembers;
  final int duePayments;
  final int renewPayments;

  DashboardMembershipSummary({
    required this.todaysNewMembers,
    required this.duePayments,
    required this.renewPayments
  });
}

class DashboardAmount {
  final int todayCash;
  final int todayOnline;
  final int weekAmount;
  final int monthAmount;
  final int yearAmount;

  DashboardAmount({
    required this.todayCash,
    required this.todayOnline,
    required this.weekAmount,
    required this.monthAmount,
    required this.yearAmount,
  });
}

class DashboardMembersCounts {
  final int totalCount;
  final int activeCount;
  final int inactiveCount;
  final int newCount;

  DashboardMembersCounts({
    required this.totalCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.newCount,
  });
}
