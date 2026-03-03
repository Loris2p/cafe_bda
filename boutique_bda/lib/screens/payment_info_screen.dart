import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentInfoScreen extends StatelessWidget {
  const PaymentInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // On simule des données qui pourraient venir de Firestore plus tard
    final List<Map<String, String>> paymentMethods = [
      {
        'label': 'Lydia',
        'phone': '06 12 34 56 78',
        'link': 'https://lydia-app.com/collect/boutique-bda',
      },
      {
        'label': 'Paylib',
        'phone': '06 12 34 56 78',
        'link': '',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations de Paiement'),
      ),
      body: DefaultTabController(
        length: paymentMethods.length,
        child: Column(
          children: [
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              tabs: paymentMethods.map((m) => Tab(text: m['label'])).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: paymentMethods.map((m) => _PaymentDetail(
                  phone: m['phone']!,
                  link: m['link']!,
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  final String phone;
  final String link;

  const _PaymentDetail({required this.phone, required this.link});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          if (link.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(link)),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ouvrir le lien de paiement'),
            ),
            const SizedBox(height: 32),
          ],
          const Text('Numéro de téléphone associé :', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(phone, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro copié !')));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
