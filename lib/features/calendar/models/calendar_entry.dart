class CalendarEntry {
  final String id;
  final String title;
  final String? description;
  final bool isPrimary;
  final String? color;

  CalendarEntry({
    required this.id,
    required this.title,
    this.description,
    this.isPrimary = false,
    this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
