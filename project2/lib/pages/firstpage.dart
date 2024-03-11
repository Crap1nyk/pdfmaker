import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:camera/camera.dart';
import 'package:crop_image/crop_image.dart';

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

  final cropController = CropController(
    aspectRatio: 0.7,
    defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
  );

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
              : PdfPreview(
                  maxPageWidth: 1000,
                  canChangeOrientation: true,
                  canDebug: false,
                  build: (format) => generateDocument(
                    format,
                    image.length,
                    image,
                  ),
                ),
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
          // Adding CropImage widget with cropController
          if (image.isNotEmpty)
            CropImage(
              controller: cropController,
              image: Image.file(image.last),
              paddingSize: 25.0,
              alwaysMove: true,
              minimumImageSize: 500,
              maximumImageSize: 500,
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
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        image.add(File(pickedFile.path));
      } else {
        print('No image selected');
      }
    });
  }

  getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        image.add(File(pickedFile.path));
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

  Future<Uint8List> applyImageEnhancementToBytes(Uint8List bytes) async {
    // Read the bytes into an image object
    img.Image? image = img.decodeImage(bytes);

    // Apply contrast enhancement
    img.adjustColor(image!, contrast: 3.0);

    // Apply brightness adjustment
    img.adjustColor(image, brightness: 2.0);

    // Apply denoising
    img.gaussianBlur(image, radius: 1);

    // Encode the processed image to bytes
    Uint8List processedBytes = Uint8List.fromList(img.encodePng(image));

    return processedBytes;
  }

  Future<Uint8List> generateDocument(
      PdfPageFormat format, int imageLength, List<File> images) async {
    final doc = pw.Document(pageMode: PdfPageMode.outlines);

    final font1 = await PdfGoogleFonts.openSansRegular();
    final font2 = await PdfGoogleFonts.openSansBold();

    for (var im in images) {
      // Apply image enhancement to image bytes
      final processedBytes =
          await applyImageEnhancementToBytes(im.readAsBytesSync());

      final showimage = pw.MemoryImage(processedBytes);

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: format.copyWith(
              marginBottom: 0,
              marginLeft: 0,
              marginRight: 0,
              marginTop: 0,
            ),
            orientation: pw.PageOrientation.portrait,
            theme: pw.ThemeData.withFont(
              base: font1,
              bold: font2,
            ),
          ),
          build: (context) {
            return pw.Center(
              child: pw.Image(showimage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    return await doc.save();
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
      _controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    });
  }

 void _onOKPressed() {
  cropController.croppedImage().then((croppedImage) {
    if (croppedImage != null) {
      setState(() {
        image.clear();
       
      });
    } else {
      print('No image selected');
    }
  });
}


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
