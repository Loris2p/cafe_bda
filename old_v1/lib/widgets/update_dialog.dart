import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final bool isMandatory;
  final String latestVersion;
  final String currentVersion;
  final String? downloadUrl;

  const UpdateDialog({
    super.key,
    required this.isMandatory,
    required this.latestVersion,
    required this.currentVersion,
    this.downloadUrl,
  });

  static Future<void> show(
    BuildContext context,
    {
      required bool isMandatory,
      required String latestVersion,
      required String currentVersion,
      String? downloadUrl,
    }
  ) {
    return showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => PopScope(
        canPop: !isMandatory,
        child: UpdateDialog(
          isMandatory: isMandatory,
          latestVersion: latestVersion,
          currentVersion: currentVersion,
          downloadUrl: downloadUrl,
        ),
      ),
    );
  }

  Future<void> _launchDownload() async {
    if (downloadUrl != null && downloadUrl!.isNotEmpty) {
      final uri = Uri.parse(downloadUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isMandatory ? 'Mise à jour requise' : 'Mise à jour disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Une nouvelle version de l'application est disponible."),
          const SizedBox(height: 16),
          Text('Version actuelle : $currentVersion'),
          Text('Dernière version : $latestVersion'),
          const SizedBox(height: 16),
          if (isMandatory)
            const Text(
              "Cette mise à jour est obligatoire pour continuer à utiliser l'application.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
      actions: [
        if (!isMandatory)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
        ElevatedButton(
          onPressed: _launchDownload,
          child: const Text('Télécharger'),
        ),
      ],
    );
  }
}
