// ignore_for_file: unused_local_variable, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class HomeView extends StatefulWidget {
  HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ImagePicker picker = ImagePicker();

  bool textScanning = false;

  XFile? imageFile;

  String? scannedText;

// Pick an image.
  getImage(ImageSource source) async {
    try {
      final pickedImage = await picker.pickImage(source: source);
      if (pickedImage != null) {
        textScanning = true;
        scannedText = '';
        imageFile = pickedImage;
        setState(() {});
        getImageLabels(pickedImage);
      }
    } catch (e) {
      textScanning = false;
      imageFile = null;
      setState(() {});
      scannedText = "Error occured while scanning";
    }
  }

  void getRecognizeText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    RecognizedText recognizedText = await textDetector.processImage(inputImage);
    await textDetector.close();

    scannedText = "";
    print('$recognizedText' + '===================================');
    print('${recognizedText.blocks}' + '===================================');

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        scannedText = '${scannedText}' + '${line.text}';
      }
      scannedText = '${scannedText}' + '\n';
    }

    textScanning = false;
    setState(() {});
  }

  void getImageLabels(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    ImageLabeler imageLabeler = ImageLabeler(options: ImageLabelerOptions());
    List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    StringBuffer sb = StringBuffer();
    for (ImageLabel imageLabel in labels) {
      String lblText = imageLabel.label;
      double confidence = imageLabel.confidence;
      sb.write(lblText);
      sb.write(" : ");
      sb.write((confidence * 100).toStringAsFixed(2));
      sb.write("%\n");
    }
    imageLabeler.close();
    scannedText = sb.toString();
    textScanning = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: textScanning,
        blur: 0.5,
        progressIndicator: const CircularProgressIndicator(
          color: Colors.teal,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Column(
                children: [
                  const SizedBox(
                    height: 150,
                  ),
                  if (imageFile == null && !textScanning)
                    Container(
                      height: 300,
                      width: 300,
                      color: Colors.grey,
                    ),
                  if (imageFile != null)
                    Image.file(File(imageFile!.path), height: 300),
                  const SizedBox(
                    height: 25,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MaterialButton(
                        height: 50,
                        minWidth: 250,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        onPressed: () {
                          _showMyDialog();
                        },
                        color: Colors.teal,
                        child: const Text(
                          'Choose image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  Text(
                    scannedText ?? 'No selected image for scanned',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Choose image from :',
          ),
          content: const SingleChildScrollView(),
          actions: <Widget>[
            CustomMaterialButton(
              buttonName: 'Gallery',
              icon: Icons.image_outlined,
              onPressed: () {
                getImage(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
            CustomMaterialButton(
              buttonName: 'Camera',
              icon: Icons.camera_alt_outlined,
              onPressed: () {
                getImage(ImageSource.camera);
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }
}

class CustomMaterialButton extends StatelessWidget {
  const CustomMaterialButton({
    super.key,
    required this.buttonName,
    required this.icon,
    required this.onPressed,
  });
  final IconData icon;
  final String buttonName;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.teal, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 50,
            ),
            Text(
              buttonName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
