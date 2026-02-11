import 'package:flutter/widgets.dart';

import '../api/feedback_api.dart';
import '../i18n/feedbackkit_localizations.dart';
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
  bool _subscribeToMailingList = false;
  bool _operationalEmails = true;
  bool _marketingEmails = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? FeedbackCategory.featureRequest;
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    // Rebuild when email transitions between empty and non-empty
    setState(() {
      if (_emailController.text.trim().isEmpty) {
        _subscribeToMailingList = false;
        _operationalEmails = true;
        _marketingEmails = true;
      }
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
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
        _error = FeedbackKitLocalizations.t('feedback.form.title.error');
      });
      return;
    }

    if (description.isEmpty) {
      setState(() {
        _error = FeedbackKitLocalizations.t('feedback.form.description.error');
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final context = FeedbackKitProvider.of(this.context);
      List<String>? emailTypes;
      if (_subscribeToMailingList && email.isNotEmpty) {
        emailTypes = [
          if (_operationalEmails) 'operational',
          if (_marketingEmails) 'marketing',
        ];
        if (emailTypes.isEmpty) emailTypes = null;
      }

      final feedback = await context.client.feedback.create(
        CreateFeedbackRequest(
          title: title,
          description: description,
          category: _selectedCategory,
          email: email.isNotEmpty ? email : null,
          subscribeToMailingList:
              email.isNotEmpty ? _subscribeToMailingList : null,
          mailingListEmailTypes: emailTypes,
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
              FeedbackKitLocalizations.t('feedback.submit.title'),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: theme.spacing * 3),

            // Category selector
            Text(
              FeedbackKitLocalizations.t('feedback.form.category'),
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
              FeedbackKitLocalizations.t('feedback.form.title'),
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
              placeholder: FeedbackKitLocalizations.t('feedback.form.title.placeholder'),
              maxLines: 1,
            ),
            SizedBox(height: theme.spacing * 2),

            // Description input
            Text(
              FeedbackKitLocalizations.t('feedback.form.description'),
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
              placeholder: FeedbackKitLocalizations.t('feedback.form.description.placeholder'),
              maxLines: 5,
            ),
            SizedBox(height: theme.spacing * 2),

            // Email input (optional)
            Text(
              FeedbackKitLocalizations.t('feedback.form.email'),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: theme.spacing / 2),
            Text(
              FeedbackKitLocalizations.t('feedback.form.email.description'),
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

            // Mailing list opt-in (visible only when email is non-empty)
            if (_emailController.text.trim().isNotEmpty) ...[
              SizedBox(height: theme.spacing * 1.5),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _subscribeToMailingList = !_subscribeToMailingList;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _subscribeToMailingList
                            ? theme.primaryColor
                            : theme.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _subscribeToMailingList
                              ? theme.primaryColor
                              : theme.borderColor,
                        ),
                      ),
                      child: _subscribeToMailingList
                          ? const Center(
                              child: Text(
                                '\u2713',
                                style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: theme.spacing),
                    Expanded(
                      child: Text(
                        FeedbackKitLocalizations.t('feedback.form.mailingList'),
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Email type sub-checkboxes (progressive disclosure)
              if (_subscribeToMailingList) ...[
                SizedBox(height: theme.spacing),
                Padding(
                  padding: EdgeInsets.only(left: 20.0 + theme.spacing),
                  child: Column(
                    children: [
                      _buildSubCheckbox(
                        label: FeedbackKitLocalizations.t('feedback.form.mailingList.operational'),
                        value: _operationalEmails,
                        onChanged: (v) => setState(() => _operationalEmails = v),
                        theme: theme,
                      ),
                      SizedBox(height: theme.spacing * 0.5),
                      _buildSubCheckbox(
                        label: FeedbackKitLocalizations.t('feedback.form.mailingList.marketing'),
                        value: _marketingEmails,
                        onChanged: (v) => setState(() => _marketingEmails = v),
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
                          FeedbackKitLocalizations.t('button.cancel'),
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
                          _isSubmitting ? FeedbackKitLocalizations.t('feedback.submit.submitting') : FeedbackKitLocalizations.t('feedback.submit.button'),
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

  Widget _buildSubCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required FeedbackKitTheme theme,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: value ? theme.primaryColor : theme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: value ? theme.primaryColor : theme.borderColor,
              ),
            ),
            child: value
                ? const Center(
                    child: Text(
                      '\u2713',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: theme.spacing * 0.75),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
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
