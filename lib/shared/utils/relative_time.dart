String relativeDateLabel(DateTime date, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final target = _dateOnly(date);
  final days = target.difference(today).inDays;

  if (days == 0) return 'Hôm nay';
  if (days == 1) return 'Ngày mai';
  if (days == -1) return 'Hôm qua';

  if (days > 0) {
    return '${_relativeUnit(days)} nữa';
  }

  return '${_relativeUnit(days.abs())} trước';
}

String _relativeUnit(int days) {
  if (days < 30) return '$days ngày';

  if (days < 365) {
    final months = (days / 30).round().clamp(1, 12);
    return '$months tháng';
  }

  final years = (days / 365).round().clamp(1, 999);
  return '$years năm';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
