import 'package:flutter/material.dart';

class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();

  static const Color background = Color(0xFF03132D);
  static const Color cardColor = Color(0xFF0D2440);
  static const Color primary = Color(0xFF19D8F4);
  static const Color secondaryText = Color(0xFFB8C8D8);

  String gender = 'Male';
  DateTime? scanDate;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> selectScanDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: primary,
              onPrimary: background,
              surface: cardColor,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: background),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        scanDate = selectedDate;
      });
    }
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: secondaryText),
      hintStyle: TextStyle(color: secondaryText.withOpacity(0.55)),
      prefixIcon: Icon(icon, color: primary, size: 21),
      filled: true,
      fillColor: const Color(0xFF102B49),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary.withOpacity(0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  void continueToUpload() {
    if (!_formKey.currentState!.validate()) return;

    if (scanDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select MRI scan date'),
          backgroundColor: Color(0xFFB45309),
        ),
      );
      return;
    }

    final patientDetails = {
      'name': nameController.text.trim(),
      'age': ageController.text.trim(),
      'gender': gender,
      'scanDate':
          '${scanDate!.day.toString().padLeft(2, '0')}/'
          '${scanDate!.month.toString().padLeft(2, '0')}/'
          '${scanDate!.year}',
    };

    Navigator.pop(context, patientDetails);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 65,
        title: const Text(
          'Patient Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spacing = (constraints.maxHeight * 0.035).clamp(18.0, 28.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: primary.withOpacity(0.3),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.28),
                                    blurRadius: 22,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: primary.withOpacity(0.08),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: nameController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: fieldDecoration(
                                      label: 'Patient Name',
                                      hint: 'Enter full name',
                                      icon: Icons.person_outline,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter patient name';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: spacing),
                                  TextFormField(
                                    controller: ageController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    decoration: fieldDecoration(
                                      label: 'Age',
                                      hint: 'Enter age',
                                      icon: Icons.calendar_today_outlined,
                                    ),
                                    validator: (value) {
                                      final age = int.tryParse(value ?? '');
                                      if (age == null ||
                                          age < 1 ||
                                          age > 120) {
                                        return 'Please enter a valid age';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: spacing),
                                  DropdownButtonFormField<String>(
                                    value: gender,
                                    dropdownColor: cardColor,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    decoration: fieldDecoration(
                                      label: 'Gender',
                                      icon: Icons.people_outline,
                                    ),
                                    items: ['Male', 'Female', 'Other']
                                        .map(
                                          (item) => DropdownMenuItem(
                                            value: item,
                                            child: Text(item),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => gender = value);
                                      }
                                    },
                                  ),
                                  SizedBox(height: spacing),
                                  InkWell(
                                    onTap: selectScanDate,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InputDecorator(
                                      decoration: fieldDecoration(
                                        label: 'MRI Scan Date',
                                        icon: Icons.calendar_month_outlined,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              scanDate == null
                                                  ? 'Select MRI scan date'
                                                  : '${scanDate!.day.toString().padLeft(2, '0')}/'
                                                        '${scanDate!.month.toString().padLeft(2, '0')}/'
                                                        '${scanDate!.year}',
                                              style: TextStyle(
                                                color: scanDate == null
                                                    ? secondaryText
                                                    : Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        SizedBox(height: spacing),

                        // Continue Button
                        SizedBox(
                          height: 58,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primary.withValues(alpha: 0.82),
                                  const Color(
                                    0xFF168CBF,
                                  ).withValues(alpha: 0.72),
                                  const Color(
                                    0xFF0D2440,
                                  ).withValues(alpha: 0.94),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.42),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 7),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: continueToUpload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue to MRI Upload',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(Icons.arrow_forward_rounded, size: 21),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
