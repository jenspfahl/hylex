import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

String formatToDateTime(DateTime dateTime, String languageCode) {

  final DateFormat dateFormatter = DateFormat.yMd(languageCode);
  final DateFormat timeFormatter = DateFormat('H:mm', languageCode);
  return dateFormatter.format(dateTime) + " " + timeFormatter.format(dateTime);
}

String formatToTime(DateTime dateTime, String languageCode) {
  final DateFormat formatter = DateFormat('H:mm', languageCode);
  return formatter.format(dateTime);
}

String format(DateTime dateTime, AppLocalizations l10n, String languageCode) {
  if (isToday(dateTime)) {
    return formatToTime(dateTime, languageCode);
  }
  else if (isYesterday(dateTime)) {
    return "${l10n.yesterday} ${formatToTime(dateTime, languageCode)}";
  }
  else {
    return formatToDateTime(dateTime, languageCode);
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
