/// Time period model for Passage Mode configuration
/// Represents a time period during which the lock remains in passage mode
library;

class TimePeriod {
  final String id;
  final List<int> selectedDays; // 0 = Sunday, 6 = Saturday
  final bool isAllHours;
  final int? startHour;
  final int? startMinute;
  final int? endHour;
  final int? endMinute;

  TimePeriod({
    required this.id,
    required this.selectedDays,
    this.isAllHours = false,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
  });

  /// Day names in Turkish
  static const List<String> dayNamesShort = ['Paz', 'Pzt', 'Sal', 'Çrş', 'Per', 'Cum', 'Cmt'];
  static const List<String> dayNamesFull = [
    'Pazar',
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi'
  ];

  /// Create a copy with updated values
  TimePeriod copyWith({
    String? id,
    List<int>? selectedDays,
    bool? isAllHours,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    return TimePeriod(
      id: id ?? this.id,
      selectedDays: selectedDays ?? List.from(this.selectedDays),
      isAllHours: isAllHours ?? this.isAllHours,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  /// Get formatted start time string
  String get startTimeFormatted {
    if (isAllHours) return 'Tüm gün';
    if (startHour == null || startMinute == null) return '--:--';
    return '${startHour!.toString().padLeft(2, '0')}:${startMinute!.toString().padLeft(2, '0')}';
  }

  /// Get formatted end time string
  String get endTimeFormatted {
    if (isAllHours) return 'Tüm gün';
    if (endHour == null || endMinute == null) return '--:--';
    return '${endHour!.toString().padLeft(2, '0')}:${endMinute!.toString().padLeft(2, '0')}';
  }

  /// Get selected days as formatted string
  String get daysFormatted {
    if (selectedDays.isEmpty) return 'Gün seçilmedi';
    if (selectedDays.length == 7) return 'Her gün';
    
    // Check for weekdays (Monday-Friday)
    final weekdays = [1, 2, 3, 4, 5];
    if (selectedDays.length == 5 && weekdays.every((d) => selectedDays.contains(d))) {
      return 'Hafta içi';
    }
    
    // Check for weekend
    if (selectedDays.length == 2 && selectedDays.contains(0) && selectedDays.contains(6)) {
      return 'Hafta sonu';
    }
    
    return selectedDays.map((d) => dayNamesShort[d]).join(', ');
  }

  /// Convert to API cyclic config format
  /// TTLock API expects: weekDay (1-7), startTime (minutes), endTime (minutes)
  List<Map<String, dynamic>> toCyclicConfig() {
    List<Map<String, dynamic>> configs = [];
    
    for (int day in selectedDays) {
      // TTLock API uses 1-7 for Sunday-Saturday
      int apiDay = day + 1;
      
      int startMinutes = isAllHours ? 0 : ((startHour ?? 0) * 60 + (startMinute ?? 0));
      int endMinutes = isAllHours ? 1439 : ((endHour ?? 23) * 60 + (endMinute ?? 59));
      
      configs.add({
        'weekDay': apiDay,
        'startTime': startMinutes,
        'endTime': endMinutes,
      });
    }
    
    return configs;
  }

  /// Check if this period overlaps with another period on any day
  bool overlapsWith(TimePeriod other) {
    // Check if any days overlap
    final commonDays = selectedDays.where((d) => other.selectedDays.contains(d)).toList();
    if (commonDays.isEmpty) return false;
    
    // If both are all hours, they overlap
    if (isAllHours && other.isAllHours) return true;
    
    // Convert times to minutes for comparison
    int thisStart = isAllHours ? 0 : ((startHour ?? 0) * 60 + (startMinute ?? 0));
    int thisEnd = isAllHours ? 1439 : ((endHour ?? 23) * 60 + (endMinute ?? 59));
    int otherStart = other.isAllHours ? 0 : ((other.startHour ?? 0) * 60 + (other.startMinute ?? 0));
    int otherEnd = other.isAllHours ? 1439 : ((other.endHour ?? 23) * 60 + (other.endMinute ?? 59));
    
    // Check for time overlap
    return thisStart < otherEnd && thisEnd > otherStart;
  }

  /// Create from API cyclic config entry
  static TimePeriod fromCyclicConfig(Map<String, dynamic> config, String id) {
    int weekDay = config['weekDay'] ?? 1;
    int startTime = config['startTime'] ?? 0;
    int endTime = config['endTime'] ?? 1439;
    
    // Convert API day (1-7) to our format (0-6)
    int day = weekDay - 1;
    
    bool isAllHours = startTime == 0 && endTime >= 1439;
    
    return TimePeriod(
      id: id,
      selectedDays: [day],
      isAllHours: isAllHours,
      startHour: isAllHours ? null : startTime ~/ 60,
      startMinute: isAllHours ? null : startTime % 60,
      endHour: isAllHours ? null : endTime ~/ 60,
      endMinute: isAllHours ? null : endTime % 60,
    );
  }

  /// Merge multiple periods with same time into single period with multiple days
  static List<TimePeriod> mergeByTime(List<TimePeriod> periods) {
    if (periods.isEmpty) return [];
    
    Map<String, TimePeriod> merged = {};
    
    for (var period in periods) {
      String key = '${period.isAllHours}_${period.startHour}_${period.startMinute}_${period.endHour}_${period.endMinute}';
      
      if (merged.containsKey(key)) {
        var existing = merged[key]!;
        var newDays = {...existing.selectedDays, ...period.selectedDays}.toList()..sort();
        merged[key] = existing.copyWith(selectedDays: newDays);
      } else {
        merged[key] = period;
      }
    }
    
    return merged.values.toList();
  }
}
