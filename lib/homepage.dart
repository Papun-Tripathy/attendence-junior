import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:test_fingerprint/create_class_page.dart';
import 'package:test_fingerprint/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Auth"),
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              "Welcome",
              style: TextStyle(fontSize: 28),
            ),
            const Text(
              "Welcome to the attendence app, here we can able to manage each and every class attendence for students",
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Get.to(() => ClassAttendenceCreatePage());
              },
              child: Text("Teacher's App"),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                Get.to(() => LoginPage());
              },
              child: Text("Student's App"),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
