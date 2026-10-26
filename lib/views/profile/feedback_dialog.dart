import 'package:flutter/material.dart';
import '../../utils/bl_colors.dart';
import '../widgets/bl_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  bool _anonymous = false;

  static const _words = ['', 'Very poor', 'Poor', 'OK', 'Good', 'Excellent'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: BL.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Rate your experience',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final on = i < _rating;
                  return IconButton(
                    tooltip: '${i + 1} star${i == 0 ? '' : 's'}',
                    constraints:
                        const BoxConstraints(minWidth: 52, minHeight: 52),
                    onPressed: () => setState(() => _rating = i + 1),
                    icon: Icon(
                        on ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 40,
                        color: on ? BL.link : const Color(0xFFB5ABAC)),
                  );
                }),
              ),
              if (_rating > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                      '$_rating star${_rating == 1 ? '' : 's'}: ${_words[_rating]}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: BL.link)),
                ),
              TextField(
                controller: _commentController,
                maxLines: 4,
                style: const TextStyle(fontSize: 17),
                decoration: InputDecoration(
                  hintText: 'Tell us what you think...',
                  filled: true,
                  fillColor: BL.fill,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: BL.hairline, width: 1.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: BL.hairline, width: 1.5)),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _anonymous = !_anonymous),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Icon(
                          _anonymous
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 26,
                          color: _anonymous ? BL.link : BL.muted),
                      const SizedBox(width: 10),
                      const Text('Send as Anonymous',
                          style: TextStyle(fontSize: 17)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              BlPrimaryButton(
                label: _isSubmitting ? 'Sending...' : 'Submit Feedback',
                color: BL.crimson,
                onTap: _isSubmitting ? null : _submitFeedback,
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                    foregroundColor: BL.muted,
                    minimumSize: const Size(0, 48),
                    textStyle:
                        const TextStyle(fontFamily: 'Outfit', fontSize: 16)),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a star rating")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _anonymous
          ? null
          : Provider.of<AuthService>(context, listen: false).currentUser;

      String userName = user?.displayName ?? 'Anonymous';
      if (userName == 'Anonymous' && user != null) {
        // Try fetching from DB
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          userName = data?['displayName'] ?? data?['name'] ?? 'Anonymous';
        }
      }

      await FirebaseFirestore.instance.collection('feedback').add({
        'userId': user?.uid ?? 'anonymous',
        'userName': userName,
        'userEmail': user?.email ?? 'N/A',
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'web', // or 'app'
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Thank you for your feedback!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error submitting feedback: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
