import 'package:flutter/material.dart';

class StudentSearchDialog extends StatefulWidget {
  final List<List<dynamic>> students;

  const StudentSearchDialog({super.key, required this.students});

  @override
  _StudentSearchDialogState createState() => _StudentSearchDialogState();
}

class _StudentSearchDialogState extends State<StudentSearchDialog> {
  List<List<dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // We skip the first row which contains the headers
    _filteredStudents = widget.students.skip(1).toList();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = widget.students.skip(1).where((student) {
        final name = student[0].toString().toLowerCase();
        final firstName = student[1].toString().toLowerCase();
        final studentId = student[2].toString().toLowerCase();
        return name.contains(query) ||
            firstName.contains(query) ||
            studentId.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechercher un étudiant'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Nom, prénom ou numéro étudiant',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  return ListTile(
                    title: Text('${student[0]} ${student[1]}'),
                    subtitle: Text('N°: ${student[2]} - ${student[3]}'),
                    onTap: () {
                      Navigator.of(context).pop(student);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
