import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

enum PaintEffect {
  none(name: "Original"),
  sepia(name: "Sepia"),
  grayscale(name: "B&W"),
  rgb(name: "RGB"),
  emboss(name: "Emboss", useASCII: true),
  ascii(name: "Grainy", useASCII: true),
  waterColor(name: "Water Color", useASCII: true);

  const PaintEffect({
    required this.name,
    this.useASCII = false,
  });

  final String name;
  final bool useASCII;
}

class ImagePainter extends CustomPainter {
  final img.Image image;
  final PaintEffect paintEffect;

  //Reference: https://editor.p5js.org/codingtrain/sketches/r4ApYWpH_
  static const _density = 'Ñ@#W\$9876543210?!abc;:+=-,._ ';
  static const _reversedDensity = ' _.,-=+:;cba!?0123456789\$W#@Ñ';
  final _length = _density.length;

  const ImagePainter({
    required this.image,
    this.paintEffect = PaintEffect.none,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = image.width / image.height;

    for (int j = 0; j < image.height; j++) {
      for (int i = 0; i < image.width; i++) {
        final pixel = image.getPixel(i, j);
        _paintPixel(canvas, pixel, i, j, pixelSize);
      }
    }
  }

  void _paintPixel(
    Canvas canvas,
    img.Pixel pixel,
    int i,
    int j,
    double pixelSize,
  ) {
    if (paintEffect.useASCII) {
      final average = (pixel.r + pixel.g + pixel.b) ~/ 3;
      final characterIndex =
          math.min(((average / 255) * _length).toInt(), _length - 1);
      String char;

      switch (paintEffect) {
        case PaintEffect.emboss:
          char = _reversedDensity[characterIndex];

          break;
        default:
          char = _density[characterIndex];
      }

      TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: char,
          style: _getStyle(pixel, pixelSize),
        ),
      )
        ..layout()
        ..paint(canvas, Offset(i.toDouble(), j.toDouble()));
    } else {
      canvas.drawRect(
          Rect.fromLTWH(
            i.toDouble(),
            j.toDouble(),
            pixelSize,
            pixelSize,
          ),
          Paint()..color = _getColor(pixel));
    }
  }

  TextStyle _getStyle(
    img.Pixel pixel,
    num pixelSize,
  ) {
    switch (paintEffect) {
      case PaintEffect.emboss:
        return TextStyle(
          fontSize: pixelSize * 4,
          color: _getColor(pixel, PaintEffect.none),
        );
      case PaintEffect.waterColor:
        return TextStyle(
          fontSize: pixelSize * 2,
          color: _getColor(pixel, PaintEffect.rgb),
        );
      default:
        return TextStyle(
          color: _getColor(pixel, PaintEffect.grayscale),
        );
    }
  }

  Color _getColor(img.Pixel pixel, [PaintEffect? override]) {
    final red = pixel.r;
    final green = pixel.g;
    final blue = pixel.b;

    switch (override ?? paintEffect) {
      case PaintEffect.grayscale:
        final average = (red + green + blue) ~/ 3;
        return Color.fromARGB(
          255,
          average,
          average,
          average,
        );
      case PaintEffect.rgb:
        final max = math.max(red, math.max(green, blue));
        return Color.fromARGB(
          255,
          max == red ? red.toInt() : 0,
          max == green ? green.toInt() : 0,
          max == blue ? blue.toInt() : 0,
        );
      case PaintEffect.sepia:
        //Reference: https://dyclassroom.com/image-processing-project/how-to-convert-a-color-image-into-sepia-image
        final tr = ((0.393 * red) + (0.769 * green) + (0.189 * blue)).toInt();
        final tg = ((0.349 * red) + (0.686 * green) + (0.168 * blue)).toInt();
        final tb = ((0.272 * red) + (0.534 * green) + (0.131 * blue)).toInt();
        return Color.fromARGB(
          255,
          tr > red ? red.toInt() : tr,
          tg > red ? green.toInt() : tg,
          tb > red ? blue.toInt() : tb,
        );

      default:
        return Color.fromARGB(
          255,
          red.toInt(),
          green.toInt(),
          blue.toInt(),
        );
    }
  }

  @override
  bool shouldRepaint(covariant ImagePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.paintEffect != paintEffect;
}
