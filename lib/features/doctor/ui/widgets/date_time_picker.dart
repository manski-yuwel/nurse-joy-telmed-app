import 'package:flutter/material.dart';

class DateTimePickerField extends StatefulWidget {
  final void Function(DateTime) onDateTimeSelected;
  const DateTimePickerField({required this.onDateTimeSelected, super.key});

  @override
  State<DateTimePickerField> createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<DateTimePickerField> {
  DateTime? _selectedDateTime;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    // 1. Pick the date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'SELECT DATE',
    );

    if (pickedDate == null) return;

    // 2. Pick the time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDateTime!)
          : TimeOfDay.now(),
      helpText: 'SELECT TIME',
    );

    if (pickedTime == null) return;

    // 3. Combine date and time
    final fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() => _selectedDateTime = fullDateTime);
    widget.onDateTimeSelected(fullDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickDateTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date & Time',
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedDateTime != null
              ? _selectedDateTime.toString()
              : 'Tap to select',
        ),
      ),
    );
  }
}
