import 'package:flutter/material.dart';

class DateTimePickerHelper {
  static Future<String?> pickDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        return "${fullDateTime.year}-${fullDateTime.month.toString().padLeft(2, '0')}-${fullDateTime.day.toString().padLeft(2, '0')} "
            "${pickedTime.format(context)}";
      }
    }

    return null;
  }
}
