String formatWholeNumber(num value) {
  final digits = value.round().toString();
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

String formatCurrency(num value, String currency) {
  return '$currency ${formatWholeNumber(value)}';
}
