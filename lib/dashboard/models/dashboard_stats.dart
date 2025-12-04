/// Statistics model for dashboard
class DashboardStats {
  final int totalEmployees;
  final int todayShifts;
  final double weeklyHours;
  final int conflicts;

  const DashboardStats({
    required this.totalEmployees,
    required this.todayShifts,
    required this.weeklyHours,
    required this.conflicts,
  });
}

