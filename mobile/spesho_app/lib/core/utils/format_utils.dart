import 'package:intl/intl.dart';

class FormatUtils {
  static final _currency = NumberFormat('#,##0.00');
  static final _number = NumberFormat('#,##0.##');
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy HH:mm');

  static String currency(double value) => _currency.format(value);
  static String number(double value) => _number.format(value);
  static String date(DateTime dt) => _dateFormat.format(dt);
  static String dateTime(DateTime dt) => _dateTimeFormat.format(dt);

  static String dateFromString(String iso) {
    try {
      return _dateFormat.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
