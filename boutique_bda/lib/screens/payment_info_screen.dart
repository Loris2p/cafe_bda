import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentInfoScreen extends StatelessWidget {
  const PaymentInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(title: const Text('Paiements')),
      body: DefaultTabController(
        length: paymentMethods.length,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                tabs: paymentMethods.map((m) => Tab(text: m['label'])).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: paymentMethods.map((m) => _ModernPaymentDetail(
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

class _ModernPaymentDetail extends StatelessWidget {
  final String phone;
  final String link;

  const _ModernPaymentDetail({required this.phone, required this.link});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          if (link.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: link,
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black87),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(link)),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('OUVRIR LYDIA'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), elevation: 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
          
          Text('Transfert direct', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
            child: Row(
              children: [
                Icon(Icons.phone_android, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Expanded(child: Text(phone, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro copié !')));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
