import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class Newcronreminder extends StatefulWidget {
  final String eventId;
  final String eventName;
  final String imageUrl;
  final currentUserPhone;
  final bool isDisabled;
  final bool compact;
  const Newcronreminder({
    Key? key,
    required this.eventId,
    required this.eventName,
    required this.imageUrl,
    required this.currentUserPhone,
    this.isDisabled = false,
      this.compact = false, // Default to false
  }) : super(key: key);

  @override
  State<Newcronreminder> createState() => _NewcronreminderState();
}

class _NewcronreminderState extends State<Newcronreminder> {
  DateTime? _selectedDateTime;
  String _recurrence = '';
  List<String> _weekdays = [];
  List<String> _monthDays = [];
  String? _selectedMonth;
  List<int> _availableDays = [];
  final TextEditingController _dateTimeController = TextEditingController();

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void dispose() {
    _dateTimeController.dispose();
    super.dispose();
  }
void _resetAllSelections() {
  setState(() {
    _recurrence = '';
    _selectedDateTime = null;
    _weekdays = [];
    _monthDays = [];
    _selectedMonth = null;
    _dateTimeController.clear();
  });
}
 
   Future<void> showReminderDialog(BuildContext context) async {
    if (widget.isDisabled) return;
    await _showInitialRecurrenceOptions(context);
  }
  @override
  Widget build(BuildContext context) {// In the compact version of your build method:
if (widget.compact) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, // Transparent background
        foregroundColor: const Color(0xff1F75EC), // Blue text color
        padding: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 0,
        side: BorderSide(
          color: widget.isDisabled 
              ? Colors.grey[300]!
              : const Color(0xff1F75EC), // Blue border color
          width: 1,
        ),
      ),
      onPressed: widget.isDisabled ? null : () => _showInitialRecurrenceOptions(context),
      child: Text(
        'Set Reminder',
        style: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xff1F75EC), // Blue text color
        ),
      ),
    ),
  );
}

  
     else {
      // Original full-size version
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDisabled 
                ? Colors.grey[300]! 
                : const Color(0xff1F75EC),
            foregroundColor: widget.isDisabled 
                ? Colors.grey[500]
                : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () => _showInitialRecurrenceOptions(context),
          child: Text(
            'Schedule Reminder',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }
  Future<void> _showInitialRecurrenceOptions(BuildContext context) async {
   if (widget.isDisabled) return; 
  setState(() {
    _selectedDateTime = null;
    _weekdays = [];
    _monthDays = [];
    _selectedMonth = null;
    _dateTimeController.clear();
  });

  String? recurrenceResult = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      // Initialize with empty string instead of _recurrence
      String tempRecurrence = '';
      
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              constraints: BoxConstraints(maxWidth: 280),
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                ...['none', 'daily', 'weekly', 'monthly'].map((value) {
                    final String title = value == 'none' ? 'Once' 
                                      : value[0].toUpperCase() + value.substring(1);
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Material(
                        borderRadius: BorderRadius.circular(6),
                        color: tempRecurrence == value 
                            ? Colors.grey.shade100 
                            : Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            setDialogState(() => tempRecurrence = value);
                            Navigator.pop(context, value);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Spacer(),
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Radio<String>(
                                    value: value,
                                    groupValue: tempRecurrence,
                                    onChanged: (String? v) {
                                      setDialogState(() => tempRecurrence = v!);
                                      Navigator.pop(context, v);
                                    },
                                    activeColor: Colors.black,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (recurrenceResult == null) {
    setState(() {
      _recurrence = '';
    });
  } else if (recurrenceResult != null) {
    setState(() {
      _recurrence = recurrenceResult;
    });

    if (recurrenceResult == 'none') {
      await _showOnceReminderDialog(context);
    } else {
      await _showTimeSelectionAndDetails(context);
    }
  }
}
Future<void> _showOnceReminderDialog(BuildContext context) async {
  _selectedDateTime ??= DateTime.now().add(const Duration(hours: 1));
  _updateDateTimeController();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Schedule once',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),  // Removed bottom padding if you want less space before actions
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select date and time for your reminder',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateTimeController,
                  readOnly: true,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  onTap: () async {
                    await _selectDateTime(context);
                    setState(_updateDateTimeController);
                  },
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xff1F75EC),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () async {
                              await _selectDate(context);
                              setState(_updateDateTimeController);
                            },
                            child: Text(
                              'Change date',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xff1F75EC),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () async {
                              await _selectTime(context);
                              setState(_updateDateTimeController);
                            },
                            child: Text(
                              'Change time',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetAllSelections();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          
                          //padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedDateTime != null
                            ? () async {
                                Navigator.pop(context);
                                await _showConfirmationDialog(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xff1F75EC),
                         // padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Schedule',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              actionsPadding: const EdgeInsets.only(
                right: 24,
                bottom: 24,
                left: 24,
                top: 0.40
              ),
            );
          },
        );
      },
    );
  }

Future<void> _showConfirmationDialog(BuildContext context) async {
  String scheduleDescription = _getScheduleDescription();
  
  bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500, // Prevents overflow on large screens
            minWidth: 300, // Ensures good appearance on small screens
          ),
          child: SingleChildScrollView( // Allows scrolling if content is too long
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, 
                          color: Color(0xff1F75EC), size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Confirm Reminder',
                        style: GoogleFonts.urbanist(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1F75EC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Event info section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color.fromARGB(255, 207, 206, 206), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Details',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        _buildInfoRow(Icons.event, widget.eventName),
                        const SizedBox(height: 8),
                        
                        _buildInfoRow(Icons.schedule, 'Reminder schedule:'),
                        const SizedBox(height: 4),
                        
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Text(
                            scheduleDescription,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Confirmation text
                  Text(
                    'Do you want to schedule this reminder?',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1F75EC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  if (confirmed == true) {
    await _scheduleReminder();
  }
}

Widget _buildInfoRow(IconData icon, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: Colors.grey[600]),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ),
    ],
  );
}
  String _getScheduleDescription() {
    if (_selectedDateTime == null) return 'No schedule selected';
    
    final timeStr = DateFormat('h:mm a').format(_selectedDateTime!);
    
    switch (_recurrence) {
      case 'none':
        return 'Once on ${DateFormat('MMMM dd, yyyy').format(_selectedDateTime!)} at $timeStr';
      case 'daily':
        return 'Daily at $timeStr';
      case 'weekly':
        if (_weekdays.isEmpty) return 'Weekly (no days selected) at $timeStr';
        final days = _weekdays.map((day) => _getWeekdayName(int.parse(day))).join(', ');
        return 'Weekly on $days at $timeStr';
      case 'monthly':
        if (_monthDays.isEmpty) return 'Monthly (no days selected) at $timeStr';
        if (_selectedMonth == null) return 'Monthly on ${_monthDays.join(', ')} at $timeStr';
        return 'Monthly on ${_monthDays.join(', ')} of $_selectedMonth at $timeStr';
      default:
        return 'Custom schedule';
    }
  }

  void _updateDateTimeController() {
    if (_selectedDateTime != null) {
      final formattedDateTime = DateFormat('MMM dd, yyyy - h:mm a').format(_selectedDateTime!);
      _dateTimeController.text = formattedDateTime;
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
          builder: (context, child) {
      return Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: Color(0xff1f75ec),  // Header and selection color
            onPrimary: Colors.white,     // Text on header
            onSurface: Colors.black,     // Default text
          ),
          textTheme: TextTheme(
            titleLarge: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w600),
            bodyLarge: GoogleFonts.urbanist(fontSize: 16),
            labelLarge: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        child: child!,
      );
    },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDateTime != null 
            ? TimeOfDay.fromDateTime(_selectedDateTime!)
            : TimeOfDay.now(),
            builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Color(0xff1f75ec),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: TextTheme(
              titleMedium: GoogleFonts.urbanist(fontSize: 16),
              bodyLarge: GoogleFonts.urbanist(fontSize: 16),
              labelLarge: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          child: child!,
        );
      },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
       builder: (context, child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xff1f75ec),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textTheme: TextTheme(
            titleLarge: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w600),
            bodyLarge: GoogleFonts.urbanist(fontSize: 16),
            labelLarge: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        child: child!,
      );
    },
    );

    if (pickedDate != null && _selectedDateTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime!.hour,
          _selectedDateTime!.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null 
          ? TimeOfDay.fromDateTime(_selectedDateTime!)
          : TimeOfDay.now(),
              builder: (context, child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xff1F75EC), // Active color
            onPrimary: const Color.fromARGB(255, 248, 246, 246),    // Text color on primary
            onSurface: Colors.black,   // Default text color
          ),
          textTheme: TextTheme(
            titleMedium: GoogleFonts.urbanist(
              fontSize: 16,
              color: Colors.black,
            ),
            bodyLarge: GoogleFonts.urbanist(
              fontSize: 16,
              color: Colors.black,
            ),
            labelLarge: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        child: child!,
      );
    },
    );

    if (pickedTime != null && _selectedDateTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime!.year,
          _selectedDateTime!.month,
          _selectedDateTime!.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _showTimeSelectionAndDetails(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: Color(0xff1F75EC),  // Blue header
            onPrimary: const Color.fromARGB(255, 245, 240, 240),     // White header text
            onSurface: Colors.black,     // Black text for time entries
          ),
          textTheme: TextTheme(
            titleMedium: GoogleFonts.urbanist(fontSize: 16),
            bodyLarge: GoogleFonts.urbanist(fontSize: 16),
            labelLarge: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child: child!,
      );
    },
    );

    if (pickedTime == null) {
    // User cancelled time selection - reset everything
    _resetAllSelections();
    return;
  }

  if (_recurrence == 'daily') {
    setState(() {
      _selectedDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
    await _showConfirmationDialog(context);
  } 
  else if (_recurrence == 'weekly') {
    await _showWeeklyOptions(context, pickedTime);
  }
  else if (_recurrence == 'monthly') {
    await _showMonthlyOptions(context, pickedTime);
  }
}
Future<void> _showWeeklyOptions(BuildContext context, TimeOfDay time) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Weekdays',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose the days for your reminder',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(7, (index) {
                      bool isSelected = _weekdays.contains(index.toString());
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _weekdays.remove(index.toString());
                            } else {
                              _weekdays.add(index.toString());
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected 
                                ? Border.all(
                                    color: Colors.blue[300]!,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Text(
                            _getWeekdayName(index),
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.blue[700] : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  // Add this visibility widget to show warning when trying to submit with no days selected
                  Visibility(
                    visible: _weekdays.isEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Please select at least one weekday',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetAllSelections();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _weekdays.isNotEmpty ? () {
                          setState(() {
                            _selectedDateTime = DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                              time.hour,
                              time.minute,
                            );
                          });
                          Navigator.pop(context);
                          _showConfirmationDialog(context);
                        } : null, // Disable button if no weekdays selected
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _weekdays.isNotEmpty 
                              ? Colors.blue[600] 
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'OK',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
  
 
 Future<void> _showMonthlyOptions(BuildContext context, TimeOfDay time) async {
  _selectedMonth = _months[DateTime.now().month - 1];
  _updateAvailableDays(DateTime.now().month, DateTime.now().year);

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Monthly Schedule',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Month Selection
                  Text(
                    'Select Month',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      items: _months.map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(
                            month,
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedMonth = newValue;
                            final monthIndex = _months.indexOf(newValue) + 1;
                            _updateAvailableDays(monthIndex, DateTime.now().year);
                            _monthDays = []; // Clear selected days when month changes
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Days Selection
                  Text(
                    'Select Days',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 10),
                  
                  // Warning message for no days selected
                  Visibility(
                    visible: _monthDays.isEmpty,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Please select at least one day',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableDays.map((day) {
                          final isSelected = _monthDays.contains(day.toString());
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _monthDays.remove(day.toString());
                                } else {
                                  _monthDays.add(day.toString());
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.blue.shade100
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.blue.shade300
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                day.toString(),
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected 
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetAllSelections();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _monthDays.isNotEmpty ? () {
                          setState(() {
                            _selectedDateTime = DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                              time.hour,
                              time.minute,
                            );
                          });
                          Navigator.pop(context);
                          _showConfirmationDialog(context);
                        } : null, // Disable button if no days selected
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _monthDays.isNotEmpty 
                              ? Colors.blue.shade600 
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
  void _updateAvailableDays(int month, int year) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    setState(() {
      _availableDays = List<int>.generate(daysInMonth, (i) => i + 1);
    });
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 0: return 'Sun';
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      default: return '';
    }
  }

  String _generateCronSchedule() {
    if (_selectedDateTime == null) return '* * * * *';

    final minute = _selectedDateTime!.minute;
    final hour = _selectedDateTime!.hour;

    switch (_recurrence) {
      case 'none':
        return '$minute $hour ${_selectedDateTime!.day} ${_selectedDateTime!.month} *'; // Specific date and time (once)
      case 'daily':
        return '$minute $hour * * *'; // Every day at this time
      case 'weekly':
        if (_weekdays.isEmpty) {
          return '$minute $hour * * *'; // Default to every day if no days selected
        } else {
          return '$minute $hour * * ${_weekdays.join(',')}'; // Weekly on selected days
        }
      case 'monthly':
        if (_monthDays.isEmpty) {
          return '$minute $hour 1 * *'; // Default to 1st of month if no days selected
        } else {
          final monthIndex = _selectedMonth != null 
              ? _months.indexOf(_selectedMonth!) + 1 
              : DateTime.now().month;
          return '$minute $hour ${_monthDays.join(',')} $monthIndex *'; // Monthly on selected days of selected month
        }
      default:
        return '* * * * *'; // Default (every minute)
    }
  }

  Future<void> _scheduleReminder() async {
    try {
      final cronSchedule = _generateCronSchedule();
      
      final result = await scheduleUserReminders(
        widget.eventId,
        cronSchedule,
        widget.currentUserPhone,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder scheduled successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> scheduleUserReminders(
    String eventId, 
    String cronSchedule,
    String userId,
  ) async {
    try {
      print('Scheduling with cron: $cronSchedule');

      final response = await http.post(
        Uri.parse('https://us-central1-eventsapp-ec193.cloudfunctions.net/scheduleUserReminder'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'eventId': eventId,
          'cronSchedule': cronSchedule,
          'userId': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || (data['success'] as bool?) != true) {
        throw Exception(data['message'] ?? 'Failed to schedule notifications');
      }

      return data;
    } catch (error) {
      print('Error scheduling notifications: $error');
      rethrow;
    }
  }
}