import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/accounts_repository.dart';
import 'account.dart';

final _accountsRepoProvider = Provider((ref) => AccountsRepository(ref.watch(dioProvider)));
final _expensesRepoProvider  = Provider((ref) => ExpensesRepository(ref.watch(dioProvider)));

final accountsProvider = FutureProvider.autoDispose<AccountsPageData>((ref) {
  return ref.watch(_accountsRepoProvider).getAccounts();
});

final expensesProvider = FutureProvider.autoDispose.family<
    ({List<ExpenseRow> expenses, num totalAmount, int lastPage}),
    ({int page, String search, String category})>((ref, params) {
  return ref.watch(_expensesRepoProvider).list(
        page: params.page,
        search: params.search,
        category: params.category,
      );
});

final expenseFormDataProvider = FutureProvider.autoDispose<ExpenseFormData>((ref) {
  return ref.watch(_expensesRepoProvider).formData();
});

final expensesRepoProvider = _expensesRepoProvider;
final accountsRepoProvider  = _accountsRepoProvider;
