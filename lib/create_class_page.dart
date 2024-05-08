import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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


  createClass() async {
    if (name.isEmpty) {
      return;
    }
    CollectionReference classes =
        FirebaseFirestore.instance.collection('classes');
    DocumentReference newObj = await classes.add({
      "createdBy": name,
      "deviceId": await UniqueIdentifier.serial,
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp()
    });
    setState(() {
      name = "";
      nameController.text = "";
    });
    getAllClass();
    return newObj;
  }

  updateClassState(Map<String, dynamic> obj) {
    // DocumentReference obj;
    FirebaseFirestore.instance.collection('classes').doc(obj['id']).update({"isActive": !obj["isActive"]});
  }

  getAllClass() async {
    QuerySnapshot<Map<String, dynamic>> allData =
        await FirebaseFirestore.instance.collection('classes').get();
    allClasses = allData.docs.map((atd) {
      String id = atd.id;
      Map<String, dynamic> data = atd.data();
      print(data);
      return {"id": id, ...data};
    }).toList();
  }

  @override
  void initState() {
    getAllClass();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendence"),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
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
              if (allClasses != null && allClasses!.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: allClasses!.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> data = allClasses![index];

                      return Container(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(data["createdBy"]),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createClass,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
