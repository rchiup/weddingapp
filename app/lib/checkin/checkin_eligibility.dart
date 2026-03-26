import 'package:timezone/timezone.dart' as tz;

/// Radio máximo respecto al lugar del evento para marcar llegada.
const double checkInRadiusMeters = 300;

/// Misma fecha calendario que el evento, en hora de Chile (coherente con horarios de llegada en la app).
bool isCheckinEventDay(DateTime? eventDate) {
  if (eventDate == null) return false;
  final loc = tz.getLocation('America/Santiago');
  final now = tz.TZDateTime.now(loc);
  final ev = tz.TZDateTime.from(
    eventDate.isUtc ? eventDate : eventDate.toUtc(),
    loc,
  );
  return now.year == ev.year && now.month == ev.month && now.day == ev.day;
}
