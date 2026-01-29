import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/checklist_repository.dart';
import '../../../models/checklist_template_model.dart';
import '../../../models/checklist_record_model.dart';
import '../../../constants/app_strings.dart';

/// Checklist tab showing today's checklist first with calendar button for date selection
class ChecklistTab extends StatefulWidget {
  const ChecklistTab({super.key});

  @override
  State<ChecklistTab> createState() => _ChecklistTabState();
}

class _ChecklistTabState extends State<ChecklistTab> {
  final ChecklistRepository _repository = ChecklistRepository();
  
  // Selected date (defaults to today)
  DateTime _selectedDate = DateTime.now();
  
  // Currently selected template
  ChecklistTemplateModel? _selectedTemplate;
  
  // Completed items map for current template
  Map<String, bool> _completedItems = {};
  
  // Save state
  bool _isSaving = false;
  bool _hasChanges = false;
  
  // Track what we've loaded to avoid reloading on every stream update
  String? _loadedTemplateId;
  String? _loadedDate;
  
  // Cache for existing records by template ID
  Map<String, ChecklistRecordModel> _recordsByTemplateId = {};

  String get _dateString {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  String get _formattedDate {
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${monthNames[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  bool get _allCompleted {
    if (_selectedTemplate == null) return false;
    return _selectedTemplate!.items.every(
      (item) => _completedItems[item.id] == true,
    );
  }

  bool get _currentRecordIsSubmitted {
    if (_selectedTemplate == null) return false;
    final record = _recordsByTemplateId[_selectedTemplate!.id];
    return record?.isSubmitted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null || user.schoolIds.isEmpty || user.organizationId == null) {
      return const Center(
        child: Text('Not assigned to a dayhome'),
      );
    }

    final schoolId = user.schoolIds.first;
    final organizationId = user.organizationId!;

    return Column(
      children: [
        // Date header with calendar button
        _buildDateHeader(context),
        
        const Divider(height: 1),
        
        // Checklist content
        Expanded(
          child: StreamBuilder<List<ChecklistTemplateModel>>(
            stream: _repository.getTemplatesStream(organizationId),
            builder: (context, templatesSnapshot) {
              if (templatesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final templates = templatesSnapshot.data ?? [];
              if (templates.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checklist, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        AppStrings.checklistNoTemplate,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppStrings.checklistContactAdmin,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // Initialize selected template if not set or if current template no longer exists
              if (_selectedTemplate == null || !templates.any((t) => t.id == _selectedTemplate!.id)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedTemplate = templates.first;
                      // Force reload for new template
                      _loadedTemplateId = null;
                      _loadedDate = null;
                    });
                  }
                });
              }

              return StreamBuilder<List<ChecklistRecordModel>>(
                stream: _repository.getRecordsForDateStream(schoolId, _dateString),
                builder: (context, recordsSnapshot) {
                  final records = recordsSnapshot.data ?? [];
                  
                  // Update records cache
                  _recordsByTemplateId = {
                    for (var r in records) r.templateId: r
                  };

                  // Only load items if template or date changed (not on every stream update)
                  if (_selectedTemplate != null) {
                    final needsReload = _loadedTemplateId != _selectedTemplate!.id || 
                                        _loadedDate != _dateString;
                    if (needsReload) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _loadItemsForTemplate(_selectedTemplate!);
                          setState(() {
                            _loadedTemplateId = _selectedTemplate!.id;
                            _loadedDate = _dateString;
                          });
                        }
                      });
                    }
                  }

                  return _buildChecklistContent(
                    templates: templates,
                    records: records,
                    schoolId: schoolId,
                    organizationId: organizationId,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final isToday = _isToday(_selectedDate);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formattedDate,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (isToday)
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Date',
            onPressed: () => _showDatePicker(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistContent({
    required List<ChecklistTemplateModel> templates,
    required List<ChecklistRecordModel> records,
    required String schoolId,
    required String organizationId,
  }) {
    if (_selectedTemplate == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isReadOnly = _currentRecordIsSubmitted;
    final isFutureDate = _selectedDate.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template selector (only show if multiple templates)
          if (templates.length > 1) ...[
            Row(
              children: [
                const Text(AppStrings.checklistSelectTemplate),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedTemplate!.id,
                    isExpanded: true,
                    items: templates.map((t) {
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
                    onChanged: isReadOnly ? null : (templateId) {
                      if (templateId != null) {
                        final template = templates.firstWhere((t) => t.id == templateId);
                        setState(() {
                          _selectedTemplate = template;
                          // Force reload for new template
                          _loadedTemplateId = null;
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
              _selectedTemplate!.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
          ],

          // Read-only or future date badge
          if (isReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                AppStrings.checklistReadOnly,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

          if (isFutureDate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Future date - read only',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),

          // All completed banner
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
          Expanded(
            child: ListView.builder(
              itemCount: _selectedTemplate!.items.length,
              itemBuilder: (context, index) {
                final item = _selectedTemplate!.items[index];
                final isChecked = _completedItems[item.id] ?? false;

                return CheckboxListTile(
                  title: Text(item.label),
                  value: isChecked,
                  onChanged: (isReadOnly || isFutureDate)
                      ? null
                      : (value) => _toggleItem(item.id, value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ),

          // Save button
          if (!isReadOnly && !isFutureDate)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving || !_hasChanges 
                      ? null 
                      : () => _saveChecklist(schoolId, organizationId),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.checklistSave),
                ),
              ),
            ),
        ],
      ),
    );
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

  void _toggleItem(String itemId, bool value) {
    setState(() {
      _completedItems[itemId] = value;
      _hasChanges = true;
    });
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hasChanges = false;
        // Force reload for new date
        _loadedDate = null;
        _completedItems = {};
      });
    }
  }

  Future<void> _saveChecklist(String schoolId, String organizationId) async {
    if (_selectedTemplate == null) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final existingRecord = _recordsByTemplateId[_selectedTemplate!.id];
      
      final record = ChecklistRecordModel(
        id: ChecklistRecordModel.generateId(
          schoolId, 
          _selectedTemplate!.id, 
          _dateString,
        ),
        schoolId: schoolId,
        organizationId: organizationId,
        templateId: _selectedTemplate!.id,
        templateName: _selectedTemplate!.name,
        date: _dateString,
        month: ChecklistRecordModel.extractMonth(_dateString),
        completedItems: Map.from(_completedItems),
        isCompleted: _allCompleted,
        isSubmitted: false,
        createdAt: existingRecord?.createdAt ?? now,
        updatedAt: now,
      );

      await _repository.saveRecord(record, _selectedTemplate!);

      // Update local cache so UI stays in sync
      _recordsByTemplateId[_selectedTemplate!.id] = record;

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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
