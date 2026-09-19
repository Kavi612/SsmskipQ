import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/feedback.dart';
import '../../services/feedback_service.dart';
import '../../utils/helpers.dart';

class ManagerFeedbackScreen extends StatefulWidget {
  const ManagerFeedbackScreen({super.key, required this.feedbackService});

  final FeedbackService feedbackService;

  @override
  State<ManagerFeedbackScreen> createState() => _ManagerFeedbackScreenState();
}

class _ManagerFeedbackScreenState extends State<ManagerFeedbackScreen> {
  List<OrderFeedback> _feedback = [];
  bool _loading = true;
  String? _error;
  int? _ratingFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _feedback = await widget.feedbackService.fetchManagerFeedback();
    } catch (_) {
      _error = 'Unable to load feedback.';
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFeedback = _ratingFilter == null
        ? _feedback
        : _feedback.where((entry) => entry.rating == _ratingFilter).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Feedback', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _ratingSummary(),
          const SizedBox(height: 12),
          _ratingFilters(),
          const SizedBox(height: 12),
          Text('${filteredFeedback.length} review${filteredFeedback.length == 1 ? '' : 's'}'),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else if (filteredFeedback.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No matching feedback found.'),
            )
          else
            ...filteredFeedback.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.order?.tokenNumber ?? 'Order',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < entry.rating ? Icons.star : Icons.star_border,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                      if (entry.review.isNotEmpty) Text(entry.review),
                      if (entry.student != null)
                        Text('${entry.student!.name} · ${entry.student!.mobile}'),
                      Text(formatIstDateTime(entry.createdAt),
                          style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ratingSummary() {
    final total = _feedback.length;
    final average = total == 0
        ? 0.0
        : _feedback.fold<int>(0, (sum, entry) => sum + entry.rating) / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${average.toStringAsFixed(1)} ★', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('from $total review${total == 1 ? '' : 's'}', style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(5, (index) {
            final rating = 5 - index;
            final count = _feedback.where((entry) => entry.rating == rating).length;
            final ratio = total == 0 ? 0.0 : count / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(width: 28, child: Text('$rating★', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: Stack(
                        children: [
                          Container(height: 8, color: Colors.white),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(height: 8, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 24, child: Text('$count', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _ratingFilters() {
    final filters = <({int? rating, String label})>[
      (rating: null, label: 'All'),
      (rating: 5, label: '5★'),
      (rating: 4, label: '4★'),
      (rating: 3, label: '3★'),
      (rating: 2, label: '2★'),
      (rating: 1, label: '1★'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _ratingFilter == filter.rating;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: selected,
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary),
              onSelected: (_) => setState(() => _ratingFilter = filter.rating),
            ),
          );
        }).toList(),
      ),
    );
  }
}
