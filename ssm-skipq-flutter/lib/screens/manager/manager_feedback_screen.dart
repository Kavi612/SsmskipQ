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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_feedback.length} review${_feedback.length == 1 ? '' : 's'}'),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else if (_feedback.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No feedback yet. Reviews appear after students collect orders.'),
            )
          else
            ..._feedback.map(
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
}
