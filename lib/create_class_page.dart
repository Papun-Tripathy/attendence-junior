import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/route_manager.dart';
import 'package:unique_identifier/unique_identifier.dart';

class ClassAttendenceCreatePage extends StatefulWidget {
  const ClassAttendenceCreatePage({super.key});

  @override
  State<ClassAttendenceCreatePage> createState() =>
      _ClassAttendenceCreatePageState();
}

class _ClassAttendenceCreatePageState extends State<ClassAttendenceCreatePage> {
  String name = "";
  TextEditingController nameController = TextEditingController();
  List<Map<String, dynamic>>? allClasses;

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

  createClass() async {
    if (name.isEmpty) {
      return;
    }
    CollectionReference classes =
        FirebaseFirestore.instance.collection('classes');
    Position? pos;
    try {
      pos = await _determinePosition();
    } catch (e) {
      //
    }
    var data = {
      "className": name,
      "deviceId": await UniqueIdentifier.serial,
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp()
    };
    if (pos != null) {
      data["latitude"] = pos.latitude;
      data["longitude"] = pos.longitude;
      data["altitude"] = pos.altitude;
      data["time"] = pos.timestamp;
    }
    DocumentReference newObj = await classes.add(data);
    setState(() {
      name = "";
      nameController.text = "";
    });
    getAllClass();
    return newObj;
  }

  updateClassState(Map<String, dynamic> obj, bool state) async {
    // DocumentReference obj;
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(obj['id'])
        .update({"isActive": state});
    getAllClass();
  }

  getAllClass() async {
    QuerySnapshot<Map<String, dynamic>> allData = await FirebaseFirestore
        .instance
        .collection('classes')
        .orderBy("createdAt", descending: true)
        .get();
    allClasses = [];
    allClasses = allData.docs.map((atd) {
      String id = atd.id;
      Map<String, dynamic> data = atd.data();
      return {"id": id, ...data};
    }).toList();
    setState(() {});
  }

  @override
  void initState() {
    getAllClass();
    super.initState();
  }

  openStudentsModal(Map<String, dynamic> obj) async {
    var listData = await FirebaseFirestore.instance
        .collection('classes')
        .doc(obj["id"])
        .collection("Attendence")
        .get();
    Get.dialog(Center(
      child: Container(
        child: Column(
          children: [
            Text("Students"),
            ListView.builder(
              itemCount: listData.docs.length,
              itemBuilder: (context, index) {
                var data = listData.docs[index];
                return Container(
                    child: Row(
                  children: [
                    Text(data["time"]),
                    const Spacer(),
                    Text(data.id),
                  ],
                ));
              },
            )
          ],
        ),
      ),
    ));
  }

  getEnrolledUserData(Map<String, dynamic> obj) async {
    var listData = await FirebaseFirestore.instance
        .collection('classes')
        .doc(obj["id"])
        .collection("Attendence")
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Attendence"),
        ),
        body: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Name",
              ),
              controller: nameController,
              onChanged: (value) {
                setState(() {
                  name = value;
                });
              },
            ),
            const SizedBox(height: 10),
            if (allClasses != null && allClasses!.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: allClasses!.length,
                  itemBuilder: (context, index) {
                    var height = 300;
                    Map<String, dynamic> data = allClasses![index];
                    print(data['id']);
                    String date =
                        (data["createdAt"] as Timestamp).toDate().toString();
                    bool isExpanded = false;
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
                              Switch(
                                  value: data["isActive"],
                                  onChanged: (val) {
                                    updateClassState(data, val);
                                  })
                            ],
                          ),
                          Row(
                            children: [
                              Text("Created At"),
                              Spacer(),
                              Text(date.split('.')[0]),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: createClass,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}
