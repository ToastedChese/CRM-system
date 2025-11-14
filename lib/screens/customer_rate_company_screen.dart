import 'package:flutter/material.dart';
import '../data/supabase_service.dart';

class CustomerRateCompanyScreen extends StatefulWidget {
  const CustomerRateCompanyScreen({super.key});

  @override
  State<CustomerRateCompanyScreen> createState() =>
      _CustomerRateCompanyScreenState();
}

class _CustomerRateCompanyScreenState extends State<CustomerRateCompanyScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  int _stars = 0;
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await SupabaseService.createCompanyRating(
        stars: _stars,
        comment: _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback!')),
      );
      Navigator.of(context).pop(true); // return success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit rating: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Our Service'),
        backgroundColor: mainBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('How was your experience?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(5, (i) {
                final idx = i + 1;
                final filled = idx <= _stars;
                return IconButton(
                  iconSize: 36,
                  onPressed: () => setState(() => _stars = idx),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Comments (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: mainBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
