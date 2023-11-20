import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pixelart/image_painter.dart';
import 'package:pixelart/image_picker_service.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const PixelArtApp());
}

class PixelArtApp extends StatelessWidget {
  const PixelArtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Art',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PixelArtDemoPage(),
    );
  }
}

class PixelArtDemoPage extends StatefulWidget {
  const PixelArtDemoPage({super.key});

  @override
  State<PixelArtDemoPage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<PixelArtDemoPage> {
  late final ImagePickerService _imagePicker = ImagePickerService();

  late final double _width = MediaQuery.sizeOf(context).width * 0.9;
  double _height = 300;

  File? _selectedImageFile;
  img.Image? _image;
  bool _loading = false;
  PaintEffect _appliedEffect = PaintEffect.none;

  void _pickImage() async {
    try {
      _image = null;
      _loading = true;
      setState(() {});
      _selectedImageFile = await _imagePicker.pickImage();

      final receivePort = ReceivePort();
      await Isolate.spawn(_resizeImage,
          [receivePort.sendPort, _selectedImageFile!.path, _width]);
      final bytes = await receivePort.first as Uint8List;

      _image = img.decodePng(bytes);
      _height = _image?.height.toDouble() ?? 300;
      _loading = false;
      setState(() {});
    } catch (e) {
      debugPrint("$e");
      _loading = false;
      setState(() {});
    }
  }

  static void _resizeImage(List<dynamic> args) {
    final sendPort = args[0] as SendPort;
    try {
      Uint8List bytes = File(args[1]).readAsBytesSync();

      final resizedImage = img.copyResize(
        img.decodeImage(bytes)!,
        width: (args[2] as num).toInt(),
        maintainAspect: true,
        backgroundColor: img.ColorRgb8(255, 255, 255),
        interpolation: img.Interpolation.average,
      );

      Isolate.exit(sendPort, img.encodePng(resizedImage));
    } catch (e) {
      Isolate.exit(sendPort, Uint8List.fromList([]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel Art Demo'),
      ),
      body: Stack(
        children: [
          if (_image != null)
            Positioned(
              top: kToolbarHeight / 2,
              left: 8,
              right: 8,
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: [
                  for (final effect in PaintEffect.values)
                    _Chip(
                      value: effect,
                      selectedValue: _appliedEffect,
                      onTap: (value) {
                        if (value != _appliedEffect) {
                          setState(() {
                            _appliedEffect = effect;
                          });
                        }
                      },
                    )
                ],
              ),
            ),
          Center(
            child: _loading
                ? const CircularProgressIndicator()
                : _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "📸",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          Text(
                            "Upload an image to get started",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      )
                    : CustomPaint(
                        painter: ImagePainter(
                          image: _image!,
                          paintEffect: _appliedEffect,
                        ),
                        size: Size(_width, _height),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.value,
    this.selectedValue,
    required this.onTap,
  });

  final PaintEffect value;
  final PaintEffect? selectedValue;
  final Function(PaintEffect) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap(value);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selectedValue == value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.background,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 2),
            Text(
              value.name,
              style: TextStyle(
                color: selectedValue == value
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            if (selectedValue == value) ...{
              const SizedBox(width: 4),
              Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 16,
              )
            },
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}
