import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Étudiants'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 50,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un nom ou un matricule...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: firebaseService.getStudents(),
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final students = snapshot.data ?? [];
                
                final filteredStudents = students.where((s) {
                  return s.fullName.toLowerCase().contains(_searchQuery) ||
                      s.studentId.contains(_searchQuery);
                }).toList();

                // On transforme les objets Student en lignes pour le DataTable
                final dataRows = filteredStudents.map((s) => [
                  s.lastName,
                  s.firstName,
                  s.studentId,
                  s.classGroup,
                  '${s.balance.toStringAsFixed(2)} €',
                  s.loyaltyBonus.toString(),
                ]).toList();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DataTableWidget(
                    headers: const ['Nom', 'Prénom', 'ID', 'Classe', 'Solde', 'Fidélité'],
                    data: dataRows,
                    isLoading: isLoading,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context),
        child: const Icon(Icons.person_add),
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
        title: const Text('Ajouter un Étudiant'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: firstNameController, decoration: const InputDecoration(labelText: 'Prénom'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                const SizedBox(height: 12),
                TextFormField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Nom'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                const SizedBox(height: 12),
                TextFormField(controller: idController, decoration: const InputDecoration(labelText: 'Matricule'), validator: (v) => v!.isEmpty ? 'Requis' : null),
                const SizedBox(height: 12),
                TextFormField(controller: classController, decoration: const InputDecoration(labelText: 'Classe / Groupe'), validator: (v) => v!.isEmpty ? 'Requis' : null),
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
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
