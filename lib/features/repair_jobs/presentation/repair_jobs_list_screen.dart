import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_colors.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/repair_job.dart';
import '../domain/repair_jobs_controller.dart';

class RepairJobsListScreen extends ConsumerStatefulWidget {
  const RepairJobsListScreen({super.key});

  @override
  ConsumerState<RepairJobsListScreen> createState() => _RepairJobsListScreenState();
}

class _RepairJobsListScreenState extends ConsumerState<RepairJobsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
        ref.read(repairJobsListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repairJobsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.read(repairJobsListProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search job #, device, IMEI, customer...',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => ref.read(repairJobsListProvider.notifier).setSearch(v.trim()),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip(context, '', 'All'),
                for (final s in repairStatusOptions) _filterChip(context, s, statusLabel(s)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(state)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/repair-jobs/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(BuildContext context, String value, String label) {
    final state = ref.watch(repairJobsListProvider);
    final selected = state.status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => ref.read(repairJobsListProvider.notifier).setStatusFilter(value),
      ),
    );
  }

  Widget _buildBody(RepairJobsListState state) {
    if (state.isLoading && state.jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.jobs.isEmpty) {
      return Center(child: Text('Failed to load: ${state.error}'));
    }
    if (state.jobs.isEmpty) {
      return const Center(child: Text('No repair jobs found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(repairJobsListProvider.notifier).load(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: state.jobs.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.jobs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final job = state.jobs[index];
          return _RepairJobCard(job: job);
        },
      ),
    );
  }
}

class _RepairJobCard extends StatelessWidget {
  const _RepairJobCard({required this.job});

  final RepairJobSummary job;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/repair-jobs/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(job.jobNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  StatusChip.status(job.status, repairStatusColor(job.status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(job.deviceModel ?? '-', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                job.customerName ?? 'Unknown',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Balance: ${formatMoney(job.balanceDue)}', style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  if (job.technicianName != null)
                    Text(job.technicianName!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
