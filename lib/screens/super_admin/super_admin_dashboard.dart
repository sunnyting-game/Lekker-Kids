import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/super_admin_service.dart';
import '../../repositories/organization_repository.dart';
import '../../models/organization_model.dart';
import '../../models/school_model.dart';
import '../../services/tenant_functions_service.dart';
import '../demo/demo_data_page.dart';

/// Super Admin Dashboard - Entry point for platform management.
/// Accessible via hidden route for super admins only.
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  final SuperAdminService _superAdminService = SuperAdminService();
  final OrganizationRepository _orgRepository = OrganizationRepository();
  final TenantFunctionsService _tenantFunctions = TenantFunctionsService();

  bool _isLoading = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    final isSuperAdmin = await _superAdminService.isSuperAdmin();
    if (!isSuperAdmin && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied. Super Admin only.')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isAuthorized = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAuthorized) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Portal'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // Demo Data Button
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Generate Demo Data',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DemoDataPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Organization List
          Expanded(
            child: _OrganizationListSection(
              orgRepository: _orgRepository,
              tenantFunctions: _tenantFunctions,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOrganizationDialog,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Organization'),
      ),
    );
  }

  Future<void> _showCreateOrganizationDialog() async {
    final result = await showDialog<CreateOrganizationResult>(
      context: context,
      builder: (context) => _CreateOrganizationDialog(
        tenantFunctions: _tenantFunctions,
      ),
    );

    if (result != null && result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Organization "${result.organizationId}" created!')),
        );
      }
    }
  }
}

// =============================================================================
// ORGANIZATION LIST SECTION
// =============================================================================

class _OrganizationListSection extends StatelessWidget {
  final OrganizationRepository orgRepository;
  final TenantFunctionsService tenantFunctions;

  const _OrganizationListSection({
    required this.orgRepository,
    required this.tenantFunctions,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrganizationModel>>(
      stream: orgRepository.getOrganizationsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final organizations = snapshot.data!;

        if (organizations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No organizations yet',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Create your first organization to get started'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: organizations.length,
          itemBuilder: (context, index) {
            final org = organizations[index];
            return _OrganizationCard(
              organization: org,
              orgRepository: orgRepository,
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// ORGANIZATION CARD WIDGET
// =============================================================================

class _OrganizationCard extends StatefulWidget {
  final OrganizationModel organization;
  final OrganizationRepository orgRepository;

  const _OrganizationCard({
    required this.organization,
    required this.orgRepository,
  });

  @override
  State<_OrganizationCard> createState() => _OrganizationCardState();
}

class _OrganizationCardState extends State<_OrganizationCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Row
          InkWell(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      widget.organization.name.isNotEmpty
                          ? widget.organization.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.organization.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${widget.organization.id}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Details
          if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
                color: Colors.grey[50], // Slight background for details
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dayhomes (Locations)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  StreamBuilder<List<SchoolModel>>(
                    stream: widget.orgRepository
                        .getDayhomesStream(widget.organization.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)));
                      }
                      
                      final dayhomes = snapshot.data ?? [];
                      
                      if (dayhomes.isEmpty) {
                        return const Text('No dayhomes created yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
                      }

                      return Column(
                        children: dayhomes
                            .map((dayhome) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.home_work_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(dayhome.name),
                                      const Spacer(),
                                      Text(dayhome.id, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                    ],
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// CREATE ORGANIZATION DIALOG
// =============================================================================

class _CreateOrganizationDialog extends StatefulWidget {
  final TenantFunctionsService tenantFunctions;

  const _CreateOrganizationDialog({required this.tenantFunctions});

  @override
  State<_CreateOrganizationDialog> createState() =>
      _CreateOrganizationDialogState();
}

class _CreateOrganizationDialogState extends State<_CreateOrganizationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Organization'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Organization Name',
                  hintText: 'e.g., Bright Path Daycares',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an organization name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Email',
                    hintText: 'admin@example.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter admin email';
                    }
                    if (!RegExp(r'^[\w\-\.]+@[\w\-]+(\.[\w\-]+)*$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _createOrganization,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createOrganization() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.tenantFunctions.createOrganization(
        name: _nameController.text.trim(),
        adminEmail: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result.success) {
        if (mounted) {
          Navigator.pop(context, result);
        }
      } else {
        setState(() {
          _error = 'Failed to create organization';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
