import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:geolocator/geolocator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    initiateAuth();
    super.initState();
  }

  final LocalAuthentication auth = LocalAuthentication();
  bool sucessfulLogin = false;
  late Position? pos;

  initiateAuth() async {
    
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    print(canAuthenticateWithBiometrics);
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    print(canAuthenticate);
    setState(() {});
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please verify your identity',
        options:
            const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if(!didAuthenticate ){
        exit(0);
      }
      setState(() {
        sucessfulLogin = didAuthenticate;
      });
      pos = await _determinePosition();
      print("Position is");
      print(pos);
    } on PlatformException {
      //
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  createNewClass() {
    CollectionReference classes =
        FirebaseFirestore.instance.collection('classes');
    classes.add({"isActive": true, "createdAt": FieldValue.serverTimestamp()});
  }

  registerForClass(
    String classId,
    String deviceId,
  ) {
    CollectionReference classes =
        FirebaseFirestore.instance.collection('classes');
    DocumentReference cls = classes.doc(classId);

    classes.snapshots().listen((event) {
      print(event.docs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        width: double.infinity,
        child: Column(
          children: [
            if (sucessfulLogin)
              Column(
                children: [
                  TextButton(
                      onPressed: createNewClass,
                      child: Text("start Attendence"))
                ],
              ),
            const CircularProgressIndicator()
          ],
        ),
      ),
    );
  }
}
