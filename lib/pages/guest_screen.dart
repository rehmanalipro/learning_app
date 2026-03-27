import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_HomeItem>[
      _HomeItem(
        label: 'Attendance',
        icon: Icons.fact_check_outlined,
        onTap: () => Get.toNamed(AppRoutes.attendanceForm),
      ),
      _HomeItem(label: 'Homework', icon: Icons.corporate_fare_outlined),
      _HomeItem(label: 'Result', icon: Icons.note_alt_outlined),
      _HomeItem(label: 'Exam Routine', icon: Icons.format_list_bulleted),
      _HomeItem(label: 'Solution', icon: Icons.menu_book_outlined),
      _HomeItem(label: 'Notice & Events', icon: Icons.contact_support_outlined),
      _HomeItem(label: 'Add Account', icon: Icons.person_add_alt_1_outlined),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              SizedBox(
                height: 248,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -180,
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
                      top: 18,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2FC0A7),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sentiment_satisfied_alt,
                            size: 92,
                            color: Color(0xFFC8C8C8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E56CF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Welcome Message',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The standard Lorem Ipsum passage\n'
                        'Lorem Ipsum dolor sit amet, consectetur adipisicing elit, sed do\n'
                        'eiusmod tempor incididunt ut labore et dolore magna aliqua,',
                        style: TextStyle(
                          color: Color(0xFFD9E5FF),
                          fontSize: 8.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 14,
                  children: items
                      .map((item) => _HomeTile(item: item))
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final _HomeItem item;

  const _HomeTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tileWidth = (width - 40) / 3;

    return SizedBox(
      width: tileWidth.clamp(92.0, 122.0),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F3),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.icon,
                size: 34,
                color: const Color(0xFF1F54CD),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF202020),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _HomeItem({required this.label, required this.icon, this.onTap});
}
