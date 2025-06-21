import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

/// Model class for appointment time slot
class AppointmentTimeSlot {
  final String id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;

  AppointmentTimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  String get displayTime => 
      '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}';

  DateTime toDateTime(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
    startTime.hour,
    startTime.minute,
  );

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'startTime': '${startTime.hour}:${startTime.minute}',
    'endTime': '${endTime.hour}:${endTime.minute}',
    'isAvailable': isAvailable,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentTimeSlot &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model class for appointment day
class AppointmentDay {
  final String id;
  final DateTime date;
  final List<AppointmentTimeSlot> timeSlots;

  AppointmentDay({
    required this.id,
    required this.date,
    required this.timeSlots,
  });

  String get displayDate => 
      '${_getWeekdayName(date.weekday)}, ${date.day}/${date.month}/${date.year}';

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': Timestamp.fromDate(date),
    'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentDay &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Model class for complete appointment booking
class AppointmentBooking {
  final AppointmentDay selectedDay;
  final AppointmentTimeSlot selectedTimeSlot;
  final List<AppointmentDay> userAvailableDays;
  final String description;

  AppointmentBooking({
    required this.selectedDay,
    required this.selectedTimeSlot,
    required this.userAvailableDays,
    required this.description,
  });

  DateTime get appointmentDateTime => selectedTimeSlot.toDateTime(selectedDay.date);

  Map<String, dynamic> toMap() => {
    'selectedDay': selectedDay.toMap(),
    'selectedTimeSlot': selectedTimeSlot.toMap(),
    'userAvailableDays': userAvailableDays.map((day) => day.toMap()).toList(),
    'description': description,
    'appointmentDateTime': Timestamp.fromDate(appointmentDateTime),
  };
}

/// Appointment Booking Dialog Widget
class AppointmentBookingDialog extends StatefulWidget {
  final String doctorId;
  final List<AppointmentDay>? availableDays;
  final Function(AppointmentBooking) onBookingComplete;

  const AppointmentBookingDialog({
    Key? key,
    required this.doctorId,
    required this.onBookingComplete,
    this.availableDays,
  }) : super(key: key);

  @override
  State<AppointmentBookingDialog> createState() => _AppointmentBookingDialogState();
}

class _AppointmentBookingDialogState extends State<AppointmentBookingDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  final List<AppointmentDay> _availableDays = [];
  AppointmentDay? _selectedDay;
  AppointmentTimeSlot? _selectedTimeSlot;
  
  @override
  void initState() {
    super.initState();
    if (widget.availableDays != null) {
      _availableDays.addAll(widget.availableDays!);
    }
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> _addNewDay() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      helpText: 'SELECT AVAILABLE DATE',
      selectableDayPredicate: (date) {
        return !_availableDays.any((day) => 
            day.date.year == date.year &&
            day.date.month == date.month &&
            day.date.day == date.day);
      },
    );

    if (pickedDate != null) {
      final newDay = AppointmentDay(
        id: _generateId(),
        date: pickedDate,
        timeSlots: [],
      );
      
      setState(() {
        _availableDays.add(newDay);
        _availableDays.sort((a, b) => a.date.compareTo(b.date));
      });
    }
  }

  void _removeDay(AppointmentDay day) {
    setState(() {
      _availableDays.remove(day);
      if (_selectedDay == day) {
        _selectedDay = null;
        _selectedTimeSlot = null;
      }
    });
  }

  Future<void> _addTimeSlot(AppointmentDay day) async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'SELECT START TIME',
    );

    if (startTime == null) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour + 1,
        minute: startTime.minute,
      ),
      helpText: 'SELECT END TIME',
    );

    if (endTime == null) return;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    
    if (endMinutes <= startMinutes) {
      _showErrorDialog('End time must be after start time');
      return;
    }

    final hasOverlap = day.timeSlots.any((slot) {
      final slotStart = slot.startTime.hour * 60 + slot.startTime.minute;
      final slotEnd = slot.endTime.hour * 60 + slot.endTime.minute;
      return (startMinutes < slotEnd && endMinutes > slotStart);
    });

    if (hasOverlap) {
      _showErrorDialog('Time slot overlaps with existing slot');
      return;
    }

    final newTimeSlot = AppointmentTimeSlot(
      id: _generateId(),
      startTime: startTime,
      endTime: endTime,
    );

    setState(() {
      day.timeSlots.add(newTimeSlot);
      day.timeSlots.sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });
    });
  }

  void _removeTimeSlot(AppointmentDay day, AppointmentTimeSlot timeSlot) {
    setState(() {
      day.timeSlots.remove(timeSlot);
      if (_selectedTimeSlot == timeSlot) {
        _selectedTimeSlot = null;
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submitBooking() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      
      if (_selectedDay == null || _selectedTimeSlot == null) {
        _showErrorDialog('Please select both a day and time slot');
        return;
      }

      final booking = AppointmentBooking(
        selectedDay: _selectedDay!,
        selectedTimeSlot: _selectedTimeSlot!,
        userAvailableDays: _availableDays,
        description: formData['description'] ?? '',
      );

      widget.onBookingComplete(booking);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              Row(
                children: [
                  const Icon(Icons.info, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Select your available dates and time slots for an appointment. Then, select a main day and time that you would like to set the appointment.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const Divider(),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvailableDaysSection(),
                      const SizedBox(height: 16),
                      if (_selectedDay != null) ...[
                        _buildTimeSlotsSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildDescriptionField(),
                    ],
                  ),
                ),
              ),
              
              const Divider(),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitBooking,
                    // 
                    child: const Text('Book Appointment'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Available Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ElevatedButton.icon(
              onPressed: _addNewDay,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Day'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_availableDays.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No days added. Click "Add Day" to start.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...List.generate(_availableDays.length, (index) => _buildDayCard(_availableDays[index])),
      ],
    );
  }

  Widget _buildDayCard(AppointmentDay day) {
    final isSelected = _selectedDay == day;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: isSelected ? 2 : 1,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDay = day;
            _selectedTimeSlot = null;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(day.displayDate, style: const TextStyle(fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${day.timeSlots.length}', style: TextStyle(fontSize: 10, color: Colors.blue.shade700)),
              ),
              IconButton(
                onPressed: () => _removeDay(day),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Time Slots', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ElevatedButton.icon(
              onPressed: () => _addTimeSlot(_selectedDay!),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Slot'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_selectedDay!.timeSlots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No time slots added.', style: TextStyle(color: Colors.grey)),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_selectedDay!.timeSlots.length, (index) {
              final timeSlot = _selectedDay!.timeSlots[index];
              return _buildTimeSlotChip(timeSlot);
            }),
          ),
      ],
    );
  }

  Widget _buildTimeSlotChip(AppointmentTimeSlot timeSlot) {
    final isSelected = _selectedTimeSlot == timeSlot;
    
    return InkWell(
      onTap: () => setState(() => _selectedTimeSlot = timeSlot),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeSlot.displayTime,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _removeTimeSlot(_selectedDay!, timeSlot),
              child: Icon(
                Icons.close,
                size: 14,
                color: isSelected ? Colors.white : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return FormBuilderTextField(
      name: 'description',
      decoration: const InputDecoration(
        labelText: 'Appointment Description',
        hintText: 'Describe your medical concern...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      maxLength: 500,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'Please provide a description'),
        FormBuilderValidators.minLength(10, errorText: 'Description must be at least 10 characters'),
      ]),
    );
  }
}


