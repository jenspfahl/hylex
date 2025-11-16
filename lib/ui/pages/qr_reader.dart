import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QrReaderPage extends StatefulWidget {

  const QrReaderPage();

  @override
  State<QrReaderPage> createState() => QrReaderPageState();
}

class QrReaderPageState extends State<QrReaderPage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  bool? _flashStatus;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _shutdown();
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () async {
              await _shutdown();
              setState(() {});
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await controller?.toggleFlash();
                _flashStatus = await controller?.getFlashStatus();
                debugPrint("flash: $_flashStatus");
                setState(() {});
              },
              icon: Icon(
                _flashStatus == true ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: Center(child: _buildQrView(context)),
      ),
    );
  }

  Future<void> _shutdown() async {
    _flashStatus = await controller?.getFlashStatus();
    if (_flashStatus == true) {
      //turn of
      await controller?.toggleFlash();
    }
    await controller?.stopCamera();
  }

  Widget _buildQrView(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.white, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: 300),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      _shutdown();
      Navigator.of(context).pop(scanData.code);
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera permission')),
      );
    }
  }
}
