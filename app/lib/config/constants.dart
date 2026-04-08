import 'package:intl/intl.dart';

class AppConstants {
  static const String currency = 'FCFA';
  static final NumberFormat priceFormat = NumberFormat('#,###', 'fr_FR');

  /// Formater un prix en FCFA
  static String formatPrice(dynamic price) {
    if (price == null) return '—';
    final amount = price is num ? price : num.tryParse(price.toString()) ?? 0;
    if (amount == 0) return 'Sur devis';
    return '${priceFormat.format(amount)} $currency';
  }

  /// Catégories de services avec icônes
  static const Map<String, String> categoryLabels = {
    'courses': 'Courses',
    'medicaments': 'Médicaments',
    'colis': 'Colis & Livraison',
    'accompagnement': 'Accompagnement',
    'assistance': 'Aide à domicile',
    'autre': 'Autre',
  };
}
