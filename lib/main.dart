import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:galileo2/edit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:ui';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galileo',
      theme: ThemeData(
        primaryColor: Colors.amber[200],
      ),
      home: MyHomePage(title: 'Galileo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  File _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = File(pickedFile.path);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Edit(
                    image: _image,
                  )));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Sample Floor Plan",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset("./assets/images/sampleFloorPlan.png"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: RaisedButton(
                  color: Colors.green[400],
                  focusColor: Colors.green[200],
                  onPressed: () {
                    getImage();
                  },
                  child: Text(
                    "Upload floor plan",
                    style: TextStyle(fontSize: 20, fontFamily: "Roboto"),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}