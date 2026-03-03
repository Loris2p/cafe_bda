import 'package:flutter/material.dart';
import '../models/student.dart';

class StudentSearchDelegate extends SearchDelegate<Student?> {
  final List<Student> students;

  StudentSearchDelegate(this.students);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList();
  }

  Widget _buildList() {
    final suggestions = students.where((s) {
      return s.fullName.toLowerCase().contains(query.toLowerCase()) ||
          s.studentId.contains(query);
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final student = suggestions[index];
        return ListTile(
          title: Text(student.fullName),
          subtitle: Text('Matricule: ${student.studentId}'),
          trailing: Text('${student.balance.toStringAsFixed(2)} €'),
          onTap: () => close(context, student),
        );
      },
    );
  }
}
