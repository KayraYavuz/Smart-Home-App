import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'time_period_model.dart';

/// Time Period Selection Page
/// Allows user to select days and time range for passage mode
class TimePeriodPage extends StatefulWidget {
  final TimePeriod? existingPeriod;

  const TimePeriodPage({super.key, this.existingPeriod});

  @override
  State<TimePeriodPage> createState() => _TimePeriodPageState();
}

class _TimePeriodPageState extends State<TimePeriodPage> {
  late Set<int> _selectedDays;
  bool _isAllHours = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    
    if (widget.existingPeriod != null) {
      final period = widget.existingPeriod!;
      _selectedDays = Set.from(period.selectedDays);
      _isAllHours = period.isAllHours;
      if (!period.isAllHours) {
        _startTime = TimeOfDay(
          hour: period.startHour ?? 8,
          minute: period.startMinute ?? 0,
        );
        _endTime = TimeOfDay(
          hour: period.endHour ?? 18,
          minute: period.endMinute ?? 0,
        );
      }
    } else {
      _selectedDays = {};
    }
  }

  void _toggleDay(int day) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _toggleAllHours(bool value) {
    HapticFeedback.lightImpact();
    setState(() => _isAllHours = value);
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      HapticFeedback.selectionClick();
      setState(() => _endTime = picked);
    }
  }

  void _save() {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir gün seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final period = TimePeriod(
      id: widget.existingPeriod?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      selectedDays: _selectedDays.toList()..sort(),
      isAllHours: _isAllHours,
      startHour: _isAllHours ? null : _startTime.hour,
      startMinute: _isAllHours ? null : _startTime.minute,
      endHour: _isAllHours ? null : _endTime.hour,
      endMinute: _isAllHours ? null : _endTime.minute,
    );

    Navigator.pop(context, period);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Zaman dilimi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Selector Section
                  _buildSectionTitle('Bu günlerde'),
                  const SizedBox(height: 16),
                  _buildDaySelector(),
                  
                  const SizedBox(height: 32),
                  
                  // Time Settings Section
                  _buildSectionTitle('Zaman ayarları'),
                  const SizedBox(height: 16),
                  
                  // All Hours Option
                  _buildAllHoursOption(),
                  
                  const SizedBox(height: 12),
                  
                  // Start Time
                  _buildTimeRow(
                    title: 'Başlangıç saati',
                    time: _startTime,
                    onTap: _isAllHours ? null : _selectStartTime,
                    enabled: !_isAllHours,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // End Time
                  _buildTimeRow(
                    title: 'Bitiş zamanı',
                    time: _endTime,
                    onTap: _isAllHours ? null : _selectEndTime,
                    enabled: !_isAllHours,
                  ),
                ],
              ),
            ),
          ),
          
          // Save Button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return GestureDetector(
          onTap: () => _toggleDay(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                TimePeriod.dayNamesShort[index],
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAllHoursOption() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleAllHours(!_isAllHours),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAllHours ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: _isAllHours ? AppColors.primary : AppColors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: _isAllHours
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 14),
                const Text(
                  'Tüm saatler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required String title,
    required TimeOfDay time,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          color: enabled ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: enabled ? AppColors.textSecondary : AppColors.border,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Tamam',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
