import 'package:flutter/material.dart';

/// Boîte de dialogue permettant de rechercher et sélectionner un étudiant dans une liste.
///
/// Retourne la ligne de l'étudiant sélectionné (`List<dynamic>`) ou `null` si annulé.
class StudentSearchDialog extends StatefulWidget {
  /// La liste complète des étudiants (incluant les en-têtes).
  final List<List<dynamic>> students;

  const StudentSearchDialog({super.key, required this.students});

  @override
  State<StudentSearchDialog> createState() => _StudentSearchDialogState();
}

class _StudentSearchDialogState extends State<StudentSearchDialog> {
  // Liste filtrée affichée
  List<List<dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // On ignore la première ligne qui contient les en-têtes
    // Data expected: [Name, FirstName, StudentID, Class, ...]
    if (widget.students.isNotEmpty) {
      _filteredStudents = widget.students.skip(1).toList();
    }
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    super.dispose();
  }

  /// Filtre la liste des étudiants en temps réel.
  void _filterStudents() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (widget.students.isEmpty) {
        _filteredStudents = [];
        return;
      }
      
      _filteredStudents = widget.students.skip(1).where((student) {
        if (student.isEmpty) return false;
        
        // Recherche sur Nom, Prénom et Numéro étudiant
        final name = (student.length > 0 ? student[0] : '').toString().toLowerCase();
        final firstName = (student.length > 1 ? student[1] : '').toString().toLowerCase();
        final studentId = (student.length > 2 ? student[2] : '').toString().toLowerCase();
        
        return name.contains(query) ||
            firstName.contains(query) ||
            studentId.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            _buildSearchField(),
            const Divider(height: 1),
            Expanded(
              child: _filteredStudents.isEmpty
                  ? _buildEmptyState()
                  : _buildStudentList(),
            ),
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Icon(Icons.person_search, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Rechercher un étudiant',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Fermer',
          )
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Nom, prénom ou numéro étudiant...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    // Force update as listener might not trigger on clear sometimes if logic varies
                    // but here listener handles it.
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      itemCount: _filteredStudents.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final name = (student.length > 0 ? student[0] : 'Inconnu').toString();
        final firstName = (student.length > 1 ? student[1] : '').toString();
        final studentId = (student.length > 2 ? student[2] : 'N/A').toString();
        final studentClass = (student.length > 3 ? student[3] : '').toString();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            '$name $firstName',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'N°: $studentId ${studentClass.isNotEmpty ? '• $studentClass' : ''}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          onTap: () => Navigator.of(context).pop(student),
          hoverColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun étudiant trouvé',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ),
    );
  }
}