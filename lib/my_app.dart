import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:test_fingerprint/create_class_page.dart';
import 'package:test_fingerprint/homepage.dart';
import 'package:test_fingerprint/login_page.dart';


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      // home: LoginPage(),
      home: HomePage(),
    );
  }
}