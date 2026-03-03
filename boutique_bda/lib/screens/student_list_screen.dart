import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../services/firebase_service.dart';

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
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un nom ou un matricule...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: firebaseService.getStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final students = snapshot.data ?? [];
                final filteredStudents = students.where((s) {
                  return s.fullName.toLowerCase().contains(_searchQuery) ||
                      s.studentId.contains(_searchQuery);
                }).toList();

                if (filteredStudents.isEmpty) {
                  return const Center(child: Text('Aucun étudiant trouvé'));
                }

                return ListView.separated(
                  itemCount: filteredStudents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(student.lastName[0].toUpperCase()),
                      ),
                      title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Matricule: ${student.studentId} • ${student.classGroup}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${student.balance.toStringAsFixed(2)} €',
                            style: TextStyle(
                              color: student.balance >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text('Bonus: ${student.loyaltyBonus}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      onTap: () {
                        // Voir détails de l'étudiant
                      },
                    );
                  },
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
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'Matricule'),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                TextFormField(
                  controller: classController,
                  decoration: const InputDecoration(labelText: 'Classe / Groupe'),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
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
                  id: '', // Firestore générera l'ID
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
