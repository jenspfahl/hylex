import 'package:intl/intl.dart';

String formatToDateTime(DateTime dateTime) {
  final DateFormat dateFormatter = DateFormat.yMd();
  final DateFormat timeFormatter = DateFormat('H:mm');
  return dateFormatter.format(dateTime) + " " + timeFormatter.format(dateTime);
}

String formatToTime(DateTime dateTime) {
  final DateFormat formatter = DateFormat('H:mm');
  return formatter.format(dateTime);
}

String format(DateTime dateTime) {
  if (isToday(dateTime)) {
    return formatToTime(dateTime);
  }
  else {
    return formatToDateTime(dateTime);
  }
}

bool isToday(DateTime? dateTime) {
  if (dateTime == null) return false;
  return truncToDate(dateTime) == truncToDate(DateTime.now());
}

bool isYesterday(DateTime? dateTime) {
  if (dateTime == null) return false;
  return truncToDate(dateTime) == truncToDate(DateTime.now().subtract(Duration(days: 1)));
}

DateTime truncToDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}
