import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType { idea, bug }

class FeedbackItem {
  final String id;
  final FeedbackType type;
  final String title;
  final String description;
  final String authorName;
  final String? authorEmail;
  final String appVersion;
  final String platform;
  final DateTime createdAt;
  final bool syncedToGithub;
  final String? githubIssueUrl;
  final int? githubIssueNumber;

  FeedbackItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.authorName,
    this.authorEmail,
    required this.appVersion,
    required this.platform,
    required this.createdAt,
    this.syncedToGithub = false,
    this.githubIssueUrl,
    this.githubIssueNumber,
  });

  factory FeedbackItem.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FeedbackItem.fromMap(doc.id, data);
  }

  factory FeedbackItem.fromMap(String id, Map<String, dynamic> data) {
    DateTime parsedDate;
    final rawDate = data['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return FeedbackItem(
      id: id,
      type: data['type'] == 'bug' ? FeedbackType.bug : FeedbackType.idea,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      authorName: data['authorName'] ?? 'Anonyme',
      authorEmail: data['authorEmail'],
      appVersion: data['appVersion'] ?? 'Inconnue',
      platform: data['platform'] ?? 'Inconnue',
      createdAt: parsedDate,
      syncedToGithub: data['syncedToGithub'] == true,
      githubIssueUrl: data['githubIssueUrl'],
      githubIssueNumber: data['githubIssueNumber'] is int
          ? data['githubIssueNumber'] as int
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type == FeedbackType.bug ? 'bug' : 'idea',
      'title': title,
      'description': description,
      'authorName': authorName,
      'authorEmail': authorEmail,
      'appVersion': appVersion,
      'platform': platform,
      'createdAt': FieldValue.serverTimestamp(),
      'syncedToGithub': syncedToGithub,
      'githubIssueUrl': githubIssueUrl,
      'githubIssueNumber': githubIssueNumber,
    };
  }
}
