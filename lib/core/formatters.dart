import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
final _dateOnly = DateFormat('dd MMM yyyy');

String formatMoney(double value) => _currency.format(value);

String formatDateTime(DateTime? dt) => dt == null ? '' : _dateTime.format(dt);

String formatDate(DateTime? dt) => dt == null ? '' : _dateOnly.format(dt);
