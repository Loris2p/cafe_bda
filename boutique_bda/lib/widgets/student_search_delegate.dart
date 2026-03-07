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
    final suggestions = _getFilteredList();

    // Si un seul résultat, on le sélectionne automatiquement lors de la validation (Entrée)
    if (suggestions.length == 1) {
      final student = suggestions.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        close(context, student);
      });
      return const Center(child: CircularProgressIndicator());
    }

    return _buildList(suggestions);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(_getFilteredList());
  }

  List<Student> _getFilteredList() {
    return students.where((s) {
      return s.fullName.toLowerCase().contains(query.toLowerCase()) ||
          s.studentId.contains(query);
    }).toList();
  }

  Widget _buildList(List<Student> suggestions) {
    if (suggestions.isEmpty) {
      return const Center(child: Text('Aucun étudiant trouvé.'));
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final student = suggestions[index];
        return ListTile(
          leading: CircleAvatar(child: Text(student.lastName[0])),
          title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('N° Étudiant: ${student.studentId}'),
          trailing: Text('${student.balance.toStringAsFixed(2)} €'),
          onTap: () => close(context, student),
        );
      },
    );
  }
}
