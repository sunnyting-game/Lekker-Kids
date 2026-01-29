import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/demo_data_generator.dart';

/// Demo Data Generator Page
/// 
/// Accessible from Super Admin Dashboard.
/// Allows generating complete demo data for client presentations.
class DemoDataPage extends StatefulWidget {
  const DemoDataPage({super.key});

  @override
  State<DemoDataPage> createState() => _DemoDataPageState();
}

class _DemoDataPageState extends State<DemoDataPage> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _daysController = TextEditingController(text: '30');

  final DemoDataGenerator _generator = DemoDataGenerator();

  bool _isGenerating = false;
  String _currentPhase = '';
  String _statusMessage = '';
  final List<String> _logs = [];
  
  // Results
  Phase1Result? _phase1Result;
  Phase2Result? _phase2Result;
  Phase3Result? _phase3Result;

  @override
  void dispose() {
    _orgNameController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _generateDemoData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _logs.clear();
      _phase1Result = null;
      _phase2Result = null;
      _phase3Result = null;
    });

    try {
      final orgName = _orgNameController.text.trim();
      final daysOfHistory = int.tryParse(_daysController.text) ?? 30;

      // Phase 1: Create Org and School
      setState(() {
        _currentPhase = 'Phase 1';
        _statusMessage = 'Creating Organization and School...';
      });
      _addLog('Starting Phase 1: Creating "$orgName Demo" organization...');

      _phase1Result = await _generator.createDemoOrgAndSchool(orgName: orgName);

      _addLog('✓ Organization created: ${_phase1Result!.organizationId}');
      _addLog('✓ School created: ${_phase1Result!.schoolId}');
      _addLog('✓ Admin email: ${_phase1Result!.adminEmail}');

      // Phase 2: Create Users
      setState(() {
        _currentPhase = 'Phase 2';
        _statusMessage = 'Creating Teacher and Students...';
      });
      _addLog('Starting Phase 2: Creating users...');

      _phase2Result = await _generator.createDemoUsers(
        organizationId: _phase1Result!.organizationId,
        schoolId: _phase1Result!.schoolId,
      );

      _addLog('✓ Teacher created: ${_phase2Result!.teacher.email}');
      for (final student in _phase2Result!.students) {
        _addLog('✓ Student created: ${student.username} (${student.shift})');
      }

      // Phase 3: Backfill Attendance
      setState(() {
        _currentPhase = 'Phase 3';
        _statusMessage = 'Generating attendance history...';
      });
      _addLog('Starting Phase 3: Backfilling $daysOfHistory days of attendance...');

      _phase3Result = await _generator.backfillAttendance(
        students: _phase2Result!.students,
        schoolId: _phase1Result!.schoolId,
        daysOfHistory: daysOfHistory,
      );

      _addLog('✓ Attendance records created: ${_phase3Result!.totalRecords}');
      _addLog('✓ Days processed: ${_phase3Result!.daysProcessed}');
      _addLog('✓ Weekends skipped: ${_phase3Result!.weekendsSkipped}');

      setState(() {
        _currentPhase = 'Complete';
        _statusMessage = 'Demo data generated successfully!';
      });
      _addLog('');
      _addLog('=== DEMO DATA GENERATION COMPLETE ===');

    } catch (e) {
      setState(() {
        _currentPhase = 'Error';
        _statusMessage = e.toString();
      });
      _addLog('ERROR: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Demo Data'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.paddingMedium),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This will create:\n• 1 Organization (with "_demo" suffix)\n• 1 Dayhome\n• 1 Teacher\n• 6 Students (with attendance history)',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _orgNameController,
                    decoration: const InputDecoration(
                      labelText: 'Organization Name',
                      hintText: 'e.g., Sunshine',
                      helperText: 'Will be created as "Sunshine Demo"',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isGenerating,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an organization name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _daysController,
                    decoration: const InputDecoration(
                      labelText: 'Days of History',
                      hintText: '30',
                      helperText: 'Number of days to backfill attendance (Mon-Fri only)',
                      prefixIcon: Icon(Icons.calendar_month),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: !_isGenerating,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of days';
                      }
                      final days = int.tryParse(value);
                      if (days == null || days < 1 || days > 365) {
                        return 'Please enter a number between 1 and 365';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isGenerating ? null : _generateDemoData,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isGenerating ? 'Generating...' : 'Generate Demo Data'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Section
            if (_currentPhase.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _currentPhase == 'Error'
                      ? Colors.red[100]
                      : _currentPhase == 'Complete'
                          ? Colors.green[100]
                          : Colors.orange[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentPhase,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _currentPhase == 'Error'
                        ? Colors.red[900]
                        : _currentPhase == 'Complete'
                            ? Colors.green[900]
                            : Colors.orange[900],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(_statusMessage, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),

              // Logs
              Container(
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.greenAccent,
                      ),
                    );
                  },
                ),
              ),
            ],

            // Results Section
            if (_phase1Result != null && _currentPhase == 'Complete') ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Generated Credentials',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),

              // Credentials Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CredentialRow(
                        label: 'Org Admin',
                        email: _phase1Result!.adminEmail,
                        password: _phase1Result!.password,
                      ),
                      const Divider(),
                      _CredentialRow(
                        label: 'Teacher',
                        email: _phase2Result!.teacher.email,
                        password: _phase2Result!.teacher.password,
                      ),
                      const Divider(),
                      const Text('Students (all use password: demo123)',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      for (final student in _phase2Result!.students)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• ${student.email} (${student.shift})'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String email;
  final String password;

  const _CredentialRow({
    required this.label,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.email, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: SelectableText(email)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.lock, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              SelectableText(password),
            ],
          ),
        ],
      ),
    );
  }
}
