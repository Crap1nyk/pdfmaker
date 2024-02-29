// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

class FromGalleryPage extends StatefulWidget {
  const FromGalleryPage({super.key});

  @override
  State<FromGalleryPage> createState() => _FromGalleryPageState();
}

class _FromGalleryPageState extends State<FromGalleryPage> {
  final controller = DocumentScannerController();
  bool imageIsSelected = false;

  @override
  void initState() {
    super.initState();

    controller.currentPage.listen((AppPages page) {
      if (page == AppPages.takePhoto) {
        setState(() => imageIsSelected = false);
      }

      if (page == AppPages.cropPhoto) {
        setState(() => imageIsSelected = true);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DocumentScanner(
        controller: controller,
        generalStyles: GeneralStyles(
          showCameraPreview: false,
          widgetInsteadOfCameraPreview: Center(
            child: ElevatedButton(
              onPressed: _selectImage,
              child: const Text('Select image'),
            ),
          ),
        ),
        onSave: (Uint8List imageBytes) async {
          // Save the processed image
          await _saveProcessedEdgeImage(imageBytes);
        },
      ),
    );
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    await controller.findContoursFromExternalImage(
      image: File(image.path),
    );
  }

  Future<void> _saveProcessedEdgeImage(Uint8List imageBytes) async {
    // Save the processed image with a specific file name and extension
    final directory = Directory('path_to_save');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final newImagePath = '${directory.path}/processed_image.jpg';

    try {
      // Write the bytes to a new image file
      await File(newImagePath).writeAsBytes(imageBytes);

      print('Processed image saved successfully as: $newImagePath');
    } catch (e) {
      print('Error saving processed image: $e');
    }
  }
}
