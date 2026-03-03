import 'package:cafe_bda/models/payment_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentInfoWidget extends StatelessWidget {
  final List<PaymentConfig> paymentConfigs;

  const PaymentInfoWidget({super.key, required this.paymentConfigs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double maxWidth = 400; // Largeur fixe similaire aux formulaires

    // Si aucune config, on affiche un message simple
    if (paymentConfigs.isEmpty) {
      return const Center(child: Text("Aucune information de paiement configurée."));
    }

    // S'il n'y a qu'une seule config, on l'affiche directement sans onglets
    if (paymentConfigs.length == 1) {
      return Card(
        elevation: 0, // Flat on page background or slight elevation
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: theme.colorScheme.outlineVariant)),
        color: theme.colorScheme.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, paymentConfigs.first.label),
                const SizedBox(height: 24),
                _PaymentCardContent(config: paymentConfigs.first),
              ],
            ),
          ),
        ),
      );
    }

    // Sinon, on utilise des onglets
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      color: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 600),
        child: DefaultTabController(
          length: paymentConfigs.length,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec TabBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Paiement",
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      tabs: paymentConfigs.map((c) => Tab(text: c.label)).toList(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Contenu flexible
              Flexible(
                child: TabBarView(
                  children: paymentConfigs.map((config) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: _PaymentCardContent(config: config),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _PaymentCardContent extends StatelessWidget {
  final PaymentConfig config;

  const _PaymentCardContent({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLink = config.link.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLink) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(config.link);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: QrImageView(
                data: config.link,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Touchez le QR Code pour ouvrir",
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 24),
        ],

        if (config.phoneNumber.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.phone, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                SelectableText(
                  config.phoneNumber,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: "Copier",
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: config.phoneNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Numéro copié !")),
                    );
                  },
                )
              ],
            ),
          ),
        ]
      ],
    );
  }
}
