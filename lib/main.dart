import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading;
  File _image;
  List _output;

  loadMLModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    loadMLModel().then((value) {
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Covid19 Detector'),
      ),
      body: _isLoading
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.all(26.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(6.0))),
                    child: _image == null ? Container(height: 200) : Image.file(_image),
                  ),
                  //_image == null ? Container() : Image.file(_image),
                  Container(
                    margin: const EdgeInsets.only(left: 26.0),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 15.0,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500),
                        children: <TextSpan>[
                          TextSpan(text: 'Predicted : '),
                          _output == null
                              ? TextSpan(text: 'None')
                              : TextSpan(
                                  text: '${_output[0]["label"]} Case',
                                  style: TextStyle(
                                      color: _output[0]["label"] == 'Covid' ? Colors.red : Colors.green),
                                )
                        ],
                      ),
                    ),
                  ),
                  /*Container(
                    margin: const EdgeInsets.only(left: 26.0),
                    child: _output == null
                        ? Text('Predicted: None',
                            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500))
                        : Text('Predicted: ${_output[0]["label"]}',
                            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                  ),*/
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: chooseImage,
        tooltip: 'Browse X-Ray Image',
        child: Icon(Icons.image),
      ),
    );
  }

  void chooseImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    setState(() {
      _isLoading = true;
      _image = File(pickedFile.path);
    });
    runModelOnImage(_image);
  }

  runModelOnImage(File image) async {
    var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 2,
        imageMean: 127.5,
        imageStd: 127.5,
        threshold: 0.5);
    setState(() {
      _isLoading = false;
      _output = output;
    });
  }
}
