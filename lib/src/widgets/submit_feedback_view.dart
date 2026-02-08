import 'package:flutter/widgets.dart';

import '../api/feedback_api.dart';
import '../models/feedback.dart' show FeedbackItem;
import '../models/feedback_category.dart';
import '../state/feedbackkit_provider.dart';
import '../theme/feedbackkit_theme.dart';

/// A form for submitting new feedback.
class SubmitFeedbackView extends StatefulWidget {
  /// Callback when feedback is successfully submitted.
  final void Function(FeedbackItem)? onSubmitted;

  /// Callback when the user cancels.
  final VoidCallback? onCancel;

  /// Optional initial category selection.
  final FeedbackCategory? initialCategory;

  /// Optional custom theme (uses provider theme by default).
  final FeedbackKitTheme? theme;

  const SubmitFeedbackView({
    super.key,
    this.onSubmitted,
    this.onCancel,
    this.initialCategory,
    this.theme,
  });

  @override
  State<SubmitFeedbackView> createState() => _SubmitFeedbackViewState();
}

class _SubmitFeedbackViewState extends State<SubmitFeedbackView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  late FeedbackCategory _selectedCategory;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? FeedbackCategory.featureRequest;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final email = _emailController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _error = 'Please enter a title';
      });
      return;
    }

    if (description.isEmpty) {
      setState(() {
        _error = 'Please enter a description';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final context = FeedbackKitProvider.of(this.context);
      final feedback = await context.client.feedback.create(
        CreateFeedbackRequest(
          title: title,
          description: description,
          category: _selectedCategory,
          email: email.isNotEmpty ? email : null,
        ),
      );

      if (mounted) {
        widget.onSubmitted?.call(feedback);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ??
        FeedbackKitProvider.maybeOf(context)?.theme ??
        const FeedbackKitTheme();

    return Container(
      color: theme.backgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(theme.spacing * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Submit Feedback',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: theme.spacing * 3),

            // Category selector
            Text(
              'Category',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: theme.spacing),
            _buildCategorySelector(theme),
            SizedBox(height: theme.spacing * 2),

            // Title input
            Text(
              'Title',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: theme.spacing),
            _buildTextField(
              theme,
              controller: _titleController,
              placeholder: 'Brief summary of your feedback',
              maxLines: 1,
            ),
            SizedBox(height: theme.spacing * 2),

            // Description input
            Text(
              'Description',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: theme.spacing),
            _buildTextField(
              theme,
              controller: _descriptionController,
              placeholder: 'Provide more details about your feedback',
              maxLines: 5,
            ),
            SizedBox(height: theme.spacing * 2),

            // Email input (optional)
            Text(
              'Email (optional)',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: theme.spacing / 2),
            Text(
              'Get notified when there are updates',
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 12,
              ),
            ),
            SizedBox(height: theme.spacing),
            _buildTextField(
              theme,
              controller: _emailController,
              placeholder: 'your@email.com',
              maxLines: 1,
            ),
            SizedBox(height: theme.spacing * 3),

            // Error message
            if (_error != null) ...[
              Container(
                padding: EdgeInsets.all(theme.spacing),
                decoration: BoxDecoration(
                  color: theme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(theme.borderRadius / 2),
                  border: Border.all(color: theme.errorColor.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: theme.errorColor,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(height: theme.spacing * 2),
            ],

            // Buttons
            Row(
              children: [
                if (widget.onCancel != null) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onCancel,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: theme.spacing * 1.5),
                        decoration: BoxDecoration(
                          color: theme.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(theme.borderRadius / 2),
                          border: Border.all(color: theme.borderColor),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: theme.spacing * 2),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: _isSubmitting ? null : _submit,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isSubmitting ? 0.5 : 1.0,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: theme.spacing * 1.5),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(theme.borderRadius / 2),
                        ),
                        child: Text(
                          _isSubmitting ? 'Submitting...' : 'Submit',
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(FeedbackKitTheme theme) {
    return Wrap(
      spacing: theme.spacing,
      runSpacing: theme.spacing,
      children: FeedbackCategory.values.map((category) {
        final isSelected = category == _selectedCategory;
        final color = theme.categoryColors.forCategory(category);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing * 1.5,
              vertical: theme.spacing,
            ),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(theme.borderRadius / 2),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
              ),
            ),
            child: Text(
              category.displayName,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFFFFF) : color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(
    FeedbackKitTheme theme, {
    required TextEditingController controller,
    required String placeholder,
    required int maxLines,
  }) {
    return Container(
      padding: EdgeInsets.all(theme.spacing * 1.5),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(theme.borderRadius / 2),
        border: Border.all(color: theme.borderColor),
      ),
      child: EditableText(
        controller: controller,
        focusNode: FocusNode(),
        style: TextStyle(
          color: theme.textColor,
          fontSize: 14,
        ),
        cursorColor: theme.primaryColor,
        backgroundCursorColor: theme.borderColor,
        maxLines: maxLines,
      ),
    );
  }
}
