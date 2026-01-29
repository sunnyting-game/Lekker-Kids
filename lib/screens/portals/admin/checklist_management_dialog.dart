import 'package:flutter/material.dart';
import '../../../repositories/checklist_repository.dart';
import '../../../models/checklist_template_model.dart';
import '../../../models/checklist_record_model.dart';
import '../../../constants/app_strings.dart';

/// Dialog for managing checklist templates and viewing records
class ChecklistManagementDialog extends StatefulWidget {
  final String organizationId;
  final String? schoolId;
  final String? schoolName;

  const ChecklistManagementDialog({
    super.key,
    required this.organizationId,
    this.schoolId,
    this.schoolName,
  });

  @override
  State<ChecklistManagementDialog> createState() => _ChecklistManagementDialogState();
}

class _ChecklistManagementDialogState extends State<ChecklistManagementDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChecklistRepository _repository = ChecklistRepository();

  // Records state
  String _selectedMonth = '';
  List<ChecklistRecordModel> _records = [];
  bool _isLoadingRecords = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initSelectedMonth();
  }

  void _initSelectedMonth() {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1);
    _selectedMonth = '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    if (_selectedMonth.isEmpty) return;
    
    setState(() => _isLoadingRecords = true);
    try {
      List<ChecklistRecordModel> records;
      if (widget.schoolId != null) {
        records = await _repository.getSubmittedRecordsForDayhome(
          widget.schoolId!,
          _selectedMonth,
        );
      } else {
        records = await _repository.getSubmittedRecordsForOrg(
          widget.organizationId,
          _selectedMonth,
        );
      }
      records.sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _records = records;
        _isLoadingRecords = false;
      });
    } catch (e) {
      setState(() => _isLoadingRecords = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 550,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.schoolName != null
                        ? '${AppStrings.checklistManagement} - ${widget.schoolName}'
                        : AppStrings.checklistManagement,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              onTap: (index) {
                if (index == 1) _loadRecords();
              },
              tabs: const [
                Tab(text: AppStrings.checklistTemplateTab),
                Tab(text: AppStrings.checklistRecordsTab),
              ],
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTemplatesListTab(),
                  _buildRecordsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesListTab() {
    return StreamBuilder<List<ChecklistTemplateModel>>(
      stream: _repository.getTemplatesStream(widget.organizationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final templates = snapshot.data ?? [];

        return Column(
          children: [
            // Create button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showTemplateEditor(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.checklistCreateNew),
                ),
              ),
            ),
            
            // Templates list
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.checklist, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(AppStrings.checklistNoTemplates),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.checklist),
                            ),
                            title: Text(
                              template.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${template.items.length} ${AppStrings.checklistItems}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showTemplateEditor(context, template),
                                  tooltip: AppStrings.checklistEditItem,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDeleteTemplate(template),
                                  tooltip: AppStrings.checklistDelete,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showTemplateEditor(BuildContext context, ChecklistTemplateModel? template) {
    showDialog(
      context: context,
      builder: (context) => ChecklistTemplateEditorDialog(
        organizationId: widget.organizationId,
        existingTemplate: template,
      ),
    );
  }

  Future<void> _confirmDeleteTemplate(ChecklistTemplateModel template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.checklistDeleteConfirmTitle),
        content: Text('${AppStrings.checklistDeleteConfirm} "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.checklistCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(AppStrings.checklistDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _repository.deleteTemplate(template.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.checklistDeleted} "${template.name}"')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppStrings.checklistSaveError}: $e')),
          );
        }
      }
    }
  }

  Widget _buildRecordsTab() {
    return Column(
      children: [
        // Month selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(AppStrings.checklistSelectMonth),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedMonth,
                items: _buildMonthDropdownItems(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMonth = value);
                    _loadRecords();
                  }
                },
              ),
            ],
          ),
        ),
        
        // Records list
        Expanded(
          child: _isLoadingRecords
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(AppStrings.checklistNoRecords),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        final completedCount = record.completedItems.values
                            .where((v) => v)
                            .length;
                        final totalCount = record.completedItems.length;

                        return ListTile(
                          leading: Icon(
                            record.isCompleted 
                                ? Icons.check_circle 
                                : Icons.radio_button_unchecked,
                            color: record.isCompleted ? Colors.green : Colors.grey,
                          ),
                          title: Text(_formatDate(record.date)),
                          subtitle: Text('${record.templateName} • $completedCount / $totalCount'),
                          trailing: record.isCompleted
                              ? Chip(
                                  label: const Text(AppStrings.checklistCompleted),
                                  backgroundColor: Colors.green.shade100,
                                )
                              : Chip(
                                  label: const Text(AppStrings.checklistIncomplete),
                                  backgroundColor: Colors.orange.shade100,
                                ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildMonthDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    final now = DateTime.now();
    
    for (var i = 1; i <= 12; i++) {
      final month = DateTime(now.year, now.month - i);
      final value = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final label = _formatMonth(value);
      items.add(DropdownMenuItem(value: value, child: Text(label)));
    }
    
    return items;
  }

  String _formatMonth(String month) {
    final parts = month.split('-');
    if (parts.length == 2) {
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final monthIndex = int.tryParse(parts[1]) ?? 1;
      return '${monthNames[monthIndex - 1]} ${parts[0]}';
    }
    return month;
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthIndex = int.tryParse(parts[1]) ?? 1;
      return '${monthNames[monthIndex - 1]} ${parts[2]}, ${parts[0]}';
    }
    return date;
  }
}

/// Dialog for creating or editing a checklist template
class ChecklistTemplateEditorDialog extends StatefulWidget {
  final String organizationId;
  final ChecklistTemplateModel? existingTemplate;

  const ChecklistTemplateEditorDialog({
    super.key,
    required this.organizationId,
    this.existingTemplate,
  });

  @override
  State<ChecklistTemplateEditorDialog> createState() => _ChecklistTemplateEditorDialogState();
}

class _ChecklistTemplateEditorDialogState extends State<ChecklistTemplateEditorDialog> {
  final ChecklistRepository _repository = ChecklistRepository();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  List<ChecklistItem> _items = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingTemplate != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingTemplate?.name ?? '');
    _items = widget.existingTemplate?.items.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 450,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                _isEditing ? AppStrings.checklistEditTemplate : AppStrings.checklistCreateNew,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Template name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.checklistNameLabel,
                  hintText: AppStrings.checklistNameHint,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.checklistNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Items section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.checklistItems} (${_items.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(AppStrings.checklistAddItem),
                  ),
                ],
              ),

              // Items list
              Expanded(
                child: _items.isEmpty
                    ? const Center(
                        child: Text(
                          AppStrings.checklistNoItems,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: _items.length,
                        onReorder: _reorderItems,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(
                            key: ValueKey(item.id),
                            leading: const Icon(Icons.drag_handle),
                            title: Text(item.label),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _removeItem(index),
                            ),
                            onTap: () => _editItem(index),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(AppStrings.checklistCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveTemplate,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? AppStrings.checklistSave : AppStrings.checklistCreateButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addItem() async {
    final label = await _showItemLabelDialog();
    if (label != null && label.isNotEmpty) {
      setState(() {
        _items.add(ChecklistItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          label: label,
          order: _items.length,
        ));
      });
    }
  }

  void _editItem(int index) async {
    final currentLabel = _items[index].label;
    final newLabel = await _showItemLabelDialog(initialValue: currentLabel);
    if (newLabel != null && newLabel.isNotEmpty && newLabel != currentLabel) {
      setState(() {
        _items[index] = _items[index].copyWith(label: newLabel);
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(order: i);
      }
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(order: i);
      }
    });
  }

  Future<String?> _showItemLabelDialog({String? initialValue}) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initialValue == null 
            ? AppStrings.checklistAddItem 
            : AppStrings.checklistEditItem),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: AppStrings.checklistItemLabel,
            hintText: AppStrings.checklistItemHint,
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.checklistCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text(AppStrings.checklistSave),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.checklistNeedItems)),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final now = DateTime.now();
      
      if (_isEditing) {
        final updated = widget.existingTemplate!.copyWith(
          name: _nameController.text.trim(),
          items: _items,
          updatedAt: now,
        );
        await _repository.updateTemplate(updated);
      } else {
        final template = ChecklistTemplateModel(
          id: ChecklistTemplateModel.generateId(),
          name: _nameController.text.trim(),
          organizationId: widget.organizationId,
          items: _items,
          createdAt: now,
          updatedAt: now,
        );
        await _repository.createTemplate(template);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing 
              ? AppStrings.checklistTemplateSaved 
              : AppStrings.checklistTemplateCreated)),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.checklistSaveError}: $e')),
        );
      }
    }
  }
}
