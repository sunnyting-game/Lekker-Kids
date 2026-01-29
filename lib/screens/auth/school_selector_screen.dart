import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/context_service.dart';
import '../../models/school_member_model.dart';

/// Screen displayed when a user belongs to multiple schools.
/// Allows them to select which school/role to use for this session.
class SchoolSelectorScreen extends StatelessWidget {
  final List<SchoolMembership> memberships;
  final ContextService contextService;
  final VoidCallback onSchoolSelected;

  const SchoolSelectorScreen({
    super.key,
    required this.memberships,
    required this.contextService,
    required this.onSchoolSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select School'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You belong to multiple schools.\nSelect one to continue:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: memberships.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final membership = memberships[index];
                    return _SchoolCard(
                      membership: membership,
                      onTap: () => _selectSchool(context, membership),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectSchool(BuildContext context, SchoolMembership membership) {
    contextService.setContext(
      school: membership.school,
      member: membership.member,
    );
    onSchoolSelected();
  }
}

class _SchoolCard extends StatelessWidget {
  final SchoolMembership membership;
  final VoidCallback onTap;

  const _SchoolCard({
    required this.membership,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getRoleColor(membership.role).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getRoleIcon(membership.role),
                  color: _getRoleColor(membership.role),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.schoolName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(membership.role).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getRoleLabel(membership.role),
                        style: TextStyle(
                          color: _getRoleColor(membership.role),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return Colors.purple;
      case MemberRole.teacher:
        return Colors.blue;
      case MemberRole.parent:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return Icons.admin_panel_settings;
      case MemberRole.teacher:
        return Icons.school;
      case MemberRole.parent:
        return Icons.family_restroom;
    }
  }

  String _getRoleLabel(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.teacher:
        return 'Teacher';
      case MemberRole.parent:
        return 'Parent';
    }
  }
}
