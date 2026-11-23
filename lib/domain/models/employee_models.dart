import 'dart:math' as math;

/// Haversine distance in meters between two WGS-84 coordinates.
int calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusMeters = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180.0;
  final dLon = (lon2 - lon1) * math.pi / 180.0;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180.0) *
          math.cos(lat2 * math.pi / 180.0) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return (earthRadiusMeters * c).round();
}

enum PunchMethod {
  mobile('MOBILE', 'Mobile'),
  selfie('SELFIE', 'Selfie'),
  biometric('BIOMETRIC', 'Biometric'),
  field('FIELD', 'Field'),
  web('WEB', 'Web');

  const PunchMethod(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static PunchMethod fromApi(String? value) {
    return PunchMethod.values.firstWhere(
      (m) => m.apiValue == value,
      orElse: () => PunchMethod.mobile,
    );
  }
}

class WorkspaceMembership {
  const WorkspaceMembership({
    required this.organizationId,
    required this.organizationName,
    required this.roleName,
  });

  final String organizationId;
  final String organizationName;
  final String roleName;

  factory WorkspaceMembership.fromJson(Map<String, dynamic> json) {
    final org = json['organization'] as Map<String, dynamic>?;
    return WorkspaceMembership(
      organizationId: (json['organizationId'] ?? org?['id'] ?? '').toString(),
      organizationName: (json['organizationName'] ?? org?['name'] ?? 'Workspace').toString(),
      roleName: (json['roleName'] ?? json['role'] ?? 'EMPLOYEE').toString(),
    );
  }
}

class EmployeeUser {
  const EmployeeUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarInitials,
    required this.memberships,
  });

  final String id;
  final String name;
  final String email;
  final String avatarInitials;
  final List<WorkspaceMembership> memberships;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  factory EmployeeUser.fromJson(Map<String, dynamic> json) {
    final rawMemberships = (json['memberships'] as List?) ?? const [];
    final memberships = rawMemberships
        .whereType<Map<String, dynamic>>()
        .map(WorkspaceMembership.fromJson)
        .toList();
    return EmployeeUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatarInitials: (json['avatarInitials'] ?? 'EM').toString(),
      memberships: memberships,
    );
  }
}

class EmployeeProfile {
  const EmployeeProfile({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.avatarInitials,
    required this.email,
    required this.phone,
    required this.department,
    required this.designation,
    required this.status,
    required this.employmentType,
    required this.location,
    required this.homeAddress,
    required this.joinedAt,
    required this.employeeId,
    this.managerName,
  });

  final String id;
  final String organizationId;
  final String name;
  final String avatarInitials;
  final String email;
  final String phone;
  final String department;
  final String designation;
  final String status;
  final String employmentType;
  final String location;
  final String homeAddress;
  final String joinedAt;
  final String employeeId;
  final String? managerName;

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      id: (json['id'] ?? '').toString(),
      organizationId: (json['organizationId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      avatarInitials: (json['avatarInitials'] ?? 'EM').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      department: (json['department'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      status: (json['status'] ?? 'ACTIVE').toString(),
      employmentType: (json['employmentType'] ?? 'FULL_TIME').toString(),
      location: (json['location'] ?? '').toString(),
      homeAddress: (json['homeAddress'] ?? '').toString(),
      joinedAt: (json['joinedAt'] ?? '').toString(),
      employeeId: (json['employeeId'] ?? '').toString(),
      managerName: json['managerName']?.toString(),
    );
  }
}

class AttendanceSettings {
  const AttendanceSettings({
    required this.geofenceEnabled,
    required this.officeName,
    required this.officeLatitude,
    required this.officeLongitude,
    required this.geofenceRadiusMeters,
  });

  final bool geofenceEnabled;
  final String officeName;
  final double? officeLatitude;
  final double? officeLongitude;
  final int geofenceRadiusMeters;

  factory AttendanceSettings.fromJson(Map<String, dynamic> json) {
    return AttendanceSettings(
      geofenceEnabled: json['geofenceEnabled'] == true,
      officeName: (json['officeName'] ?? 'Alderway HQ').toString(),
      officeLatitude: (json['officeLatitude'] as num?)?.toDouble(),
      officeLongitude: (json['officeLongitude'] as num?)?.toDouble(),
      geofenceRadiusMeters: (json['geofenceRadiusMeters'] as num?)?.toInt() ?? 250,
    );
  }
}

class PunchMeta {
  const PunchMeta({
    this.method,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.address,
    this.selfieUrl,
    this.biometricVerified = false,
    this.geofenceStatus,
    this.distanceMeters,
  });

  final String? method;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? address;
  final String? selfieUrl;
  final bool biometricVerified;
  final String? geofenceStatus;
  final int? distanceMeters;

  factory PunchMeta.fromJson(Map<String, dynamic> json) {
    return PunchMeta(
      method: json['method']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      address: json['address']?.toString(),
      selfieUrl: json['selfieUrl']?.toString(),
      biometricVerified: json['biometricVerified'] == true,
      geofenceStatus: json['geofenceStatus']?.toString(),
      distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'method': method,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'address': address,
    'selfieUrl': selfieUrl,
    'biometricVerified': biometricVerified,
    'geofenceStatus': geofenceStatus,
    'distanceMeters': distanceMeters,
  };

  PunchMeta copyWith({
    String? method,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
    String? selfieUrl,
    bool? biometricVerified,
    String? geofenceStatus,
    int? distanceMeters,
  }) {
    return PunchMeta(
      method: method ?? this.method,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      address: address ?? this.address,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      biometricVerified: biometricVerified ?? this.biometricVerified,
      geofenceStatus: geofenceStatus ?? this.geofenceStatus,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}

class MyTodayStatus {
  const MyTodayStatus({
    required this.checkedIn,
    required this.checkedOut,
    this.checkInTime,
    this.checkOutTime,
    this.checkInMeta,
    this.checkOutMeta,
    this.onLeaveType,
  });

  final bool checkedIn;
  final bool checkedOut;
  final String? checkInTime;
  final String? checkOutTime;
  final PunchMeta? checkInMeta;
  final PunchMeta? checkOutMeta;
  final String? onLeaveType;

  factory MyTodayStatus.fromJson(Map<String, dynamic> json) {
    final onLeave = json['onLeave'] as Map<String, dynamic>?;
    return MyTodayStatus(
      checkedIn: json['checkedIn'] == true,
      checkedOut: json['checkedOut'] == true,
      checkInTime: json['checkInTime']?.toString(),
      checkOutTime: json['checkOutTime']?.toString(),
      checkInMeta: json['checkInMeta'] is Map<String, dynamic>
          ? PunchMeta.fromJson(json['checkInMeta'] as Map<String, dynamic>)
          : null,
      checkOutMeta: json['checkOutMeta'] is Map<String, dynamic>
          ? PunchMeta.fromJson(json['checkOutMeta'] as Map<String, dynamic>)
          : null,
      onLeaveType: onLeave?['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'checkedIn': checkedIn,
    'checkedOut': checkedOut,
    'checkInTime': checkInTime,
    'checkOutTime': checkOutTime,
    'checkInMeta': checkInMeta?.toJson(),
    'checkOutMeta': checkOutMeta?.toJson(),
    if (onLeaveType != null) 'onLeave': {'type': onLeaveType},
  };

  MyTodayStatus copyWith({
    bool? checkedIn,
    bool? checkedOut,
    String? checkInTime,
    String? checkOutTime,
    PunchMeta? checkInMeta,
    PunchMeta? checkOutMeta,
    String? onLeaveType,
  }) {
    return MyTodayStatus(
      checkedIn: checkedIn ?? this.checkedIn,
      checkedOut: checkedOut ?? this.checkedOut,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInMeta: checkInMeta ?? this.checkInMeta,
      checkOutMeta: checkOutMeta ?? this.checkOutMeta,
      onLeaveType: onLeaveType ?? this.onLeaveType,
    );
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    required this.hours,
    this.clockIn,
    this.clockOut,
    this.checkInMeta,
    this.checkOutMeta,
  });

  final String id;
  final String date;
  final String status;
  final double hours;
  final String? clockIn;
  final String? clockOut;
  final PunchMeta? checkInMeta;
  final PunchMeta? checkOutMeta;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: (json['id'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      status: (json['status'] ?? 'ABSENT').toString(),
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      clockIn: json['clockIn']?.toString(),
      clockOut: json['clockOut']?.toString(),
      checkInMeta: json['checkInMeta'] is Map<String, dynamic>
          ? PunchMeta.fromJson(json['checkInMeta'] as Map<String, dynamic>)
          : null,
      checkOutMeta: json['checkOutMeta'] is Map<String, dynamic>
          ? PunchMeta.fromJson(json['checkOutMeta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AttendanceMonth {
  const AttendanceMonth({
    required this.year,
    required this.month,
    required this.todayDate,
    required this.records,
    this.myTodayStatus,
  });

  final int year;
  final int month;
  final String todayDate;
  final List<AttendanceRecord> records;
  final MyTodayStatus? myTodayStatus;

  factory AttendanceMonth.fromJson(Map<String, dynamic> json) {
    final monthRows = (json['myMonthRecords'] as List?) ?? (json['today'] as List?) ?? const [];
    final rawRecords = monthRows
        .whereType<Map<String, dynamic>>()
        .map(AttendanceRecord.fromJson)
        .toList();

    return AttendanceMonth(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month - 1,
      todayDate: (json['todayDate'] ?? '').toString(),
      records: rawRecords,
      myTodayStatus: json['myTodayStatus'] is Map<String, dynamic>
          ? MyTodayStatus.fromJson(json['myTodayStatus'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FieldVisit {
  const FieldVisit({
    required this.id,
    required this.date,
    required this.clientName,
    required this.purpose,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.checkedInAt,
    this.address,
    this.accuracy,
    this.notes,
    this.selfieUrl,
    this.biometricVerified = false,
    this.checkedOutAt,
  });

  final String id;
  final String date;
  final String clientName;
  final String purpose;
  final double latitude;
  final double longitude;
  final String status; // ACTIVE | COMPLETED
  final String checkedInAt;
  final String? address;
  final double? accuracy;
  final String? notes;
  final String? selfieUrl;
  final bool biometricVerified;
  final String? checkedOutAt;

  bool get isCompleted => status == 'COMPLETED';

  factory FieldVisit.fromJson(Map<String, dynamic> json) {
    return FieldVisit(
      id: (json['id'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      clientName: (json['clientName'] ?? '').toString(),
      purpose: (json['purpose'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? 'ACTIVE').toString(),
      checkedInAt: (json['checkedInAt'] ?? '').toString(),
      address: json['address']?.toString(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      notes: json['notes']?.toString(),
      selfieUrl: json['selfieUrl']?.toString(),
      biometricVerified: json['biometricVerified'] == true,
      checkedOutAt: json['checkedOutAt']?.toString(),
    );
  }
}

class LeaveBalance {
  const LeaveBalance({
    required this.type,
    required this.total,
    required this.used,
    required this.pending,
  });

  final String type;
  final double total;
  final double used;
  final double pending;

  double get remaining => type == 'UNPAID' ? 0 : math.max(0, total - used);

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      type: (json['type'] ?? 'ANNUAL').toString(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      used: (json['used'] as num?)?.toDouble() ?? 0,
      pending: (json['pending'] as num?)?.toDouble() ?? 0,
    );
  }
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.isHalfDay,
    this.halfDayPeriod,
    required this.reason,
    required this.status,
    required this.requestedAt,
  });

  final String id;
  final String type;
  final String startDate;
  final String endDate;
  final double days;
  final bool isHalfDay;
  final String? halfDayPeriod;
  final String reason;
  final String status;
  final String requestedAt;

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'ANNUAL').toString(),
      startDate: (json['startDate'] ?? '').toString(),
      endDate: (json['endDate'] ?? '').toString(),
      days: (json['days'] as num?)?.toDouble() ?? 1,
      isHalfDay: json['isHalfDay'] == true,
      halfDayPeriod: json['halfDayPeriod']?.toString(),
      reason: (json['reason'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      requestedAt: (json['requestedAt'] ?? '').toString(),
    );
  }
}

class LeaveData {
  const LeaveData({
    required this.balances,
    required this.requests,
    required this.holidays,
  });

  final List<LeaveBalance> balances;
  final List<LeaveRequest> requests;
  final List<String> holidays;

  factory LeaveData.fromJson(Map<String, dynamic> json) {
    return LeaveData(
      balances: ((json['balances'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LeaveBalance.fromJson)
          .toList(),
      requests: ((json['requests'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LeaveRequest.fromJson)
          .toList(),
      holidays: ((json['holidays'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class Payslip {
  const Payslip({
    required this.month,
    required this.status,
    required this.hasSalaryStructure,
    required this.basic,
    required this.hra,
    required this.otherAllowance,
    required this.daysInMonth,
    required this.unpaidDays,
    required this.bonus,
    required this.incentive,
    required this.reimbursement,
    required this.incomeTax,
    required this.otherDeduction,
    required this.lopDeduction,
    required this.grossEarnings,
    required this.totalDeductions,
    required this.netSalary,
    this.finalizedAt,
  });

  final String month;
  final String status;
  final bool hasSalaryStructure;
  final double basic;
  final double hra;
  final double otherAllowance;
  final int daysInMonth;
  final double unpaidDays;
  final double bonus;
  final double incentive;
  final double reimbursement;
  final double incomeTax;
  final double otherDeduction;
  final double lopDeduction;
  final double grossEarnings;
  final double totalDeductions;
  final double netSalary;
  final String? finalizedAt;

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      month: (json['month'] ?? '').toString(),
      status: (json['status'] ?? 'DRAFT').toString(),
      hasSalaryStructure: json['hasSalaryStructure'] != false,
      basic: (json['basic'] as num?)?.toDouble() ?? 0,
      hra: (json['hra'] as num?)?.toDouble() ?? 0,
      otherAllowance: (json['otherAllowance'] as num?)?.toDouble() ?? 0,
      daysInMonth: (json['daysInMonth'] as num?)?.toInt() ?? 30,
      unpaidDays: (json['unpaidDays'] as num?)?.toDouble() ?? 0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
      incentive: (json['incentive'] as num?)?.toDouble() ?? 0,
      reimbursement: (json['reimbursement'] as num?)?.toDouble() ?? 0,
      incomeTax: (json['incomeTax'] as num?)?.toDouble() ?? 0,
      otherDeduction: (json['otherDeduction'] as num?)?.toDouble() ?? 0,
      lopDeduction: (json['lopDeduction'] as num?)?.toDouble() ?? 0,
      grossEarnings: (json['grossEarnings'] as num?)?.toDouble() ?? 0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 0,
      finalizedAt: json['finalizedAt']?.toString(),
    );
  }
}

class CompanyDocument {
  const CompanyDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.fileType,
    required this.sizeKb,
    required this.updatedAt,
    required this.updatedBy,
    required this.url,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String fileType;
  final int sizeKb;
  final String updatedAt;
  final String updatedBy;
  final String url;

  factory CompanyDocument.fromJson(Map<String, dynamic> json) {
    return CompanyDocument(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'Policies').toString(),
      fileType: (json['fileType'] ?? 'PDF').toString(),
      sizeKb: (json['sizeKb'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updatedAt'] ?? '').toString(),
      updatedBy: (json['updatedBy'] ?? 'HR').toString(),
      url: (json['cloudinaryUrl'] ?? '').toString(),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.read,
    required this.createdAt,
    this.type,
    this.priority,
    this.icon,
    this.holidayFrom,
    this.holidayTo,
    this.reopenDate,
    this.requiresAck = false,
    this.acknowledgedAt,
    this.pinned = false,
    this.imageUrl,
    this.attachmentUrl,
  });

  final String id;
  final String title;
  final String body;
  final String kind;
  final bool read;
  final String createdAt;
  final String? type;
  final String? priority;
  final String? icon;
  final String? holidayFrom;
  final String? holidayTo;
  final String? reopenDate;
  final bool requiresAck;
  final String? acknowledgedAt;
  final bool pinned;
  final String? imageUrl;
  final String? attachmentUrl;

  bool get isAcknowledged => acknowledgedAt != null && acknowledgedAt!.isNotEmpty;

  AppNotification copyWith({
    bool? read,
    String? acknowledgedAt,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      kind: kind,
      read: read ?? this.read,
      createdAt: createdAt,
      type: type,
      priority: priority,
      icon: icon,
      holidayFrom: holidayFrom,
      holidayTo: holidayTo,
      reopenDate: reopenDate,
      requiresAck: requiresAck,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      pinned: pinned,
      imageUrl: imageUrl,
      attachmentUrl: attachmentUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'kind': kind,
      'read': read,
      'createdAt': createdAt,
      'type': type,
      'priority': priority,
      'icon': icon,
      'holidayFrom': holidayFrom,
      'holidayTo': holidayTo,
      'reopenDate': reopenDate,
      'requiresAck': requiresAck,
      'acknowledgedAt': acknowledgedAt,
      'pinned': pinned,
      'imageUrl': imageUrl,
      'attachmentUrl': attachmentUrl,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      kind: (json['kind'] ?? json['type'] ?? 'info').toString(),
      read: json['read'] == true,
      createdAt: (json['createdAt'] ?? '').toString(),
      type: json['type']?.toString(),
      priority: json['priority']?.toString(),
      icon: json['icon']?.toString(),
      holidayFrom: json['holidayFrom']?.toString(),
      holidayTo: json['holidayTo']?.toString(),
      reopenDate: json['reopenDate']?.toString(),
      requiresAck: json['requiresAck'] == true,
      acknowledgedAt: json['acknowledgedAt']?.toString(),
      pinned: json['pinned'] == true,
      imageUrl: json['imageUrl']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
    );
  }
}

class TimesheetRowItem {
  const TimesheetRowItem({
    required this.client,
    required this.project,
    required this.task,
    required this.hours,
    required this.isBillable,
  });

  final String client;
  final String project;
  final String task;
  final List<double> hours;
  final bool isBillable;

  double get totalHours => hours.fold(0.0, (a, b) => a + b);

  factory TimesheetRowItem.fromJson(Map<String, dynamic> json) {
    final rawHours = ((json['hours'] as List?) ?? const [0, 0, 0, 0, 0, 0, 0])
        .map((e) => (e as num).toDouble())
        .toList();
    while (rawHours.length < 7) {
      rawHours.add(0);
    }
    return TimesheetRowItem(
      client: (json['client'] ?? '').toString(),
      project: (json['project'] ?? '').toString(),
      task: (json['task'] ?? '').toString(),
      hours: rawHours.take(7).toList(),
      isBillable: json['isBillable'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'client': client,
        'project': project,
        'task': task,
        'hours': hours,
        'isBillable': isBillable,
      };
}

class TimesheetWeek {
  const TimesheetWeek({
    this.id,
    required this.weekStartDate,
    required this.status,
    required this.rows,
  });

  final String? id;
  final String weekStartDate;
  final String status;
  final List<TimesheetRowItem> rows;

  double get totalHours => rows.fold(0.0, (sum, r) => sum + r.totalHours);

  factory TimesheetWeek.fromJson(Map<String, dynamic> json, String fallbackWeek) {
    return TimesheetWeek(
      id: json['id']?.toString(),
      weekStartDate: (json['weekStartDate'] ?? fallbackWeek).toString(),
      status: (json['status'] ?? 'DRAFT').toString(),
      rows: ((json['rows'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TimesheetRowItem.fromJson)
          .toList(),
    );
  }
}

class TicketComment {
  const TicketComment({
    required this.id,
    required this.authorName,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String authorName;
  final String comment;
  final String createdAt;

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: (json['id'] ?? '').toString(),
      authorName: (json['authorName'] ?? json['userName'] ?? 'Support').toString(),
      comment: (json['comment'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class HelpdeskTicket {
  const HelpdeskTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.comments,
  });

  final String id;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String createdAt;
  final List<TicketComment> comments;

  factory HelpdeskTicket.fromJson(Map<String, dynamic> json) {
    return HelpdeskTicket(
      id: (json['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'HR').toString(),
      priority: (json['priority'] ?? 'MEDIUM').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      comments: ((json['comments'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(TicketComment.fromJson)
          .toList(),
    );
  }
}

class HolidayItem {
  const HolidayItem({
    required this.date,
    required this.name,
    this.type = 'Public Holiday',
  });

  final String date;
  final String name;
  final String type;
}

class DashboardStat {
  const DashboardStat({
    required this.id,
    required this.label,
    required this.value,
    this.delta,
  });

  final String id;
  final String label;
  final String value;
  final String? delta;

  factory DashboardStat.fromJson(Map<String, dynamic> json) {
    return DashboardStat(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      delta: json['delta']?.toString(),
    );
  }
}

class GeoLocationFix {
  const GeoLocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.addressLabel,
    this.isSimulated = false,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final String addressLabel;
  final bool isSimulated;
}

class SelfieCaptureResult {
  const SelfieCaptureResult({
    required this.dataUrl,
    required this.bytesLength,
    this.isSimulated = false,
  });

  final String dataUrl;
  final int bytesLength;
  final bool isSimulated;
}

class BiometricResult {
  const BiometricResult({
    required this.verified,
    required this.label,
    this.isSimulated = false,
  });

  final bool verified;
  final String label;
  final bool isSimulated;
}

