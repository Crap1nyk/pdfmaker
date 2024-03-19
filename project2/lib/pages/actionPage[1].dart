import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

class Firstpage extends StatefulWidget {
  @override
  _FirstpageState createState() => _FirstpageState();
}

class _FirstpageState extends State<Firstpage> {
  final picker = ImagePicker();
  List<File> image = [];
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          image.length == 0
              ? Center(
                  child: Container(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            'Select Image From Camera or Gallery',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color.fromARGB(255, 6, 6, 6),
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Image.file(image.last),
          Align(
            alignment: Alignment(-0.7, 0.7),
            child: FloatingActionButton(
              elevation: 0.0,
              child: new Icon(
                Icons.image,
              ),
              backgroundColor: Color.fromARGB(255, 197, 206, 166),
              onPressed: getImageFromGallery,
            ),
          ),
          Align(
            alignment: Alignment(0.7, 0.7),
            child: FloatingActionButton(
              elevation: 0.0,
              child: new Icon(
                Icons.camera,
              ),
              backgroundColor: Color.fromARGB(255, 197, 206, 166),
              onPressed: getImageFromCamera,
            ),
          ),
          Align(
            alignment: Alignment(0.0, 0.7),
            child: FloatingActionButton(
              elevation: 0.0,
              child: new Icon(
                Icons.delete,
              ),
              backgroundColor: Color.fromARGB(255, 197, 206, 166),
              onPressed: removeImage,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onOKPressed,
        tooltip: 'OK',
        child: Icon(Icons.done),
      ),
    );
  }

  getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    File? img;
    if (pickedFile != null) {
      img = await cropCustomImg(pickedFile);
    }
    setState(() {
      if (pickedFile != null) {
        image.add(File(img?.path ?? pickedFile.path));
      } else {
        print('No image selected');
      }
    });
  }

  getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    File? img;
    if (pickedFile != null) {
      img = await cropCustomImg(pickedFile);
    }
    setState(() {
      if (pickedFile != null) {
        image.add(File(img?.path ?? pickedFile.path));
      } else {
        print('No image selected');
      }
    });
    await _initializeControllerFuture;
    _toggleFlash();
  }

  removeImage() {
    setState(() {
      if (image.isNotEmpty) {
        image.removeLast();
      } else {
        print('No image to remove');
      }
    });
  }

  Future<File?> cropCustomImg(XFile img) async {
    File? image = await ImageCropper().cropImage(
      sourcePath: img.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      androidUiSettings: const AndroidUiSettings(lockAspectRatio: false),
    );
    return image;
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
      _controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  void _onOKPressed() async {
    // final croppedImage = await cropController.croppedImage();
    // if (croppedImage != null) {
    // setState(() {
    //   image.clear();
    //   // Convert Uint8List to File
    //   image.add(
    //       File.fromRawPath(Uint8List.fromList(croppedImage as List<int>)));
    //   // image.add(File.fromRawPath(Uint8List.fromList(croppedImage as List<int>)));
    // });
    // } else {
    //   print('No image selected');
    // }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
