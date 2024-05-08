import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/route_manager.dart';

import 'package:unique_identifier/unique_identifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:geolocator/geolocator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool sucessfulLogin = false;
  late Position? pos;
  List<Map<String, dynamic>>? allClasses;

  @override
  void initState() {
    initiateAuth();
    super.initState();
  }

  initiateAuth() async {
    getAllClass();

    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;

    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    setState(() {});
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please verify your identity',
        options:
            const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!didAuthenticate) {
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

  enrollYourAttendence(Map<String, dynamic> obj) async {
    // if already exists
    DocumentSnapshot<Map<String, dynamic>> docExists = await FirebaseFirestore
        .instance
        .collection('classes')
        .doc(obj['id'])
        .collection("Attendence")
        .doc(await UniqueIdentifier.serial)
        .get();

    if (docExists.exists) {
      return;
    }
    // DocumentReference obj;
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(obj['id'])
        .collection("Attendence")
        .doc(await UniqueIdentifier.serial)
        .set({
      "createdAt": FieldValue.serverTimestamp(),
      "location": {
        "altitude": pos?.altitude ?? 0,
        "latitude": pos?.latitude ?? 0,
        "longitude": pos?.longitude ?? 0,
        "time": pos?.timestamp,
      }
    });
    getAllClass();
  }

  getAllClass() async {
    await FirebaseFirestore.instance
        .collection('classes')
        .snapshots()
        .listen((event) {
      List<QueryDocumentSnapshot<Map<String, dynamic>>> allData = event.docs;
      setState(() {
        allClasses = allData.map((atd) {
          String id = atd.id;
          Map<String, dynamic> data = atd.data();
          print(data);
          return {"id": id, ...data};
        }).toList();
        print(allClasses != null);
      });
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        width: double.infinity,
        child: Column(
          children: [
            if (!sucessfulLogin) const CircularProgressIndicator(),
            const SizedBox(height: 10),
            if (allClasses != null && allClasses!.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: allClasses!.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data = allClasses![index];
                    print(data['id']);
                    String date =
                        (data["createdAt"] as Timestamp).toDate().toString();

                    return Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(6)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(data["className"]),
                              Spacer(),
                            
                              if (data["isActive"])
                                ElevatedButton(
                                    onPressed: () => enrollYourAttendence(data),
                                    child: const Text("Mark Present"))
                              else
                                Text("Attendence Session Over")
                            ],
                          ),
                          Row(
                            children: [
                              Text("Created At"),
                              Spacer(),
                              Text(date.split(":")[0]),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
