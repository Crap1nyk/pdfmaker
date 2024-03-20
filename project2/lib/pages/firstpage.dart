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
  bool filterApplied = false;
  File? originalImg;
  bool isLoading = false;

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
      appBar: AppBar(
        title: const Text('Scanner App'),
        centerTitle: true,
        actions: [
          (images.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: TextButton(
                      onPressed: () => generateAndPrintPDF(),
                      style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          )),
                          backgroundColor: MaterialStateProperty.all(
                              const Color.fromARGB(255, 197, 206, 166))),
                      child: const Text(
                        'PDF',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w700),
                      )),
                )
              : const SizedBox()
        ],
      ),
      body: Stack(
        children: [
          (images.isEmpty)
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
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
                            color: Color.fromARGB(255, 6, 6, 6),
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'Press remove once to remove filter, twice to delete image.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromARGB(255, 6, 6, 6),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: images.length,
                  itemBuilder: (BuildContext context, index) {
                    return Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Stack(children: [
                          (isLoading && index + 1 == images.length)
                              ? SizedBox(
                                  width: MediaQuery.sizeOf(context).width,
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.5,
                                  child: const Center(
                                      child: CircularProgressIndicator()))
                              : Image.file(images[index]),
                          (index + 1 == images.length)
                              ? Positioned(
                                  top: 10,
                                  right: 10,
                                  child: (filterApplied)
                                      ? Row(
                                          children: [
                                            FloatingActionButton(
                                              onPressed: () {
                                                setState(() {
                                                  images[index] = originalImg!;
                                                  filterApplied = false;
                                                });
                                              },
                                              tooltip: 'Remove Filter',
                                              child: const Icon(
                                                  Icons.replay_rounded),
                                            ),
                                            const SizedBox(width: 20),
                                            FloatingActionButton(
                                              onPressed: () {
                                                setState(() {
                                                  filterApplied = false;
                                                });
                                              },
                                              tooltip: 'Save',
                                              child: const Icon(
                                                  Icons.done_rounded),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            FloatingActionButton(
                                              onPressed: () async {
                                                setState(() {
                                                  isLoading = true;
                                                });
                                                File filteredImage =
                                                    await applyThreshold(
                                                        images[index]);
                                                setState(() {
                                                  isLoading = false;
                                                  filterApplied = true;
                                                  originalImg = images[index];
                                                  images[index] = filteredImage;
                                                });
                                              },
                                              tooltip: 'Apply Threshold Filter',
                                              child: const Icon(Icons.brush),
                                            ),
                                            const SizedBox(width: 20),
                                            FloatingActionButton(
                                              onPressed: () async {
                                                setState(() {
                                                  isLoading = true;
                                                });
                                                File filteredImage =
                                                    await applyThreshold2(
                                                        images[index]);
                                                setState(() {
                                                  isLoading = false;
                                                  filterApplied = true;
                                                  originalImg = images[index];
                                                  images[index] = filteredImage;
                                                });
                                              },
                                              tooltip:
                                                  'Apply Threshold Filter2',
                                              child: const Icon(Icons.filter),
                                            ),
                                          ],
                                        ),
                                )
                              : const SizedBox(),
                        ]));
                  }),
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
          // Align(
          //   alignment: Alignment(-0.7, 0.9),
          //   child: FloatingActionButton(
          //     onPressed: applyThresholdFilter,
          //     tooltip: 'Apply Threshold Filter',
          //     child: Icon(Icons.brush),
          //   ),
          // ),
          // Align(
          //   alignment: Alignment(0.7, 0.9),
          //   child: FloatingActionButton(
          //     onPressed: generateAndPrintPDF,
          //     tooltip: 'Generate and Print PDF',
          //     child: Icon(Icons.print),
          //   ),
          // ),
          // Align(
          //   alignment: Alignment(0.0, 0.9),
          //   child: FloatingActionButton(
          //     onPressed: applyThresholdFilter2,
          //     tooltip: 'Apply Threshold Filter2',
          //     child: Icon(Icons.filter),
          //   ),
          // ),
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

    return croppedImage;
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

  Future<void> applyThresholdFilter({required File img}) async {
    if (images.isNotEmpty) {
      // Apply threshold filter to the last image in the list
      File filteredImage = await applyThreshold(img);
      setState(() {
        filterApplied = true;
        images.add(filteredImage);
      });
    } else {
      print('No image selected');
    }
  }

  Future<void> applyThresholdFilter2({required File img}) async {
    if (images.isNotEmpty) {
      // Apply threshold filter to the last image in the list
      File filteredImage = await applyThreshold2(img);
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
    thresholdedImage = img.adjustColor(image, contrast: 1.2);

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
