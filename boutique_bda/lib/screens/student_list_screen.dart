import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';
import '../widgets/data_table_widget.dart';

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
        title: const Text('Membres'),
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
                  hintText: 'Nom ou matricule...',
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
                              'Erreur lors du chargement des membres',
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
                    s.loyaltyBonus.toString(),
                  ]).toList();

                  return DataTableWidget(
                    headers: const ['Nom', 'Prénom', 'ID', 'Classe', 'Solde', 'Fid.'],
                    data: dataRows,
                    isLoading: isLoading,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Nouveau Membre', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final idController = TextEditingController();
    final classController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Ajouter un Étudiant', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                _buildField(idController, 'Matricule', isNumeric: true),
                const SizedBox(height: 16),
                _buildField(classController, 'Classe / Groupe'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newStudent = Student(
                  id: '', 
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  studentId: idController.text.trim(),
                  classGroup: classController.text.trim(),
                );
                context.read<FirebaseService>().addStudent(newStudent);
                Navigator.pop(ctx);
                _refresh();
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? 'Requis' : null,
    );
  }
}
