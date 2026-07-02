/// Row shape returned by both Api\V1\RepairJobController@index and the
/// dashboard's period_jobs list — one model covers both call sites.
class RepairJobSummary {
  const RepairJobSummary({
    required this.id,
    required this.jobNumber,
    required this.deviceModel,
    required this.status,
    required this.createdAt,
    this.imei,
    this.flag,
    this.priority,
    this.estimateCost,
    this.finalCost,
    this.balanceDue,
    this.dueDate,
    this.customerName,
    this.customerPhone,
    this.technicianName,
  });

  final int id;
  final String jobNumber;
  final String? deviceModel;
  final String status;
  final DateTime createdAt;
  final String? imei;
  final String? flag;
  final String? priority;
  final num? estimateCost;
  final num? finalCost;
  final num? balanceDue;
  final String? dueDate;
  final String? customerName;
  final String? customerPhone;
  final String? technicianName;

  factory RepairJobSummary.fromJson(Map<String, dynamic> json) {
    return RepairJobSummary(
      id: json['id'] as int,
      jobNumber: json['job_number'] as String? ?? '',
      deviceModel: json['device_model'] as String?,
      status: json['status'] as String? ?? 'received',
      createdAt: DateTime.parse(json['created_at'] as String),
      imei: json['imei'] as String?,
      flag: json['flag'] as String?,
      priority: json['priority'] as String?,
      estimateCost: json['estimate_cost'] as num?,
      finalCost: json['final_cost'] as num?,
      balanceDue: json['balance_due'] as num?,
      dueDate: json['due_date'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      technicianName: json['technician_name'] as String?,
    );
  }
}

class RepairStatusEvent {
  const RepairStatusEvent({required this.status, required this.createdAt, this.note, this.byName});

  final String status;
  final String? note;
  final String? byName;
  final DateTime createdAt;

  factory RepairStatusEvent.fromJson(Map<String, dynamic> json) {
    return RepairStatusEvent(
      status: json['status'] as String,
      note: json['note'] as String?,
      byName: json['by_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class RepairPartRow {
  const RepairPartRow({required this.id, required this.name, required this.qty, required this.sellPrice});

  final int id;
  final String name;
  final int qty;
  final num sellPrice;

  factory RepairPartRow.fromJson(Map<String, dynamic> json) {
    return RepairPartRow(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      qty: json['qty'] as int? ?? 1,
      sellPrice: json['sell_price'] as num? ?? 0,
    );
  }
}

class RepairNoteRow {
  const RepairNoteRow({required this.id, required this.note, required this.createdAt, this.userName});

  final int id;
  final String note;
  final String? userName;
  final DateTime createdAt;

  factory RepairNoteRow.fromJson(Map<String, dynamic> json) {
    return RepairNoteRow(
      id: json['id'] as int,
      note: json['note'] as String? ?? '',
      userName: json['user_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class RepairJobDetail {
  const RepairJobDetail({
    required this.summary,
    required this.history,
    required this.parts,
    required this.notes,
    this.customerEmail,
    this.brandName,
    this.reportedIssue,
    this.advancePaid,
    this.warrantyDays,
  });

  final RepairJobSummary summary;
  final List<RepairStatusEvent> history;
  final List<RepairPartRow> parts;
  final List<RepairNoteRow> notes;
  final String? customerEmail;
  final String? brandName;
  final String? reportedIssue;
  final num? advancePaid;
  final int? warrantyDays;

  factory RepairJobDetail.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>;
    return RepairJobDetail(
      summary: RepairJobSummary.fromJson(job),
      history: (json['history'] as List).map((e) => RepairStatusEvent.fromJson(e as Map<String, dynamic>)).toList(),
      parts: (json['parts'] as List).map((e) => RepairPartRow.fromJson(e as Map<String, dynamic>)).toList(),
      notes: (json['notes'] as List).map((e) => RepairNoteRow.fromJson(e as Map<String, dynamic>)).toList(),
      customerEmail: job['customer_email'] as String?,
      brandName: job['brand_name'] as String?,
      reportedIssue: job['reported_issue'] as String?,
      advancePaid: job['advance_paid'] as num?,
      warrantyDays: job['warranty_days'] as int?,
    );
  }
}

/// Statuses match the repair_statuses table slugs used across the web app
/// (Repair Settings -> Statuses). Kept as a flat list here rather than
/// fetched from the API since Phase 1 doesn't expose a statuses endpoint.
const repairStatusOptions = <String>[
  'received',
  'diagnosing',
  'waiting_parts',
  'repairing',
  'ready',
  'delivered',
  'cancelled',
];

class TechnicianOption {
  const TechnicianOption({required this.id, required this.name});
  final int id;
  final String name;

  factory TechnicianOption.fromJson(Map<String, dynamic> json) =>
      TechnicianOption(id: json['id'] as int, name: json['name'] as String? ?? '');
}

class BrandOption {
  const BrandOption({required this.id, required this.name});
  final int id;
  final String name;

  factory BrandOption.fromJson(Map<String, dynamic> json) =>
      BrandOption(id: json['id'] as int, name: json['name'] as String? ?? '');
}

class LabeledOption {
  const LabeledOption({required this.id, required this.label, this.icon});
  final int id;
  final String label;
  final String? icon;

  factory LabeledOption.fromJson(Map<String, dynamic> json) => LabeledOption(
        id: json['id'] as int,
        label: json['label'] as String? ?? '',
        icon: json['icon'] as String?,
      );
}

class RepairFormData {
  const RepairFormData({
    required this.technicians,
    required this.brands,
    required this.deviceConditions,
    required this.checklistItems,
    required this.appleBrandIds,
    this.techAssignApple,
    this.techAssignAndroid,
  });

  final List<TechnicianOption> technicians;
  final List<BrandOption> brands;
  final List<LabeledOption> deviceConditions;
  final List<LabeledOption> checklistItems;
  final List<int> appleBrandIds;
  final int? techAssignApple;
  final int? techAssignAndroid;

  factory RepairFormData.fromJson(Map<String, dynamic> json) {
    return RepairFormData(
      technicians: (json['technicians'] as List).map((e) => TechnicianOption.fromJson(e as Map<String, dynamic>)).toList(),
      brands: (json['brands'] as List).map((e) => BrandOption.fromJson(e as Map<String, dynamic>)).toList(),
      deviceConditions:
          (json['device_conditions'] as List).map((e) => LabeledOption.fromJson(e as Map<String, dynamic>)).toList(),
      checklistItems:
          (json['checklist_items'] as List).map((e) => LabeledOption.fromJson(e as Map<String, dynamic>)).toList(),
      appleBrandIds: (json['apple_brand_ids'] as List? ?? []).map((e) => (e as num).toInt()).toList(),
      techAssignApple:  json['tech_assign_apple']   as int?,
      techAssignAndroid: json['tech_assign_android'] as int?,
    );
  }
}

/// Local builder state for the "New Repair Job" intake form.
class NewRepairJobState {
  const NewRepairJobState({
    this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    this.technicianId,
    this.brandId,
    this.deviceModel = '',
    this.imei = '',
    this.color = '',
    this.deviceCondition,
    this.checklist = const [],
    this.devicePassword = '',
    this.reportedIssue = '',
    this.priority = 'normal',
    this.estimateCost = 0,
    this.advancePaid = 0,
    this.warrantyDays = 0,
    this.dueDate,
    this.notes = '',
    this.isSubmitting = false,
  });

  final int? customerId;
  final String customerName;
  final String customerPhone;
  final int? technicianId;
  final int? brandId;
  final String deviceModel;
  final String imei;
  final String color;
  final String? deviceCondition;
  final List<String> checklist;
  final String devicePassword;
  final String reportedIssue;
  final String priority;
  final num estimateCost;
  final num advancePaid;
  final int warrantyDays;
  final DateTime? dueDate;
  final String notes;
  final bool isSubmitting;

  num get balanceDue => (estimateCost - advancePaid).clamp(0, double.infinity);

  NewRepairJobState copyWith({
    int? customerId,
    String? customerName,
    String? customerPhone,
    int? technicianId,
    int? brandId,
    String? deviceModel,
    String? imei,
    String? color,
    String? deviceCondition,
    List<String>? checklist,
    String? devicePassword,
    String? reportedIssue,
    String? priority,
    num? estimateCost,
    num? advancePaid,
    int? warrantyDays,
    DateTime? dueDate,
    String? notes,
    bool? isSubmitting,
  }) {
    return NewRepairJobState(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      technicianId: technicianId ?? this.technicianId,
      brandId: brandId ?? this.brandId,
      deviceModel: deviceModel ?? this.deviceModel,
      imei: imei ?? this.imei,
      color: color ?? this.color,
      deviceCondition: deviceCondition ?? this.deviceCondition,
      checklist: checklist ?? this.checklist,
      devicePassword: devicePassword ?? this.devicePassword,
      reportedIssue: reportedIssue ?? this.reportedIssue,
      priority: priority ?? this.priority,
      estimateCost: estimateCost ?? this.estimateCost,
      advancePaid: advancePaid ?? this.advancePaid,
      warrantyDays: warrantyDays ?? this.warrantyDays,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

const repairPriorityOptions = <String>['normal', 'high', 'urgent'];
