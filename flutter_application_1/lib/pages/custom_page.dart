import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class CustomPage extends StatefulWidget {
  const CustomPage({Key? key}) : super(key: key);

  @override
  State<CustomPage> createState() => _CustomPageState();
}

class _CustomPageState extends State<CustomPage> {
  final _controller = DocumentScannerController();
  String? _imagePath;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> generateAndPrintPdf() async {
    if (_imagePath != null) {
      try {
        final pdfFilePath = await generatePdf(File(_imagePath!));

        // Print the PDF
        await printPdf(pdfFilePath);

        print('PDF saved at: $pdfFilePath');
      } catch (e) {
        print('Error while generating or printing PDF: $e');
      }
    } else {
      print('Error: Image path is null');
    }
  }

  Future<String> generatePdf(File imageFile) async {
    final pdf = pw.Document();
    final Uint8List imageBytes = await imageFile.readAsBytes();

    // Add image to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(PdfImage.file(
              pdf.document,
              bytes: imageBytes,
            ) as pw.ImageProvider),
          );
        },
      ),
    );

    // Save the PDF to a file
    final output = await File('document.pdf').writeAsBytes(await pdf.save());

    // Return the file path
    return output.path;
  }

  Future<void> printPdf(String pdfFilePath) async {
    final pdfBytes = File(pdfFilePath).readAsBytesSync();
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Document Scanner'),
        actions: [
          IconButton(
            onPressed: generateAndPrintPdf,
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_imagePath != null)
            Positioned.fill(
              child: Image.file(
                File(_imagePath!),
                fit: BoxFit.cover,
              ),
            ),
          DocumentScanner(
            controller: _controller,
            generalStyles: const GeneralStyles(
              hideDefaultBottomNavigation: true,
              messageTakingPicture: 'Taking picture of document',
              messageCroppingPicture: 'Cropping picture of document',
              messageEditingPicture: 'Editing picture of document',
              messageSavingPicture: 'Saving picture of document',
              baseColor: Colors.teal,
            ),
            takePhotoDocumentStyle: TakePhotoDocumentStyle(
              top: MediaQuery.of(context).padding.top + 25,
              hideDefaultButtonTakePicture: true,
              onLoading: const CircularProgressIndicator(
                color: Colors.white,
              ),
              children: [
                // * AppBar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.teal,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      bottom: 15,
                    ),
                    child: const Center(
                      child: Text(
                        'Take a picture of the document',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                // * Button to take picture
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Take photo using the document scanner
                        _controller.takePhoto();

                        // Wait for a short duration to ensure the image is captured
                        await Future.delayed(Duration(milliseconds: 500));

                        // Detect edges and set the image path
                        try {
                          String? imagePath = (await EdgeDetection.detectEdge) as String?;
                          setState(() {
                            _imagePath = imagePath;
                          });
                        } catch (e) {
                          print('Error while detecting edges: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text(
                        'Take picture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            cropPhotoDocumentStyle: CropPhotoDocumentStyle(
              top: MediaQuery.of(context).padding.top,
              maskColor: Colors.teal.withOpacity(0.2),
            ),
            editPhotoDocumentStyle: EditPhotoDocumentStyle(
              top: MediaQuery.of(context).padding.top,
            ),
            resolutionCamera: ResolutionPreset.ultraHigh,
            pageTransitionBuilder: (child, animation) {
              final tween = Tween<double>(begin: 0, end: 1);

              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );

              return ScaleTransition(
                scale: tween.animate(curvedAnimation),
                child: child,
              );
            },
            onSave: (Uint8List imageBytes) {
              // Process the imageBytes further if needed
            },
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: CustomPage(),
  ));
}
