import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yavuz_lock/api_service.dart';
import 'package:yavuz_lock/repositories/auth_repository.dart';
import 'package:yavuz_lock/ui/theme.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';
import 'time_period_model.dart';
import 'time_period_page.dart';

/// Passage Mode Main Page (Geçiş Modu Ana Sayfası)
/// Allows user to enable/disable passage mode and manage time periods
class PassageModePage extends StatefulWidget {
  final Map<String, dynamic> lock;

  const PassageModePage({super.key, required this.lock});

  @override
  State<PassageModePage> createState() => _PassageModePageState();
}

class _PassageModePageState extends State<PassageModePage> {
  late ApiService _apiService;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _passageModeEnabled = false;
  List<TimePeriod> _timePeriods = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(AuthRepository());
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final config = await _apiService.getPassageModeConfiguration(
        lockId: widget.lock['lockId'].toString(),
      );

      if (!mounted) return;

      setState(() {
        _passageModeEnabled = config['passageMode'] == 1;
        
        // Parse cyclic config if available
        if (config['cyclicConfig'] != null && config['cyclicConfig'] is List) {
          List<TimePeriod> periods = [];
          int index = 0;
          for (var entry in config['cyclicConfig']) {
            periods.add(TimePeriod.fromCyclicConfig(entry, 'period_$index'));
            index++;
          }
          _timePeriods = TimePeriod.mergeByTime(periods);
        }
        
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.configLoadError(e.toString()))),
      );
    }
  }

  void _togglePassageMode(bool value) {
    HapticFeedback.lightImpact();
    setState(() {
      _passageModeEnabled = value;
      _hasChanges = true;
    });
  }

  Future<void> _addTimePeriod() async {
    final result = await Navigator.push<TimePeriod>(
      context,
      MaterialPageRoute(
        builder: (context) => const TimePeriodPage(),
      ),
    );

    if (result != null) {
      // Check for conflicts
      final conflicts = _timePeriods.where((p) => p.overlapsWith(result)).toList();
      
      if (conflicts.isNotEmpty && mounted) {
        final proceed = await _showConflictWarning(conflicts);
        if (!proceed) return;
      }

      setState(() {
        _timePeriods.add(result);
        _hasChanges = true;
      });
    }
  }

  Future<void> _editTimePeriod(int index) async {
    final result = await Navigator.push<TimePeriod>(
      context,
      MaterialPageRoute(
        builder: (context) => TimePeriodPage(existingPeriod: _timePeriods[index]),
      ),
    );

    if (result != null) {
      // Check for conflicts with other periods (excluding the one being edited)
      final otherPeriods = List<TimePeriod>.from(_timePeriods)..removeAt(index);
      final conflicts = otherPeriods.where((p) => p.overlapsWith(result)).toList();
      
      if (conflicts.isNotEmpty && mounted) {
        final proceed = await _showConflictWarning(conflicts);
        if (!proceed) return;
      }

      setState(() {
        _timePeriods[index] = result;
        _hasChanges = true;
      });
    }
  }

  Future<bool> _showConflictWarning(List<TimePeriod> conflicts) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Text(
              l10n.timeConflict,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.timeOverlapWarning,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ...conflicts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${c.daysFormatted}: ${c.startTimeFormatted} - ${c.endTimeFormatted}',
                style: const TextStyle(color: Colors.white),
              ),
            )),
            const SizedBox(height: 12),
            Text(
              l10n.addStill,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.add, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _deleteTimePeriod(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _timePeriods.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      // Build cyclic config from all periods
      List<Map<String, dynamic>> cyclicConfig = [];
      for (var period in _timePeriods) {
        cyclicConfig.addAll(period.toCyclicConfig());
      }

      await _apiService.configurePassageMode(
        lockId: widget.lock['lockId'].toString(),
        passageMode: _passageModeEnabled ? 1 : 2,
        cyclicConfig: cyclicConfig.isNotEmpty ? cyclicConfig : null,
        type: 2, // Via gateway/WiFi
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 12),
              Text(l10n.configSaved),
            ],
          ),
          backgroundColor: AppColors.surface,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorWithMsg(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (_hasChanges) {
              _showUnsavedChangesDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          l10n.passageModeTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Description
                      _buildDescription(),
                      
                      const SizedBox(height: 24),
                      
                      // Passage Mode Toggle
                      _buildPassageModeToggle(),
                      
                      const SizedBox(height: 12),
                      
                      // Time Period Add Row
                      _buildTimePeriodRow(),
                      
                      const SizedBox(height: 20),
                      
                      // Time Periods List or Empty State
                      if (_timePeriods.isEmpty)
                        _buildEmptyState()
                      else
                        ..._buildTimePeriodsList(),
                    ],
                  ),
                ),
                
                // Save Button
                _buildSaveButton(),
              ],
            ),
    );
  }

  Widget _buildDescription() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.passageModeInstruction,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassageModeToggle() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _passageModeEnabled 
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.door_front_door,
                    color: _passageModeEnabled ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  l10n.passageModeTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Switch(
              value: _passageModeEnabled,
              onChanged: _togglePassageMode,
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePeriodRow() {
    final l10n = AppLocalizations.of(context)!;
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
          onTap: _addTimePeriod,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.border.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      l10n.timePeriod,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noPlanAdded,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addTimelineInstruction,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimePeriodsList() {
    return _timePeriods.asMap().entries.map((entry) {
      final index = entry.key;
      final period = entry.value;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Dismissible(
          key: Key(period.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteTimePeriod(index),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: AppColors.error),
          ),
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
                onTap: () => _editTimePeriod(index),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              period.daysFormatted,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              period.isAllHours
                                  ? AppLocalizations.of(context)!.allDay
                                  : '${period.startTimeFormatted} - ${period.endTimeFormatted}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSaveButton() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveConfiguration,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasChanges 
                  ? AppColors.primary 
                  : AppColors.textSecondary.withOpacity(0.3),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  )
                : Text(
                    l10n.save,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showUnsavedChangesDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.unsavedChanges,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.unsavedChangesMsg,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.exit, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context);
    }
  }
}
