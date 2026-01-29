import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/school_member_model.dart';
import '../../services/tenant_functions_service.dart';

/// Dialog for school admins to invite users.
class InviteUserDialog extends StatefulWidget {
  final String schoolId;
  final TenantFunctionsService? tenantService;

  const InviteUserDialog({
    super.key,
    required this.schoolId,
    this.tenantService,
  });

  /// Show the dialog and return the result.
  static Future<InvitationResult?> show(
    BuildContext context, {
    required String schoolId,
    TenantFunctionsService? tenantService,
  }) {
    return showDialog<InvitationResult>(
      context: context,
      builder: (context) => InviteUserDialog(
        schoolId: schoolId,
        tenantService: tenantService,
      ),
    );
  }

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  MemberRole _selectedRole = MemberRole.teacher;
  bool _isLoading = false;
  String? _error;
  InvitationResult? _result;

  late final TenantFunctionsService _tenantService;

  @override
  void initState() {
    super.initState();
    _tenantService = widget.tenantService ?? TenantFunctionsService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite User'),
      content: _result != null ? _buildSuccessContent() : _buildFormContent(),
      actions: _result != null ? _buildSuccessActions() : _buildFormActions(),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Role',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<MemberRole>(
              segments: const [
                ButtonSegment(
                  value: MemberRole.teacher,
                  label: Text('Teacher'),
                  icon: Icon(Icons.school),
                ),
                ButtonSegment(
                  value: MemberRole.parent,
                  label: Text('Parent'),
                  icon: Icon(Icons.family_restroom),
                ),
                ButtonSegment(
                  value: MemberRole.admin,
                  label: Text('Admin'),
                  icon: Icon(Icons.admin_panel_settings),
                ),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedRole = selection.first;
                });
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'Invitation Sent!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'An invitation has been created for ${_emailController.text}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _result?.token ?? '',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _result?.token ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token copied to clipboard')),
                  );
                },
                tooltip: 'Copy token',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share this token with the user to complete registration.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _buildFormActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _isLoading ? null : _sendInvitation,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Send Invitation'),
      ),
    ];
  }

  List<Widget> _buildSuccessActions() {
    return [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_result),
        child: const Text('Done'),
      ),
    ];
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _tenantService.createInvitation(
        email: _emailController.text.trim(),
        role: _selectedRole,
        schoolId: widget.schoolId,
      );

      if (result.success) {
        setState(() {
          _result = result;
        });
      } else {
        setState(() {
          _error = 'Failed to create invitation';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
