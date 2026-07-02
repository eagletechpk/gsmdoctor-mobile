import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/repair_job_repository.dart';
import 'repair_job.dart';

final repairJobRepositoryProvider =
    Provider<RepairJobRepository>((ref) => RepairJobRepository(ref.watch(dioProvider)));

class RepairJobsListState {
  const RepairJobsListState({
    this.jobs = const [],
    this.status = '',
    this.search = '',
    this.page = 1,
    this.lastPage = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  final List<RepairJobSummary> jobs;
  final String status;
  final String search;
  final int page;
  final int lastPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => page < lastPage;

  RepairJobsListState copyWith({
    List<RepairJobSummary>? jobs,
    String? status,
    String? search,
    int? page,
    int? lastPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return RepairJobsListState(
      jobs: jobs ?? this.jobs,
      status: status ?? this.status,
      search: search ?? this.search,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// Backs the repair jobs list screen: filter state + paginated fetch, mirrors
/// RepairController::index()'s status/search query params.
class RepairJobsListController extends Notifier<RepairJobsListState> {
  @override
  RepairJobsListState build() {
    Future.microtask(() => load());
    return const RepairJobsListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref.read(repairJobRepositoryProvider).list(
            status: state.status,
            search: state.search,
            page: 1,
          );
      state = state.copyWith(
        jobs: result.jobs,
        page: result.page,
        lastPage: result.lastPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await ref.read(repairJobRepositoryProvider).list(
            status: state.status,
            search: state.search,
            page: state.page + 1,
          );
      state = state.copyWith(
        jobs: [...state.jobs, ...result.jobs],
        page: result.page,
        lastPage: result.lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void setStatusFilter(String status) {
    state = state.copyWith(status: status);
    load();
  }

  void setSearch(String search) {
    state = state.copyWith(search: search);
    load();
  }
}

final repairJobsListProvider =
    NotifierProvider<RepairJobsListController, RepairJobsListState>(RepairJobsListController.new);

final repairJobDetailProvider =
    FutureProvider.family.autoDispose<RepairJobDetail, int>((ref, id) {
  // Re-resolve the user permissions provider so a 401 mid-fetch still routes
  // through the same handleUnauthorized() path as every other API call.
  ref.watch(authControllerProvider);
  return ref.watch(repairJobRepositoryProvider).show(id);
});

final repairFormDataProvider = FutureProvider.autoDispose<RepairFormData>((ref) {
  return ref.watch(repairJobRepositoryProvider).formData();
});

/// Local builder state for the "New Repair Job" intake screen — mirrors
/// NewPurchaseController's pattern (purchases feature): in-memory form state
/// until submit, then cleared.
class NewRepairJobController extends Notifier<NewRepairJobState> {
  @override
  NewRepairJobState build() => const NewRepairJobState();

  void setCustomer({int? id, String name = '', String phone = ''}) =>
      state = NewRepairJobState(
        customerId: id,
        customerName: name,
        customerPhone: phone,
        technicianId: state.technicianId,
        brandId: state.brandId,
        deviceModel: state.deviceModel,
        imei: state.imei,
        color: state.color,
        deviceCondition: state.deviceCondition,
        checklist: state.checklist,
        devicePassword: state.devicePassword,
        reportedIssue: state.reportedIssue,
        priority: state.priority,
        estimateCost: state.estimateCost,
        advancePaid: state.advancePaid,
        warrantyDays: state.warrantyDays,
        dueDate: state.dueDate,
        notes: state.notes,
      );
  void setTechnician(int? id) => state = state.copyWith(technicianId: id);
  void setBrand(int? id) => state = state.copyWith(brandId: id);
  void setDeviceModel(String v) => state = state.copyWith(deviceModel: v);
  void setImei(String v) => state = state.copyWith(imei: v);
  void setColor(String v) => state = state.copyWith(color: v);
  void setDeviceCondition(String? v) => state = state.copyWith(deviceCondition: v);
  void toggleChecklistItem(String label) {
    final list = [...state.checklist];
    if (list.contains(label)) {
      list.remove(label);
    } else {
      list.add(label);
    }
    state = state.copyWith(checklist: list);
  }
  void setDevicePassword(String v) => state = state.copyWith(devicePassword: v);
  void setReportedIssue(String v) => state = state.copyWith(reportedIssue: v);
  void setPriority(String v) => state = state.copyWith(priority: v);
  void setEstimateCost(num v) => state = state.copyWith(estimateCost: v);
  void setAdvancePaid(num v) => state = state.copyWith(advancePaid: v);
  void setWarrantyDays(int v) => state = state.copyWith(warrantyDays: v);
  void setDueDate(DateTime? v) => state = NewRepairJobState(
        customerId: state.customerId,
        customerName: state.customerName,
        customerPhone: state.customerPhone,
        technicianId: state.technicianId,
        brandId: state.brandId,
        deviceModel: state.deviceModel,
        imei: state.imei,
        color: state.color,
        deviceCondition: state.deviceCondition,
        checklist: state.checklist,
        devicePassword: state.devicePassword,
        reportedIssue: state.reportedIssue,
        priority: state.priority,
        estimateCost: state.estimateCost,
        advancePaid: state.advancePaid,
        warrantyDays: state.warrantyDays,
        dueDate: v,
        notes: state.notes,
      );
  void setNotes(String v) => state = state.copyWith(notes: v);

  void clear() => state = const NewRepairJobState();

  Future<RepairJobSummary> submit() async {
    if (state.deviceModel.trim().isEmpty) {
      throw Exception('Device model is required.');
    }
    if (state.customerId == null && state.customerName.trim().isEmpty) {
      throw Exception('Customer name is required for a new customer.');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final result = await ref.read(repairJobRepositoryProvider).store(state);
      clear();
      ref.invalidate(repairJobsListProvider);
      return result;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final newRepairJobProvider = NotifierProvider<NewRepairJobController, NewRepairJobState>(NewRepairJobController.new);
