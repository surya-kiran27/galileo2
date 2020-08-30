import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:galileo2/googleDrive.dart';
import 'package:galileo2/main.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_widget/zoom_widget.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

const directoryName = 'Galileo';

class Edit extends StatefulWidget {
  final File image;

  const Edit({Key key, this.image}) : super(key: key);

  @override
  _EditState createState() => _EditState();
}

class _EditState extends State<Edit> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _zoomWidget = GlobalKey();
  ui.Image _image;
  double xPos = 0.0;
  double yPos = 0.0;
  List<Circle> circle = new List();
  double temp, humidity;
  String ip_address = "";
  bool _dragging = false;
  double _lowerValue = 40;
  String fileName = "";
  LongPressStartDetails _tapPosition;
  double x;
  final drive = GoogleDrive();
  final _random = new Random();

  @override
  void initState() {
    _loadImage();
    _loadStorage();
  }

  int next(int min, int max) => min + _random.nextInt(max - min);
  _loadStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.getString("ipaddress"));
    if (prefs.containsKey("ipaddress")) {
      print(prefs.getString("ipaddress"));
      setState(() {
        ip_address = prefs.getString("ipaddress");
      });
    }
  }

  _loadImage() async {
    try {
      final Uint8List bytes = await widget.image.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.Image image = (await codec.getNextFrame()).image;
      setState(() {
        _image = image;
      });
    } catch (e) {
      print(e);
    }
  }

  _getSensorData() async {
    if (ip_address != null && ip_address.length > 0) {
      if (ip_address.toLowerCase() == "demo") {
        double randomTemp = next(10, 40).toDouble();
        setState(() {
          temp = randomTemp;
        });
        showInSnackBar("Temp is " + randomTemp.toString());
        return;
      }
      try {
        Dio dio = new Dio(); // with default Options
        dio.options.receiveTimeout = 3000;
        dio.options.connectTimeout = 3000;
        Response response = await dio.get("http://$ip_address/GetData");
        var decoded = jsonDecode(response.data);
        if (decoded['status'] = true) {
          print(decoded['temp']);
          showInSnackBar(
              "Data received, Temp is: " + decoded['temp'].toString());
          setState(() {
            temp = decoded['temp'].toDouble();
          });
        } else {
          showInSnackBar("Failed to receive data");
        }
      } on DioError catch (e) {
        print(e);
        if (e.type == DioErrorType.CONNECT_TIMEOUT) {
          print("timed out");
          showInSnackBar("Timed out..Try again");
        }
        if (e.type == DioErrorType.RECEIVE_TIMEOUT) {
          showInSnackBar("Timed out..Try again");
        }
      }
    } else {
      showInSnackBar("Enter valid ip Address");
      print("Enter valid ip Address");
    }
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
        content: new Text(value),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)))));
  }

  void saveImage() async {
    showInSnackBar("Saving image...");
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    ImageEditor painter = ImageEditor(this._image, this.circle);
    Size s = new Size(_image.width.toDouble(), _image.height.toDouble());
    painter.paint(canvas, s);
    ui.Image img =
        await recorder.endRecording().toImage(_image.width, _image.height);

    final pngBytes = await img.toByteData(format: ImageByteFormat.png);
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    try {
      if (status.isGranted) {
        print("check saving");
        String directory = await ExtStorage.getExternalStoragePublicDirectory(
            ExtStorage.DIRECTORY_DOCUMENTS);
        String path = directory + "/Galileo";

        await Directory('$path').create(recursive: true);

        File upload = await File('$path/${fileName}.png')
            .writeAsBytes(pngBytes.buffer.asInt8List());
        showInSnackBar("Saved at " + upload.path);
        showInSnackBar("Uploading please wait...");
        var res = await drive.upload(upload);
        if (res != null)
          showInSnackBar("File uploaded to drive ");
        else {
          showInSnackBar("Failed to upload");
        }
      }
    } catch (e) {
      print(e);
      showInSnackBar("Failed to get downloads directory");
    }
  }

  showBackAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("YES"),
      onPressed: () async {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MyApp()));
      },
    );

    Widget closeButton = FlatButton(
      child: Text("NO"),
      onPressed: () async {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Are you sure ?"),
      actions: [closeButton, okButton],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showIpAddressAlertDialog() {
    // set up the button
    Widget okButton = FlatButton(
        child: Text("Done"),
        onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString("ipaddress", ip_address);
          Navigator.of(context, rootNavigator: true).pop();
        });
    Widget field = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextFormField(
            onChanged: (text) {
              setState(() {
                ip_address = text;
              });
            },
            initialValue: ip_address,
            decoration: InputDecoration(
              labelText: 'IP ADDRESS',
            ),
          ),
          Text("Enter 'demo' for demo mode")
        ],
      ),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Enter IP ADDRESS"),
      actions: [okButton],
      content: field,
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showCircleRadiusAlertDialog() {
    // set up the button
    Widget okButton = FlatButton(
      child: Text("Done"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
    Widget field = SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            height: 200,
            width: 300,
            child: FlutterSlider(
              values: [_lowerValue],
              max: 300,
              min: 10,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                setState(() {
                  _lowerValue = lowerValue;
                });
              },
              jump: true,
            ),
          ),
        ],
      ),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Circle radius"),
      actions: [okButton],
      content: field,
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showSaveFileAlertDialog() {
    Widget okButton = FlatButton(
        child: Text("Upload"),
        onPressed: () async {
          if (fileName != "") {
            Navigator.of(context, rootNavigator: true).pop();
            saveImage();
          } else {
            showInSnackBar("Invalid file name");
          }
        });
    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
    Widget field = SingleChildScrollView(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("File Name"),
            TextField(
              onChanged: (text) {
                setState(() {
                  fileName = text;
                });
              },
            )
          ]),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Enter File Name"),
      actions: [cancelButton, okButton],
      content: field,
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  dispose() {
    // you need this
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      resizeToAvoidBottomPadding: false,
      body: Container(
          child: _image != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ButtonBar(
                        alignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          FlatButton(
                            color: Colors.black,
                            child: Text("Back",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              showBackAlertDialog(context);
                            },
                          ),
                          FlatButton(
                            color: Colors.amber,
                            child: Text("Reset Marker",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              setState(() {
                                xPos = _image.width / 2;
                                yPos = _image.height / 2;
                              });
                            },
                          ),
                          FlatButton(
                            color: Colors.blue,
                            child: Text("Get Data"),
                            onPressed: () {
                              _getSensorData();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Zoom(
                          key: _zoomWidget,
                          doubleTapZoom: true,
                          initZoom: 0.0,
                          zoomSensibility: 8,
                          backgroundColor: Colors.transparent,
                          width: _image.width.toDouble(),
                          height: _image.height.toDouble(),
                          child: GestureDetector(
                            onLongPressStart: (details) {
                              setState(() {
                                _tapPosition = details;
                              });
                              print(details.globalPosition);
                            },
                            onLongPress: () {
                              print("check");
                              xPos = _tapPosition.localPosition.dx -
                                  _image.height.toDouble() * 0.03;
                              yPos = _tapPosition.localPosition.dy -
                                  _image.height.toDouble() * 0.05;
                            },
                            child: Stack(
                              fit: StackFit.expand, // add this
                              overflow: Overflow.visible,
                              children: <Widget>[
                                SizedBox(
                                  width: _image.width.toDouble(),
                                  height: _image.height.toDouble(),
                                  child: CustomPaint(
                                    size: Size(_image.width.toDouble(),
                                        _image.height.toDouble()),
                                    painter: ImageEditor(_image, circle),
                                    child: Container(),
                                  ),
                                ),
                                Positioned(
                                  top: yPos,
                                  left: xPos,
                                  child: Icon(Icons.location_on,
                                      color: Colors.red,
                                      size: _image.height.toDouble() * 0.05),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ButtonBar(
                      buttonTextTheme: ButtonTextTheme.accent,
                      alignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FlatButton(
                          child: Icon(Icons.settings_remote),
                          onPressed: () {
                            showIpAddressAlertDialog();
                          },
                        ),
                        FlatButton(
                          child: Icon(Icons.adjust),
                          onPressed: () {
                            showCircleRadiusAlertDialog();
                          },
                        ),
                        FlatButton(
                          child: Icon(Icons.undo),
                          onPressed: () {
                            setState(() {
                              if (circle.length >= 1)
                                circle.removeLast();
                              else {
                                showInSnackBar("Points are empty");
                              }
                            });
                          },
                        ),
                        FlatButton(
                          child: Icon(Icons.add_location),
                          onPressed: () {
                            double xPosUpdated =
                                xPos + _image.height.toDouble() * 0.025;
                            double yPosUpdated =
                                yPos + _image.height.toDouble() * 0.045;
                            if (temp != null) {
                              setState(() {
                                if (temp <= 15 && temp >= 10) {
                                  circle.add(Circle(
                                      Colors.blue[300],
                                      Offset(xPosUpdated, yPosUpdated),
                                      _lowerValue,
                                      temp));
                                } else if (temp <= 20 && temp > 15) {
                                  circle.add(Circle(
                                      Colors.blue,
                                      Offset(xPosUpdated, yPosUpdated),
                                      _lowerValue,
                                      temp));
                                } else if (temp <= 25 && temp > 20) {
                                  circle.add(Circle(
                                      Colors.blue[700],
                                      Offset(xPosUpdated, yPosUpdated),
                                      _lowerValue,
                                      temp));
                                } else if (temp <= 30 && temp > 25) {
                                  circle.add(Circle(
                                      Colors.red,
                                      Offset(xPosUpdated, yPosUpdated),
                                      _lowerValue,
                                      temp));
                                } else if (temp <= 35 && temp > 30) {
                                  circle.add(Circle(
                                      Colors.red[700],
                                      Offset(xPosUpdated, yPosUpdated),
                                      _lowerValue,
                                      temp));
                                } else if (temp <= 45 && temp > 35) {
                                  circle.add(Circle(
                                      Colors.red[900],
                                      Offset(xPosUpdated, yPosUpdated),
                                      _lowerValue,
                                      temp));
                                }
                              });
                            } else {
                              showInSnackBar("Please click on Get Data first");
                            }
                          },
                        ),
                        FlatButton(
                          child: Icon(Icons.save),
                          onPressed: () async {
                            showSaveFileAlertDialog();
                          },
                        )
                      ],
                    )
                  ],
                )
              : Center(
                  child: Container(
                    color: Colors.lightBlue,
                    child: Center(child: Text("Loading...")),
                  ),
                )),
    );
  }
}

class Circle {
  final Color color;
  final Offset offset;
  final double radius;
  final double temp;
  Circle(this.color, this.offset, this.radius, this.temp) : super();
}

class ImageEditor extends CustomPainter {
  ui.Image image;

  final List<Circle> circle;
  Picture picture;
  ImageEditor(this.image, this.circle) : super();

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()..color = Colors.yellow;
    canvas.drawImage(image, Offset.zero, paint);
    double avg = 0;
    for (var item in circle) {
      Paint circlePaint = new Paint()..color = item.color;
      avg += item.temp;
      final TextPainter textPainter = TextPainter(
          text: TextSpan(
              text: "" + item.temp.toString() + "\u00B0 C",
              style:
                  TextStyle(color: Colors.white, fontSize: item.radius * 0.4)),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: size.width - 100.0);
      canvas.drawCircle(item.offset, item.radius, circlePaint);
      textPainter.paint(
          canvas,
          Offset(item.offset.dx - item.radius * 0.5,
              item.offset.dy - item.radius * 0.2));
    }
    if (circle.length > 0) {
      avg /= circle.length;
      final TextPainter textPainter2 = TextPainter(
          text: TextSpan(
              text: "Average temp is: " +
                  avg.floor().toInt().toString() +
                  "\u00B0 C",
              style: TextStyle(
                  color: Colors.black, fontSize: image.height * 0.02)),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: size.width - 100.0);
      textPainter2.paint(canvas,
          Offset(0, size.height.toDouble() - size.height.toDouble() * 0.04));
    }
    @override
    bool hitTest(Offset position) {
      // TODO: implement hitTest
      return super.hitTest(position);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
