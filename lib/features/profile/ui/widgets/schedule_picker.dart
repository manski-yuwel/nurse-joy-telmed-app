import 'package:flutter/material.dart';

/// Model class for time slot
class ScheduleTimeSlot {
  final String id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  ScheduleTimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
  });

  String get displayTime => 
      '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}';

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'startTime': '${startTime.hour}:${startTime.minute}',
    'endTime': '${endTime.hour}:${endTime.minute}',
  };

  factory ScheduleTimeSlot.fromMap(Map<String, dynamic> map) {
    final startParts = (map['startTime'] as String).split(':');
    final endParts = (map['endTime'] as String).split(':');
    
    return ScheduleTimeSlot(
      id: map['id'] as String,
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
    );
  }
}

/// Model class for schedule day
class ScheduleDay {
  final String id;
  final String day;
  final List<ScheduleTimeSlot> timeSlots;
  bool isAvailable;

  ScheduleDay({
    required this.id,
    required this.day,
    List<ScheduleTimeSlot>? timeSlots,
    this.isAvailable = false,
  }) : timeSlots = timeSlots ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'day': day,
    'isAvailable': isAvailable,
    'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
  };

  factory ScheduleDay.fromMap(Map<String, dynamic> map) {
    return ScheduleDay(
      id: map['id'] as String,
      day: map['day'] as String,
      isAvailable: map['isAvailable'] as bool? ?? false,
      timeSlots: (map['timeSlots'] as List<dynamic>? ?? [])
          .map((slot) => ScheduleTimeSlot.fromMap(slot as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SchedulePicker extends StatefulWidget {
  final List<ScheduleDay> initialSchedule;
  final ValueChanged<List<ScheduleDay>> onScheduleChanged;

  const SchedulePicker({
    Key? key,
    required this.initialSchedule,
    required this.onScheduleChanged,
  }) : super(key: key);

  @override
  _SchedulePickerState createState() => _SchedulePickerState();
}

class _SchedulePickerState extends State<SchedulePicker> {
  late List<ScheduleDay> _schedule;
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _schedule = widget.initialSchedule.isNotEmpty
        ? widget.initialSchedule
        : _daysOfWeek.map((day) => ScheduleDay(
              id: day.toLowerCase(),
              day: day,
              timeSlots: [],
              isAvailable: false,
            )).toList();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _toggleDayAvailability(ScheduleDay day) {
    setState(() {
      day.isAvailable = !day.isAvailable;
      _notifyParent();
    });
  }

  Future<void> _addTimeSlot(ScheduleDay day) async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Select start time',
    );

    if (startTime == null) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour + 1,
        minute: startTime.minute,
      ),
      helpText: 'Select end time',
    );

    if (endTime != null) {
      // Validate that end time is after start time
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      
      if (endMinutes <= startMinutes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          day.timeSlots.add(ScheduleTimeSlot(
            id: _generateId(),
            startTime: startTime,
            endTime: endTime,
          ));
          _notifyParent();
        });
      }
    }
  }

  void _removeTimeSlot(ScheduleDay day, ScheduleTimeSlot timeSlot) {
    setState(() {
      day.timeSlots.removeWhere((slot) => slot.id == timeSlot.id);
      _notifyParent();
    });
  }

  Future<void> _editTimeSlot(ScheduleDay day, ScheduleTimeSlot timeSlot) async {
    TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: timeSlot.startTime,
      helpText: 'Select start time',
    );
    
    if (newStartTime == null) return;
    
    TimeOfDay? newEndTime = await showTimePicker(
      context: context,
      initialTime: timeSlot.endTime,
      helpText: 'Select end time',
    );

    if (newEndTime != null) {
      // Validate that end time is after start time
      final startMinutes = newStartTime.hour * 60 + newStartTime.minute;
      final endMinutes = newEndTime.hour * 60 + newEndTime.minute;
      
      if (endMinutes <= startMinutes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          final index = day.timeSlots.indexWhere((slot) => slot.id == timeSlot.id);
          if (index != -1) {
            day.timeSlots[index] = ScheduleTimeSlot(
              id: timeSlot.id,
              startTime: newStartTime,
              endTime: newEndTime,
            );
            _notifyParent();
          }
        });
      }
    }
  }

  void _notifyParent() {
    widget.onScheduleChanged(_schedule);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Availability',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._schedule.map((day) => _buildDayCard(day)).toList(),
      ],
    );
  }

  Widget _buildDayCard(ScheduleDay day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: day.isAvailable,
                  onChanged: (_) => _toggleDayAvailability(day),
                ),
                Text(
                  day.day,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (day.isAvailable)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _addTimeSlot(day),
                  ),
              ],
            ),
            if (day.isAvailable && day.timeSlots.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: day.timeSlots.map((timeSlot) => _buildTimeSlotChip(day, timeSlot)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotChip(ScheduleDay day, ScheduleTimeSlot timeSlot) {
    return InputChip(
      label: Text(timeSlot.displayTime),
      onPressed: () => _editTimeSlot(day, timeSlot),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => _removeTimeSlot(day, timeSlot),
    );
  }
}

// Helper function to convert schedule data to Firestore format
Map<String, dynamic> scheduleToMap(List<ScheduleDay> schedule) {
  return {
    'schedule': schedule.map((day) => day.toMap()).toList(),
  };
}

// Helper function to parse schedule data from Firestore
List<ScheduleDay> scheduleFromMap(Map<String, dynamic>? data) {
  if (data == null) return [];
  
  final scheduleData = data['schedule'] as List<dynamic>?;
  if (scheduleData == null) return [];
  
  return scheduleData
      .map((dayData) => ScheduleDay.fromMap(dayData as Map<String, dynamic>))
      .toList();
}
