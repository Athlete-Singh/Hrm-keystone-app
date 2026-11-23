import '../../domain/models/employee_models.dart';

/// Offline / preview dataset matching `hrm-backend` seeded employee `Amit Patel` (`usr-4` / `EMP-004`).
/// Used only when the user explicitly enters Offline Preview mode or when no backend server is reachable.
class DemoStore {
  DemoStore() {
    _initDefaults();
  }

  late EmployeeUser user;
  late EmployeeProfile profile;
  late AttendanceSettings settings;
  MyTodayStatus todayStatus = const MyTodayStatus(checkedIn: false, checkedOut: false);
  late List<AttendanceRecord> records;
  late List<FieldVisit> visits;
  late LeaveData leaveData;
  late List<CompanyDocument> documents;
  late List<AppNotification> notifications;
  late TimesheetWeek timesheet;
  late List<HelpdeskTicket> tickets;

  void _initDefaults() {
    user = const EmployeeUser(
      id: 'usr-4',
      name: 'Amit Patel',
      email: 'employee@demo.com',
      avatarInitials: 'AP',
      memberships: [
        WorkspaceMembership(
          organizationId: 'org-alderway',
          organizationName: 'Alderway Technologies',
          roleName: 'Employee',
        ),
      ],
    );

    profile = const EmployeeProfile(
      id: 'emp-4',
      organizationId: 'org-alderway',
      name: 'Amit Patel',
      avatarInitials: 'AP',
      email: 'employee@demo.com',
      phone: '+91 98204 51120',
      department: 'Engineering',
      designation: 'Software Engineer',
      status: 'ACTIVE',
      employmentType: 'FULL_TIME',
      location: 'Andheri East, Mumbai',
      homeAddress: '402 Lakeview Residency, Powai, Mumbai',
      joinedAt: '2024-04-08T00:00:00.000Z',
      employeeId: 'EMP-004',
      managerName: 'Marta Lindqvist',
    );

    settings = const AttendanceSettings(
      geofenceEnabled: false,
      officeName: 'Alderway HQ · Andheri East',
      officeLatitude: 19.1136,
      officeLongitude: 72.8697,
      geofenceRadiusMeters: 250,
    );

    final now = DateTime.now();
    records = List.generate(7, (idx) {
      final day = now.subtract(Duration(days: idx + 1));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        return AttendanceRecord(id: 'demo-$idx', date: dateStr, status: 'WEEKEND', hours: 0);
      }
      final late = idx == 2;
      return AttendanceRecord(
        id: 'demo-$idx',
        date: dateStr,
        status: late ? 'LATE' : 'PRESENT',
        clockIn: late ? '09:42' : '09:04',
        clockOut: '18:16',
        hours: late ? 8.5 : 9.2,
        checkInMeta: PunchMeta(
          method: idx == 1 ? 'SELFIE' : 'BIOMETRIC',
          latitude: 19.1136,
          longitude: 72.8697,
          accuracy: 11,
          address: 'Alderway HQ · Andheri East',
          biometricVerified: true,
          geofenceStatus: 'INSIDE',
          distanceMeters: 38,
        ),
      );
    });

    final todayIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    visits = [
      FieldVisit(
        id: 'fv-demo-1',
        date: todayIso,
        clientName: 'Surya Logistics Hub',
        purpose: 'Badge kiosk & Wi-Fi check',
        address: 'Chakala Industrial Area, Mumbai',
        latitude: 19.1151,
        longitude: 72.8654,
        accuracy: 14,
        notes: 'Verified reader power supply and test punch.',
        biometricVerified: true,
        status: 'COMPLETED',
        checkedInAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
        checkedOutAt: now.subtract(const Duration(hours: 2, minutes: 10)).toIso8601String(),
      ),
    ];

    leaveData = const LeaveData(
      balances: [
        LeaveBalance(type: 'ANNUAL', total: 25, used: 4, pending: 2),
        LeaveBalance(type: 'SICK', total: 10, used: 1, pending: 0),
        LeaveBalance(type: 'PERSONAL', total: 5, used: 1, pending: 0),
        LeaveBalance(type: 'UNPAID', total: 0, used: 0, pending: 0),
      ],
      requests: [
        LeaveRequest(
          id: 'lv-demo-1',
          type: 'ANNUAL',
          startDate: '2026-11-26',
          endDate: '2026-11-27',
          days: 2,
          isHalfDay: false,
          reason: 'Family wedding out of town',
          status: 'PENDING',
          requestedAt: '2026-11-10T09:15:00Z',
        ),
        LeaveRequest(
          id: 'lv-demo-2',
          type: 'SICK',
          startDate: '2026-10-14',
          endDate: '2026-10-14',
          days: 1,
          isHalfDay: false,
          reason: 'Viral fever recovery',
          status: 'APPROVED',
          requestedAt: '2026-10-13T20:00:00Z',
        ),
      ],
      holidays: ['2026-11-24', '2026-12-25', '2027-01-01'],
    );

    documents = const [
      CompanyDocument(
        id: 'doc-1',
        name: 'Employee Handbook 2026',
        description: 'Attendance rules, remote work etiquette, leave carry-forward policy.',
        category: 'Policies',
        fileType: 'PDF',
        sizeKb: 840,
        updatedAt: '2026-04-01',
        updatedBy: 'Marta Lindqvist',
        url: '',
      ),
      CompanyDocument(
        id: 'doc-2',
        name: 'Appointment Letter — Amit Patel',
        description: 'Signed employment terms and Mumbai base office clause.',
        category: 'Contracts',
        fileType: 'PDF',
        sizeKb: 312,
        updatedAt: '2024-04-08',
        updatedBy: 'Priya Nair',
        url: '',
      ),
      CompanyDocument(
        id: 'doc-3',
        name: 'POSH & Workplace Safety Policy',
        description: 'Annual mandatory workplace conduct acknowledgement.',
        category: 'Compliance',
        fileType: 'PDF',
        sizeKb: 490,
        updatedAt: '2026-01-15',
        updatedBy: 'HR Operations',
        url: '',
      ),
    ];

    notifications = [
      AppNotification(
        id: 'notif-1',
        title: 'Payslip available for October',
        body: 'Your finalized salary breakdown for October is ready to review.',
        kind: 'payroll',
        read: false,
        createdAt: now.subtract(const Duration(hours: 4)).toIso8601String(),
      ),
      AppNotification(
        id: 'notif-2',
        title: 'Geofence radius updated',
        body: 'Alderway HQ attendance zone set to 250 m around Andheri East.',
        kind: 'attendance',
        read: true,
        createdAt: now.subtract(const Duration(days: 2)).toIso8601String(),
      ),
    ];

    timesheet = const TimesheetWeek(
      id: 'ts-demo-1',
      weekStartDate: '2026-11-09',
      status: 'DRAFT',
      rows: [
        TimesheetRowItem(
          client: 'Internal',
          project: 'Keystone Mobile App',
          task: 'Attendance & Geofence module',
          hours: [8, 8, 7.5, 6, 0, 0, 0],
          isBillable: false,
        ),
        TimesheetRowItem(
          client: 'Surya Logistics',
          project: 'Field Rollout',
          task: 'Biometric kiosk integration',
          hours: [0, 0, 1, 2, 0, 0, 0],
          isBillable: true,
        ),
      ],
    );

    tickets = [
      HelpdeskTicket(
        id: 'tkt-demo-1',
        subject: 'Update emergency contact phone number',
        description: 'Please update my secondary emergency contact in HR records.',
        category: 'HR',
        priority: 'LOW',
        status: 'RESOLVED',
        createdAt: now.subtract(const Duration(days: 5)).toIso8601String(),
        comments: [
          TicketComment(
            id: 'c-1',
            authorName: 'Marta Lindqvist',
            comment: 'Updated in your personnel file.',
            createdAt: now.subtract(const Duration(days: 4)).toIso8601String(),
          ),
        ],
      ),
    ];
  }
}

