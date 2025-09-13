import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qrcode_reading/qrcode_reading.dart';


class QrReaderPage extends StatefulWidget {

  const QrReaderPage();

  @override
  State<QrReaderPage> createState() => QrReaderPageState();
}

class QrReaderPageState extends State<QrReaderPage> {
  var _isFlashLightOn = false;

  var pause = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _isFlashLightOn = false;
        });
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              setState(() {
                _isFlashLightOn = false;
              });
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isFlashLightOn = !_isFlashLightOn;
                });
              },
              icon: Icon(
                _isFlashLightOn ? Icons.flash_off : Icons.flash_on,
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: QRCodeReading(
                isFlashLightOn: _isFlashLightOn,
                pauseReading: pause,
                onRead: (data) {

                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      setState(() {
                        pause = true;
                        _isFlashLightOn = false;
                      }); //TODO doesnt work
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop(data);
                      }
                    });

                },
                errorWidget: Text("Cannot scan QR code :((("),
                loadingWidget: CircularProgressIndicator(color: Colors.black38),
                overlayWidget: (constraints) => SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Material(
                    shape: ShapeQrCodeView(
                      borderRadius: 32,
                      borderLength: 40,
                      borderColor: Colors.white,
                    ),
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// taken from https://github.com/matheusfelipe1/qrcode_reading/tree/main/example/lib/styles
class ShapeQrCodeView extends ShapeBorder {
  ShapeQrCodeView({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, .8),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
    double? cutOutWidth,
    double? cutOutHeight,
    this.cutOutBottomOffset = 0,
  })  : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
        cutOutHeight = cutOutHeight ?? cutOutSize ?? 250 {
    assert(
    borderLength <=
        min(this.cutOutWidth, this.cutOutHeight) / 2 + borderWidth * 2,
    "Border can't be larger than ${min(this.cutOutWidth, this.cutOutHeight) / 2 + borderWidth * 2}",
    );
    assert(
    (cutOutWidth == null && cutOutHeight == null) ||
        (cutOutSize == null && cutOutWidth != null && cutOutHeight != null),
    'Use only cutOutWidth and cutOutHeight or only cutOutSize');
  }

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;
  final double cutOutBottomOffset;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final currentBorderLength =
    borderLength > min(cutOutHeight, cutOutHeight) / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : borderLength;
    final currentCutOutWidth =
    cutOutWidth < width ? cutOutWidth : width - borderOffset;
    final currentCutOutHeight =
    cutOutHeight < height ? cutOutHeight : height - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - currentCutOutWidth / 2 + borderOffset,
      -cutOutBottomOffset +
          rect.top +
          height / 2 -
          currentCutOutHeight / 2 +
          borderOffset,
      currentCutOutWidth - borderOffset * 2,
      currentCutOutHeight - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
    // Draw top right corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - currentBorderLength,
          cutOutRect.top,
          cutOutRect.right,
          cutOutRect.top + currentBorderLength,
          topRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
    // Draw top left corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.top,
          cutOutRect.left + currentBorderLength,
          cutOutRect.top + currentBorderLength,
          topLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
    // Draw bottom right corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - currentBorderLength,
          cutOutRect.bottom - currentBorderLength,
          cutOutRect.right,
          cutOutRect.bottom,
          bottomRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
    // Draw bottom left corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.bottom - currentBorderLength,
          cutOutRect.left + currentBorderLength,
          cutOutRect.bottom,
          bottomLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();
  }

  @override
  ShapeBorder scale(double t) {
    return ShapeQrCodeView(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
