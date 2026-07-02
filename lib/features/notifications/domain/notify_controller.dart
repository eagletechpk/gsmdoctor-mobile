import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/notify_repository.dart';

final notifyRepoProvider =
    Provider((ref) => NotifyRepository(ref.watch(dioProvider)));

typedef NotifyTemplatesArgs = ({
  String event,
  int? jobId,
  int? dueId,
  int? crmId
});

final notifyTemplatesProvider =
    FutureProvider.autoDispose.family<NotifyTemplatesData, NotifyTemplatesArgs>(
  (ref, args) => ref.watch(notifyRepoProvider).fetchTemplates(
        event: args.event,
        jobId: args.jobId,
        dueId: args.dueId,
        crmId: args.crmId,
      ),
);
