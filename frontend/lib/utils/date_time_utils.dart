class DateTimeUtils {
  static String toIsoString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  static String toDateString(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}