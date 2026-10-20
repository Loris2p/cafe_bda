import 'package:flutter_test/flutter_test.dart';
import 'package:boutique_bda/models/feedback_item.dart';

void main() {
  group('FeedbackItem Model Tests', () {
    test('fromMap parses idea and bug correctly', () {
      final idea = FeedbackItem.fromMap('id_1', {
        'type': 'idea',
        'title': 'Mode sombre',
        'description': 'Ajouter un thème sombre',
        'authorName': 'Loris',
        'authorEmail': 'loris@bda.fr',
        'appVersion': '12.0.1',
        'platform': 'Web (linux)',
        'syncedToGithub': true,
        'githubIssueNumber': 42,
        'githubIssueUrl': 'https://github.com/Loris2p/cafe_bda/issues/42',
      });

      expect(idea.id, 'id_1');
      expect(idea.type, FeedbackType.idea);
      expect(idea.title, 'Mode sombre');
      expect(idea.syncedToGithub, isTrue);
      expect(idea.githubIssueNumber, 42);

      final bug = FeedbackItem.fromMap('id_2', {
        'type': 'bug',
        'title': 'Crash export',
        'description': 'Erreur lors du clic',
      });

      expect(bug.type, FeedbackType.bug);
      expect(bug.authorName, 'Anonyme');
      expect(bug.syncedToGithub, isFalse);
      expect(bug.githubIssueNumber, isNull);
    });

    test('toFirestore serializes fields properly', () {
      final item = FeedbackItem(
        id: 'test',
        type: FeedbackType.bug,
        title: 'Problème affichage',
        description: 'Détails du bug',
        authorName: 'Loris',
        authorEmail: 'loris@bda.fr',
        appVersion: '12.0.1',
        platform: 'Web',
        createdAt: DateTime(2026, 10, 20),
      );

      final map = item.toFirestore();
      expect(map['type'], 'bug');
      expect(map['title'], 'Problème affichage');
      expect(map['description'], 'Détails du bug');
      expect(map['authorName'], 'Loris');
      expect(map['syncedToGithub'], isFalse);
    });
  });
}
