class PaymentConfig {
  final String label;
  final String phoneNumber;
  final String link;
  final bool isActive;

  PaymentConfig({
    required this.label,
    required this.phoneNumber,
    required this.link,
    this.isActive = true,
  });

  factory PaymentConfig.fromRow(List<dynamic> row) {
    // Expected format: [Label, PhoneNumber, Link, IsActive]
    // Example: ["Lydia", "06 12 34 56 78", "https://lydia-app.com/...", "TRUE"]
    
    final label = row.isNotEmpty ? row[0].toString() : '';
    final phoneNumber = row.length > 1 ? row[1].toString() : '';
    final link = row.length > 2 ? row[2].toString() : '';
    
    bool isActive = true;
    if (row.length > 3) {
      final val = row[3];
      if (val is bool) {
        isActive = val;
      } else {
        final str = val.toString().toUpperCase();
        isActive = str == 'TRUE';
      }
    }
    
    return PaymentConfig(
      label: label,
      phoneNumber: phoneNumber,
      link: link,
      isActive: isActive,
    );
  }
}
