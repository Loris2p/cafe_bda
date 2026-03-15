import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';
import '../widgets/data_table_widget.dart';
import '../main.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';
  late Stream<List<Student>> _studentsStream;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final firebaseService = Provider.of<FirebaseService>(context);
      _studentsStream = firebaseService.getStudents();
      _isInitialized = true;
    }
  }

  void _refresh() {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    setState(() {
      _studentsStream = firebaseService.getStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Étudiants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Nom ou N° Étudiant...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: StreamBuilder<List<Student>>(
                stream: _studentsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur lors du chargement des Étudiants',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _refresh, child: const Text('Réessayer')),
                          ],
                        ),
                      ),
                    );
                  }

                  final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
                  final students = snapshot.data ?? [];
                  
                  final filteredStudents = students.where((s) {
                    return s.fullName.toLowerCase().contains(_searchQuery) ||
                        s.studentId.contains(_searchQuery);
                  }).toList();

                  final dataRows = filteredStudents.map((s) => [
                    s.lastName,
                    s.firstName,
                    s.studentId,
                    s.classGroup,
                    '${s.balance.toStringAsFixed(2)} €',
                    s.totalBought,
                    s.loyaltyBonus,
                  ]).toList();

                  return DataTableWidget(
                    headers: const ['Nom', 'Prénom', 'ID', 'Classe', 'Solde', 'Pris', 'Fid.'],
                    data: dataRows,
                    isLoading: isLoading,
                    onRowTap: (index) => _showStudentDetails(context, filteredStudents[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_student_fab',
        onPressed: () => _showAddStudentDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Nouvel étudiant', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    _showStudentFormDialog(context);
  }

  void _showEditStudentDialog(BuildContext context, Student student) {
    _showStudentFormDialog(context, student: student);
  }

  void _showStudentFormDialog(BuildContext context, {Student? student}) {
    final isEdit = student != null;
    final firstNameController = TextEditingController(text: student?.firstName);
    final lastNameController = TextEditingController(text: student?.lastName);
    final idController = TextEditingController(text: student?.studentId);
    final classController = TextEditingController(text: student?.classGroup);
    final balanceController = TextEditingController(text: student?.balance.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(isEdit ? 'Modifier l\'Étudiant' : 'Ajouter un Étudiant', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(firstNameController, 'Prénom'),
                const SizedBox(height: 16),
                _buildField(lastNameController, 'Nom'),
                const SizedBox(height: 16),
                _buildField(idController, 'N° Étudiant', isNumeric: true, enabled: !isEdit),
                const SizedBox(height: 16),
                _buildField(classController, 'Classe / Groupe'),
                if (isEdit) ...[
                  const SizedBox(height: 16),
                  _buildField(balanceController, 'Solde (€)', isNumeric: true),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final studentData = Student(
                  id: student?.id ?? '', 
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  studentId: idController.text.trim(),
                  classGroup: classController.text.trim(),
                  balance: isEdit ? (double.tryParse(balanceController.text.replaceAll(',', '.')) ?? student.balance) : 0.0,
                  loyaltyBonus: student?.loyaltyBonus ?? 0,
                  totalBought: student?.totalBought ?? 0,
                  lastTransactionAt: student?.lastTransactionAt,
                );
                
                try {
                  final service = context.read<FirebaseService>();
                  if (isEdit) {
                    await service.updateStudent(studentData);
                  } else {
                    await service.addStudent(studentData);
                  }
                  
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);

                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (successCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        title: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 30),
                            SizedBox(width: 12),
                            Text('Étudiant ajouté'),
                          ],
                        ),
                        content: Text('Les informations de ${studentData.fullName} ont été enregistrées.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(successCtx), child: const Text('OK')),
                        ],
                      ),
                    );
                  }
                  _refresh();
                } catch (e) {
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {bool isNumeric = false, bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? 'Requis' : null,
    );
  }

  void _showStudentDetails(BuildContext context, Student student) {
    final isAdmin = context.read<AdminProvider>().isAdmin;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(student.fullName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(label: 'N° Étudiant', value: student.studentId),
            _InfoRow(label: 'Classe', value: student.classGroup),
            const Divider(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: student.balance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Solde', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  Text('${student.balance.toStringAsFixed(2)} €', 
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 24, color: student.balance >= 0 ? Colors.green : Colors.red)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
          if (isAdmin)
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.pop(ctx);
                _showEditStudentDialog(context, student);
              },
              label: const Text('Modifier'),
            )
          else
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<TabProvider>().setTab(1); // Index 1 est 'Vendre'
              },
              child: const Text('Vendre'),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
