import 'package:flutter/material.dart';
import '../../../../../constants/app_strings.dart';
import '../../../../../constants/app_theme.dart';
import '../../../../../utils/week_utils.dart';

class AddPlanDialog extends StatefulWidget {
  final List<String> weekDays;
  final int year;
  final int weekNumber;
  final Map<String, DateTime> weekDates;
  final Future<void> Function({
    required String title,
    required String description,
    required String dayOfWeek,
  }) onSave;

  const AddPlanDialog({
    super.key,
    required this.weekDays,
    required this.year,
    required this.weekNumber,
    required this.weekDates,
    required this.onSave,
  });

  @override
  State<AddPlanDialog> createState() => _AddPlanDialogState();
}

class _AddPlanDialogState extends State<AddPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedDay;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.weeklyPlanDayRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await widget.onSave(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dayOfWeek: _selectedDay!,
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '${AppStrings.weeklyPlanDialogTitle} - ${AppStrings.format(AppStrings.weeklyPlanWeekFormat, [widget.weekNumber.toString(), widget.year.toString()])}',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppStrings.weeklyPlanTitleLabel,
                  hintText: AppStrings.weeklyPlanTitleHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.weeklyPlanTitleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.marginMedium),
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: AppStrings.weeklyPlanDescriptionLabel,
                  hintText: AppStrings.weeklyPlanDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.marginMedium),
              // Day dropdown with dates
              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                decoration: InputDecoration(
                  labelText: AppStrings.weeklyPlanDateLabel,
                  border: const OutlineInputBorder(),
                ),
                hint: Text(AppStrings.weeklyPlanSelectDay),
                items: widget.weekDays.map((day) {
                  final date = widget.weekDates[day]!;
                  return DropdownMenuItem(
                    value: day,
                    child: Text('$day - ${WeekUtils.formatDate(date)}'),
                  );
                }).toList(),
                onChanged: (value) {
                    _selectedDay = value;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.weeklyPlanCancelButton),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              ) 
            : Text(AppStrings.weeklyPlanSaveButton),
        ),
      ],
    );
  }
}
