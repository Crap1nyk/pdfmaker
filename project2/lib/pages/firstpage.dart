import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (images.isEmpty)
            Center(
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
                      Text(
                        'Press remove once to remove filter, twice to delete image.',
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
          else
            ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Image.file(images[index]);
              },
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
          Align(
            alignment: Alignment(-0.7, 0.9),
            child: FloatingActionButton(
              onPressed: applyThresholdFilter,
              tooltip: 'Apply Threshold Filter',
              child: Icon(Icons.brush),
            ),
          ),
          Align(
            alignment: Alignment(0.7, 0.9),
            child: FloatingActionButton(
              onPressed: generateAndPrintPDF,
              tooltip: 'Generate and Print PDF',
              child: Icon(Icons.print),
            ),
          ),
          Align(
            alignment: Alignment(0.0, 0.9),
            child: FloatingActionButton(
              onPressed: applyThresholdFilter2,
              tooltip: 'Apply Threshold Filter2',
              child: Icon(Icons.filter),
            ),
          ),
        ],
      ),
    );
  }

  getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    File? img;
    if (pickedFile != null) {
      img = await cropCustomImg(pickedFile);
      setState(() {
        images.add(File(img?.path ?? pickedFile.path));
      });
    } else {
      print('No image selected');
    }
  }

  getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    File? img;
    if (pickedFile != null) {
      img = await cropCustomImg(pickedFile);
      setState(() {
        images.add(File(img?.path ?? pickedFile.path));
      });
    } else {
      print('No image selected');
    }
    await _initializeControllerFuture;
    _toggleFlash();
  }

  removeImage() {
    setState(() {
      if (images.isNotEmpty) {
        images.removeLast();
      } else {
        print('No image to remove');
      }
    });
  }

  Future<File?> cropCustomImg(XFile img) async {
    File? croppedImage = await ImageCropper().cropImage(
      sourcePath: img.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      androidUiSettings: const AndroidUiSettings(lockAspectRatio: false),
    );

    if (croppedImage != null) {
      // Apply filters to the cropped image
      File filteredImage = await applyFilter(croppedImage);
      return filteredImage;
    } else {
      return null;
    }
  }

  Future<File> applyFilter(File imageFile) async {
    // Read the image file
    Uint8List bytes = await imageFile.readAsBytes();
    img.Image image = img.decodeImage(bytes)!;

    // Apply filters (Example: Adjust brightness and contrast)
    img.Image filteredImage = img.adjustColor(image, brightness: 1.1);
    // Apply luminance threshold

    // Save the filtered image to a temporary file
    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/filtered_image.jpg');
    await tempFile.writeAsBytes(img.encodeJpg(filteredImage));

    return tempFile;
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
      _controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  void _onOKPressed() async {
    // Implement your logic for OK button here
  }

  Future<void> applyThresholdFilter() async {
    if (images.isNotEmpty) {
      // Apply threshold filter to the last image in the list
      File filteredImage = await applyThreshold(images.last);
      setState(() {
        images.add(filteredImage);
      });
    } else {
      print('No image selected');
    }
  }

  Future<void> applyThresholdFilter2() async {
    if (images.isNotEmpty) {
      // Apply threshold filter to the last image in the list
      File filteredImage = await applyThreshold2(images.last);
      setState(() {
        images.add(filteredImage);
      });
    } else {
      print('No image selected');
    }
  }

  Future<File> applyThreshold(File imageFile) async {
    // Read the image file
    Uint8List bytes = await imageFile.readAsBytes();
    img.Image image = img.decodeImage(bytes)!;

    // Apply threshold filter
    img.Image thresholdedImage = img.luminanceThreshold(image, threshold: 0.7);

    // Save the filtered image to a temporary file
    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/thresholded_image.jpg');
    await tempFile.writeAsBytes(img.encodeJpg(thresholdedImage));

    return tempFile;
  }

  Future<File> applyThreshold2(File imageFile) async {
    // Read the image file
    Uint8List bytes = await imageFile.readAsBytes();
    img.Image image = img.decodeImage(bytes)!;

    // Apply threshold filter
    img.Image thresholdedImage = img.sketch(image);
    thresholdedImage = img.adjustColor(image,contrast: 1.2);
    

    // Save the filtered image to a temporary file
    Directory tempDir = await getTemporaryDirectory();
    File tempFile = File('${tempDir.path}/thresholded_image.jpg');
    await tempFile.writeAsBytes(img.encodeJpg(thresholdedImage));

    return tempFile;
  }

  Future<void> generateAndPrintPDF() async {
    if (images.isNotEmpty) {
      final pdf = pw.Document();
      
      for (final imageFile in images) {
        final image = pw.MemoryImage(
          imageFile.readAsBytesSync(),
        );

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image),
              );
            },
          ),
        );
      }

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/example.pdf");
      await file.writeAsBytes(await pdf.save());

      // Print the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } else {
      print('No images to generate PDF');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    home: Firstpage(),
  ));
}
