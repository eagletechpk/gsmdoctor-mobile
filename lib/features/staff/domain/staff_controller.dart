import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_controller.dart';
import '../data/staff_repository.dart';
import 'staff_member.dart';

final staffRepoProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(dioProvider));
});

final staffListProvider = FutureProvider<StaffPageData>((ref) async {
  return ref.watch(staffRepoProvider).getAll();
});

final staffDetailProvider =
    FutureProvider.family<StaffDetail, int>((ref, id) async {
  return ref.watch(staffRepoProvider).getOne(id);
});
