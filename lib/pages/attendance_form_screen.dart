import 'package:flutter/material.dart';

class AttendanceFormScreen extends StatelessWidget {
  const AttendanceFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -178,
                      child: Container(
                        height: 320,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2FC0A7),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(260),
                            bottomRight: Radius.circular(260),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 34,
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2FC0A7),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 46,
                              color: Color(0xFFC2C2C2),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2FC0A7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: const [
                    _FormField(label: 'Full Name'),
                    SizedBox(height: 14),
                    _FormField(label: 'Email'),
                    SizedBox(height: 14),
                    _FormField(label: 'Class'),
                    SizedBox(height: 14),
                    _FormField(label: 'Section'),
                    SizedBox(height: 14),
                    _FormField(label: 'Roll No.'),
                    SizedBox(height: 14),
                    _FormField(label: 'Email'),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E56CF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add to contact',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;

  const _FormField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter Something...',
            hintStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9598CA),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(
                color: Color(0xFF86A1FF),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: const BorderSide(
                color: Color(0xFF1E56CF),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
