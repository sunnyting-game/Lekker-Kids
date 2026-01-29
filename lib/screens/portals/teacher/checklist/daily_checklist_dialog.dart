import 'package:flutter/material.dart';
import '../../../../repositories/checklist_repository.dart';
import '../../../../models/checklist_template_model.dart';
import '../../../../models/checklist_record_model.dart';
import '../../../../constants/app_strings.dart';

/// Dialog for viewing and editing daily checklists with template selection
class DailyChecklistDialog extends StatefulWidget {
  final String date;
  final List<ChecklistTemplateModel> templates;
  final List<ChecklistRecordModel> existingRecords;
  final String schoolId;
  final String organizationId;
  final bool isReadOnly;

  const DailyChecklistDialog({
    super.key,
    required this.date,
    required this.templates,
    required this.existingRecords,
    required this.schoolId,
    required this.organizationId,
    required this.isReadOnly,
  });

  @override
  State<DailyChecklistDialog> createState() => _DailyChecklistDialogState();
}

class _DailyChecklistDialogState extends State<DailyChecklistDialog> {
  final ChecklistRepository _repository = ChecklistRepository();
  
  late ChecklistTemplateModel _selectedTemplate;
  late Map<String, bool> _completedItems;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Map of templateId -> existing record for this day
  late Map<String, ChecklistRecordModel> _recordsByTemplateId;

  @override
  void initState() {
    super.initState();
    
    // Build lookup for existing records
    _recordsByTemplateId = {
      for (var r in widget.existingRecords) r.templateId: r
    };

    // Default to first template
    _selectedTemplate = widget.templates.first;
    _loadItemsForTemplate(_selectedTemplate);
  }

  void _loadItemsForTemplate(ChecklistTemplateModel template) {
    final existingRecord = _recordsByTemplateId[template.id];
    _completedItems = Map.from(existingRecord?.completedItems ?? {});
    
    // Ensure all template items are in the map
    for (var item in template.items) {
      _completedItems.putIfAbsent(item.id, () => false);
    }
    _hasChanges = false;
  }

  bool get _allCompleted => _selectedTemplate.items.every(
    (item) => _completedItems[item.id] == true,
  );

  String get _formattedDate {
    final parts = widget.date.split('-');
    if (parts.length == 3) {
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = int.tryParse(parts[1]) ?? 1;
      return '${monthNames[month - 1]} ${parts[2]}, ${parts[0]}';
    }
    return widget.date;
  }

  bool get _currentRecordIsSubmitted {
    final record = _recordsByTemplateId[_selectedTemplate.id];
    return record?.isSubmitted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentTemplateReadOnly = widget.isReadOnly || _currentRecordIsSubmitted;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${AppStrings.checklistDialogTitle} - $_formattedDate',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          if (isCurrentTemplateReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                AppStrings.checklistReadOnly,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          if (_allCompleted && !isCurrentTemplateReadOnly)
            Icon(Icons.check_circle, color: Colors.green.shade600),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template selector (only show if multiple templates)
            if (widget.templates.length > 1) ...[
              Row(
                children: [
                  const Text(AppStrings.checklistSelectTemplate),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedTemplate.id,
                      isExpanded: true,
                      items: widget.templates.map((t) {
                        final record = _recordsByTemplateId[t.id];
                        final isComplete = record?.isCompleted ?? false;
                        return DropdownMenuItem(
                          value: t.id,
                          child: Row(
                            children: [
                              Expanded(child: Text(t.name)),
                              if (isComplete)
                                Icon(Icons.check_circle, 
                                  size: 16, 
                                  color: Colors.green.shade600),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: isCurrentTemplateReadOnly ? null : (templateId) {
                        if (templateId != null) {
                          final template = widget.templates
                              .firstWhere((t) => t.id == templateId);
                          setState(() {
                            _selectedTemplate = template;
                            _loadItemsForTemplate(template);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Show template name for single template
              Text(
                _selectedTemplate.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
            ],

            if (_allCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        AppStrings.checklistAllCompleted,
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),

            // Checklist items
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _selectedTemplate.items.length,
                itemBuilder: (context, index) {
                  final item = _selectedTemplate.items[index];
                  final isChecked = _completedItems[item.id] ?? false;

                  return CheckboxListTile(
                    title: Text(item.label),
                    value: isChecked,
                    onChanged: isCurrentTemplateReadOnly
                        ? null
                        : (value) => _toggleItem(item.id, value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isCurrentTemplateReadOnly 
              ? AppStrings.checklistClose 
              : AppStrings.checklistCancel),
        ),
        if (!isCurrentTemplateReadOnly)
          FilledButton(
            onPressed: _isSaving || !_hasChanges ? null : _saveChecklist,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.checklistSave),
          ),
      ],
    );
  }

  void _toggleItem(String itemId, bool value) {
    setState(() {
      _completedItems[itemId] = value;
      _hasChanges = true;
    });
  }

  Future<void> _saveChecklist() async {
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final existingRecord = _recordsByTemplateId[_selectedTemplate.id];
      
      final record = ChecklistRecordModel(
        id: ChecklistRecordModel.generateId(
          widget.schoolId, 
          _selectedTemplate.id, 
          widget.date,
        ),
        schoolId: widget.schoolId,
        organizationId: widget.organizationId,
        templateId: _selectedTemplate.id,
        templateName: _selectedTemplate.name,
        date: widget.date,
        month: ChecklistRecordModel.extractMonth(widget.date),
        completedItems: Map.from(_completedItems),
        isCompleted: _allCompleted,
        isSubmitted: false,
        createdAt: existingRecord?.createdAt ?? now,
        updatedAt: now,
      );

      await _repository.saveRecord(record, _selectedTemplate);

      // Update local cache
      _recordsByTemplateId[_selectedTemplate.id] = record;

      if (mounted) {
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.checklistSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.checklistSaveError}: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}
