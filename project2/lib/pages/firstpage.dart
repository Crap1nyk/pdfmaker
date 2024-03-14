import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:printing/printing.dart';

class Firstpage extends StatefulWidget {
  @override
  _FirstpageState createState() => _FirstpageState();
}

class _FirstpageState extends State<Firstpage> {
  final picker = ImagePicker();
  List<File> images = [];
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

    _initializeControllerFuture = _controller.initialize().catchError((error) {
      print("Error initializing camera: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          images.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
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
                )
              : PdfPreview(
                  maxPageWidth: 1000,
                  canChangeOrientation: true,
                  canDebug: false,
                  build: (format) => generateDocument(format, images),
                ),
          _buildFloatingActionButton(Icons.image, getImageFromGallery),
          _buildFloatingActionButton(Icons.camera, getImageFromCamera),
          _buildFloatingActionButton(Icons.delete, removeImage),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onOKPressed,
        tooltip: 'OK',
        child: Icon(Icons.done),
      ),
    );
  }

  Widget _buildFloatingActionButton(IconData icon, Function() onPressed) {
    return Align(
      alignment: Alignment(icon == Icons.image ? -0.7 : icon == Icons.camera ? 0.7 : 0.0, 0.7),
      child: FloatingActionButton(
        elevation: 0.0,
        child: Icon(icon),
        backgroundColor: Color.fromARGB(255, 197, 206, 166),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        images.add(File(pickedFile.path));
      });
    } else {
      print('No image selected');
    }
  }

  Future<void> getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        images.add(File(pickedFile.path));
      });
    } else {
      print('No image selected');
    }
    await _initializeControllerFuture;
    _toggleFlash();
  }

  void removeImage() {
    setState(() {
      if (images.isNotEmpty) {
        images.removeLast();
      } else {
        print('No image to remove');
      }
    });
  }

  Future<Uint8List> applyImageEnhancementToBytes(Uint8List bytes) async {
    final img.Image image = img.decodeImage(bytes)!;
    img.adjustColor(image, contrast: 1.3);
    img.adjustColor(image, brightness: 1.2);
    img.minMax(image);// Increase brightness
   img.grayscale(image!); // Convert image to grayscale for better readability
    return Uint8List.fromList(img.encodePng(image));
  }

  Future<Uint8List> generateDocument(PdfPageFormat format, List<File> images) async {
    final doc = pw.Document(pageMode: PdfPageMode.outlines);
    final font1 = await PdfGoogleFonts.openSansRegular();
    final font2 = await PdfGoogleFonts.openSansBold();

    for (var imageFile in images) {
      final processedBytes = await applyImageEnhancementToBytes(imageFile.readAsBytesSync());
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
          build: (context) => pw.Center(child: pw.Image(showimage, fit: pw.BoxFit.contain)),
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

  Future<void> _onOKPressed() async {
    if (images.isNotEmpty) {
      final croppedBytes = await cropImage(images.last);
      if (croppedBytes != null) {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Center(child: pw.Image(pw.MemoryImage(croppedBytes))),
          ),
        );
        final file = File('output.pdf');
        await file.writeAsBytes(await pdf.save());
        print('PDF generated successfully');
      } else {
        print('Failed to crop image');
      }
    } else {
      print('No image selected');
    }
  }

  Future<Uint8List?> cropImage(File imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image image = img.decodeImage(bytes)!;
    final cropX = (image.width - image.height) ~/ 2;
    final cropY = 0;
    final cropSize = image.height;
    final img.Image croppedImage = img.copyCrop(image, x: cropX, y: cropY, width: cropSize, height: cropSize);
    return Uint8List.fromList(img.encodePng(croppedImage));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
