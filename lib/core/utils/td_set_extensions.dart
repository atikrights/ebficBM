import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/td_set_provider.dart';

/// Extension on BuildContext for easy, provider-backed currency & language access.
/// Usage:
///   context.currencySymbol  → '৳' or '$'
///   context.currency        → 'BDT' or 'USDT'
///   context.language        → 'bn' or 'en'
extension TdSetContext on BuildContext {
  TdSetProvider get _tdSet => read<TdSetProvider>();

  /// The active currency symbol ('৳' for BDT, '$' for USDT)
  String get currencySymbol => _tdSet.currencySymbol;

  /// The active currency code ('BDT' or 'USDT')
  String get currency => _tdSet.currency;

  /// The active language code ('bn' or 'en')
  String get language => _tdSet.language;

  /// Formats a numeric amount with the current currency symbol prefix.
  /// e.g. formatCurrency(1250.5) → '$1,250.50' or '৳1,250.50'
  String formatCurrency(num amount, {int decimals = 0}) {
    final sym = _tdSet.currencySymbol;
    if (decimals == 0) {
      return '$sym${amount.toInt()}';
    }
    return '$sym${amount.toStringAsFixed(decimals)}';
  }
}
