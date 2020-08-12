import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:galileo2/googleDrive.dart';
import 'package:googleapis/cloudshell/v1.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:zoom_widget/zoom_widget.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;

const directoryName = 'Galileo';

class Edit extends StatefulWidget {
  final File image;

  const Edit({Key key, this.image}) : super(key: key);

  @override
  _EditState createState() => _EditState();
}

class _EditState extends State<Edit> {
  double width;
  double height;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ui.Image _image;
  double xPos = 0.0;
  double yPos = 0.0;
  List<Circle> circle = new List();
  String _platformVersion = 'Unknown';
  double temp, humidity;
  String ip_address;
  bool _dragging = false;
  double _lowerValue = 40;
  String fileName = "";
  final drive = GoogleDrive();

  @override
  void initState() {
    _loadImage();
  }

  _loadImage() async {
    final Uint8List bytes = await widget.image.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.Image image = (await codec.getNextFrame()).image;
    setState(() {
      _image = image;
    });
  }

  _getSensorData() async {
    if (ip_address != null && ip_address.length > 0) {
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

  @override
  Widget build(BuildContext context) {
    setState(() {
      height = MediaQuery.of(context).size.height;
      width = MediaQuery.of(context).size.width;
    });

    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            ButtonBar(
              buttonPadding: EdgeInsets.all(5),
              children: <Widget>[
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
            _image != null
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: width,
                      height: height * 0.80,
                      child: Zoom(
                        initZoom: 0,
                        backgroundColor: Colors.transparent,
                        width: _image.width.toDouble(),
                        height: _image.height.toDouble(),
                        child: Stack(
                          children: <Widget>[
                            CustomPaint(
                              size: Size(width, height * 0.80),
                              painter: ImageEditor(_image, circle),
                              child: Container(),
                            ),
                            Positioned(
                              top: yPos,
                              left: xPos,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onPanStart: (details) => {
                                  _dragging = true,
                                },
                                onPanEnd: (details) {
                                  _dragging = false;
                                },
                                onPanUpdate: (details) {
                                  if (_dragging) {
                                    setState(() {
                                      xPos += details.delta.dx;
                                      yPos += details.delta.dy;
                                    });
                                  }
                                },
                                child: Icon(Icons.location_on,
                                    color: Colors.red,
                                    size: _image.height * 0.1),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                : SizedBox.shrink(),
            ButtonBar(
              buttonTextTheme: ButtonTextTheme.accent,
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                // FlatButton(
                //   child: Icon(Icons.undo),
                //   onPressed: () {
                //     setState(() {
                //       if (circle.length >= 1)
                //         circle.removeLast();
                //       else {
                //         showInSnackBar("Points are empty");
                //       }
                //     });
                //   },
                // ),
                FlatButton(
                  child: Icon(Icons.settings_remote),
                  onPressed: () {
                    setState(() {
                      Alert(
                          context: context,
                          title: "Edit IP Address",
                          closeFunction: () {},
                          content: Column(
                            children: <Widget>[
                              TextFormField(
                                onChanged: (text) {
                                  setState(() {
                                    ip_address = text;
                                  });
                                },
                                initialValue: ip_address,
                                validator: (text) {
                                  String zeroTo255 = "(\\d{1,2}|(0|1)\\" +
                                      "d{2}|2[0-4]\\d|25[0-5])";
                                  String regex = zeroTo255 +
                                      "\\." +
                                      zeroTo255 +
                                      "\\." +
                                      zeroTo255 +
                                      "\\." +
                                      zeroTo255;
                                  RegExp regExp = new RegExp(regex);
                                  if (!regExp.hasMatch(text)) {
                                    return 'invalid ip address';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'IP ADDRESS',
                                ),
                              ),
                            ],
                          ),
                          buttons: [
                            DialogButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Done",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              ),
                            )
                          ]).show();
                    });
                  },
                ),
                FlatButton(
                  child: Icon(Icons.adjust),
                  onPressed: () {
                    Alert(
                        context: context,
                        title: "Edit circle radius",
                        closeFunction: () {},
                        content: Column(
                          children: <Widget>[
                            // Container(
                            //   width: 400,
                            //   height: 400,
                            //   child: CustomPaint(
                            //     painter: SampleCircle(_lowerValue),
                            //     child: Container(),
                            //   ),
                            // ),
                            Container(
                              width: 300,
                              height: 200,
                              child: FlutterSlider(
                                values: [_lowerValue],
                                max: 300,
                                min: 10,
                                onDragging:
                                    (handlerIndex, lowerValue, upperValue) {
                                  setState(() {
                                    _lowerValue = lowerValue;
                                  });
                                },
                                jump: true,
                              ),
                            )
                          ],
                        ),
                        buttons: [
                          DialogButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Done",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          )
                        ]).show();
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
                    if (temp != null) {
                      setState(() {
                        if (temp <= 15 && temp >= 10) {
                          circle.add(Circle(
                              Colors.blue[300],
                              Offset(xPos + _image.height * 0.05,
                                  yPos + _image.height * 0.07),
                              _lowerValue,
                              temp));
                        } else if (temp <= 20 && temp > 15) {
                          circle.add(Circle(
                              Colors.blue,
                              Offset(xPos + _image.height * 0.05,
                                  yPos + _image.height * 0.07),
                              _lowerValue,
                              temp));
                        } else if (temp <= 25 && temp > 20) {
                          circle.add(Circle(
                              Colors.blue[700],
                              Offset(xPos + _image.height * 0.05,
                                  yPos + _image.height * 0.07),
                              _lowerValue,
                              temp));
                        } else if (temp <= 30 && temp > 25) {
                          circle.add(Circle(
                              Colors.red,
                              Offset(xPos + _image.height * 0.05,
                                  yPos + _image.height * 0.07),
                              _lowerValue,
                              temp));
                        } else if (temp <= 35 && temp > 30) {
                          circle.add(Circle(
                              Colors.red[700],
                              Offset(xPos + _image.height * 0.05,
                                  yPos + _image.height * 0.07),
                              _lowerValue,
                              temp));
                        } else if (temp <= 45 && temp > 35) {
                          circle.add(Circle(
                              Colors.red[900],
                              Offset(xPos + _image.height * 0.05,
                                  yPos + _image.height * 0.07),
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
                    Alert(
                        context: context,
                        title: "Enter file name",
                        closeFunction: () {},
                        content: Container(
                          height: 200,
                          width: double.maxFinite,
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
                        ),
                        // content: Row(
                        //   children: <Widget>[
                        //     Text("File Name"),
                        //     TextField(
                        //       onChanged: (text) {
                        //         setState(() {
                        //           fileName = text;
                        //         });
                        //       },
                        //     )
                        //   ],
                        // ),
                        buttons: [
                          DialogButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Cancel",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ),
                          DialogButton(
                            onPressed: () async {
                              ui.PictureRecorder recorder =
                                  ui.PictureRecorder();
                              Canvas canvas = Canvas(recorder);
                              print(this.circle.length);
                              ImageEditor painter =
                                  ImageEditor(this._image, this.circle);
                              Size s = new Size(_image.width.toDouble(),
                                  _image.height.toDouble());
                              painter.paint(canvas, s);
                              ui.Image img = await recorder
                                  .endRecording()
                                  .toImage(_image.width, _image.height);

                              final pngBytes = await img.toByteData(
                                  format: ImageByteFormat.png);

                              Directory directory =
                                  await getExternalStorageDirectory();
                              String path = directory.path + "/Download";
                              print(path);
                              await Directory('$path/$directoryName')
                                  .create(recursive: true);

                              File upload = await File('$path/${fileName}.png')
                                  .writeAsBytes(pngBytes.buffer.asInt8List());
                              Navigator.pop(context);
                              showInSnackBar("Uploading please wait...");
                              var res = await drive.upload(upload);
                              if (res != null)
                                showInSnackBar("File uploaded to drive ");
                              else {
                                showInSnackBar("Failed to upload");
                              }
                            },
                            child: Text(
                              "Upload",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ),
                        ]).show();
                  },
                )
              ],
            )
          ],
        ),
      ),
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
  void paintImage(
      ui.Image image, Rect outputRect, Canvas canvas, Paint paint, BoxFit fit) {
    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final FittedSizes sizes = applyBoxFit(fit, imageSize, outputRect.size);
    final Rect inputSubrect =
        Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final Rect outputSubrect =
        Alignment.center.inscribe(sizes.destination, outputRect);
    canvas.drawImageRect(image, inputSubrect, outputSubrect, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint

    Paint paint = new Paint()..color = Colors.yellow;

    final Rect rect = Offset.zero & size;
    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    FittedSizes sizes = applyBoxFit(BoxFit.contain, imageSize, size);
    final Rect inputSubRect =
        Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final Rect outputSubRect =
        Alignment.center.inscribe(sizes.destination, rect);

    canvas.drawImageRect(
      image,
      inputSubRect,
      outputSubRect,
      paint,
    );

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
        ..layout(maxWidth: size.width - 100.0 - 100.0);
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
                  color: Colors.black, fontSize: image.height * 0.05)),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: size.width - 100.0 - 100.0);
      textPainter2.paint(canvas,
          Offset(0, size.height.toDouble() - size.height.toDouble() * 0.1));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// class SampleCircle extends CustomPainter {
//   final double radius;

//   SampleCircle(this.radius) : super();
//   @override
//   void paint(Canvas canvas, Size size) {
//     // TODO: implement paint
//     Paint paint = new Paint()..color = Colors.red;
//     canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
