import 'package:flutter/material.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import '../../theme.dart';
// Actually, simple cyclic config is enough.

class RecurringPeriodPage extends StatefulWidget {
  final Function(DateTime startDate, DateTime endDate, List<int> days, TimeOfDay startTime, TimeOfDay endTime) onSave;

  const RecurringPeriodPage({super.key, required this.onSave});

  @override
  State<RecurringPeriodPage> createState() => _RecurringPeriodPageState();
}

class _RecurringPeriodPageState extends State<RecurringPeriodPage> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365)); // Default 1 year
  
  // Days: 1-Sun, 2-Mon, ..., 7-Sat (TTLock API standard usually 1=Sun? Or 1=Mon? 
  // Wait, TimePeriodModel used 0-6 index.
  // TTLock API for cyclic: weekDay: 1 (Sun) to 7 (Sat) usually. 
  // Let's use 1-7 (Sun-Sat) for API compatibility later.
  // Selected days set.
  final Set<int> _selectedDays = {2, 3, 4, 5, 6}; // Mon-Fri default

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  final List<String> _dayLabels = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt']; // Sun-Sat

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(const Duration(days: 1));
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _toggleDay(int index) {
    // index 0 = Sun (1), 1 = Mon (2)...
    final dayValue = index + 1;
    setState(() {
      if (_selectedDays.contains(dayValue)) {
        if (_selectedDays.length > 1) { // Prevent empty selection
          _selectedDays.remove(dayValue);
        }
      } else {
        _selectedDays.add(dayValue);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.validityPeriod, style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(AppLocalizations.of(context)!.startDate, _formatDate(_startDate), () => _selectDate(true)),
            _buildDivider(),
            _buildRow(AppLocalizations.of(context)!.endDate, _formatDate(_endDate), () => _selectDate(false)),
            
            const SizedBox(height: 30),
            
            Text(AppLocalizations.of(context)!.cycle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                // index matches _dayLabels[index]
                // dayValue = index + 1
                final isSelected = _selectedDays.contains(index + 1);
                return GestureDetector(
                  onTap: () => _toggleDay(index),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _dayLabels[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),

            _buildRow(AppLocalizations.of(context)!.tabTimed + ' ' + AppLocalizations.of(context)!.startDate.split(' ')[1] , _formatTime(_startTime), () => _selectTime(true)),
            _buildDivider(),
            _buildRow(AppLocalizations.of(context)!.tabTimed + ' ' + AppLocalizations.of(context)!.endDate.split(' ')[1], _formatTime(_endTime), () => _selectTime(false)),

            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(_startDate, _endDate, _selectedDays.toList(), _startTime, _endTime);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C), // Gray button per request
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Text(AppLocalizations.of(context)!.ok, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
         padding: const EdgeInsets.symmetric(vertical: 16),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
             Row(
               children: [
                 Text(value, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                 const SizedBox(width: 8),
                 const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
               ],
             )
           ],
         ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color(0xFF2C2C2C), height: 1);
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
  }

  String _formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}";
  }
}
