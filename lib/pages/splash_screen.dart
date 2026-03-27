import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Get.offAllNamed(AppRoutes.choose);
    });

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: -width * 0.35,
            top: -180,
            child: Container(
              width: width * 1.7,
              height: 310,
              decoration: const BoxDecoration(
                color: Color(0xFF00BFA5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(260),
                  bottomRight: Radius.circular(260),
                ),
              ),
            ),
          ),
          Positioned(
            right: -width * 0.35,
            bottom: -190,
            child: Container(
              width: width * 1.7,
              height: 330,
              decoration: const BoxDecoration(
                color: Color(0xFF1E88E5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(260),
                  topRight: Radius.circular(260),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    size: 78,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(height: 19),
                const Text(
                  'School Management System',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Attendance, Grades, Timetable, and More',
                  style: TextStyle(fontSize: 16, color: Color(0xFF546E7A)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                const Text(
                  'Powered by PR Rehman Ali',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00897B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
