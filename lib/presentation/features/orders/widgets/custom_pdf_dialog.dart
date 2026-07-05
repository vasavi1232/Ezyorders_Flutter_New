import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import '../../../../core/constants/url_api_key.dart';
import '../../../../core/utils/common_methods.dart';

class CustomPdfDialog extends StatefulWidget {
  final String pdfUrl;
  final String orderId;

  const CustomPdfDialog({
    super.key,
    required this.pdfUrl,
    required this.orderId,
  });

  @override
  State<CustomPdfDialog> createState() => _CustomPdfDialogState();
}

class _CustomPdfDialogState extends State<CustomPdfDialog> {
  String? localPath;
  bool isDownloading = true;
  String errorMessage = "";
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _downloadAndSavePdf() async {
    try {
      String finalUrl = widget.pdfUrl;
      if (!finalUrl.startsWith('http')) {
        finalUrl = UrlApiKey.companyMainUrl +
            (finalUrl.startsWith('/') ? finalUrl.substring(1) : finalUrl);
      }

      final response = await http.get(Uri.parse(finalUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/Invoice_${widget.orderId}.pdf');
        await file.writeAsBytes(bytes);

        _saveToPublicDownloads(finalUrl);

        if (mounted) {
          setState(() {
            localPath = file.path;
            _pdfController = PdfControllerPinch(
              document: PdfDocument.openFile(file.path),
            );
            isDownloading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isDownloading = false;
            errorMessage =
                "Failed to load invoice. Server returned ${response.statusCode}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isDownloading = false;
          errorMessage = "Error downloading invoice: $e";
        });
      }
    }
  }

  Future<void> _saveToPublicDownloads(String finalUrl) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }

        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          await FlutterDownloader.enqueue(
            url: finalUrl,
            savedDir: directory.path,
            fileName: 'Invoice_${widget.orderId}.pdf',
            showNotification: true,
            openFileFromNotification: true,
            saveInPublicStorage: true,
          );
        }
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        await FlutterDownloader.enqueue(
          url: finalUrl,
          savedDir: dir.path,
          fileName: 'Invoice_${widget.orderId}.pdf',
          showNotification: true,
          openFileFromNotification: true,
        );
      }
    } catch (e) {
      debugPrint("Error saving via flutter_downloader: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
          horizontal: CommonMethods.safeSize(16.w, min: 1.0),
          vertical: CommonMethods.safeSize(24.h, min: 1.0)),
      backgroundColor: Colors.transparent,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header Bar
            Container(
              color: const Color(0xFFFDB833),
              padding: EdgeInsets.symmetric(
                  horizontal: CommonMethods.safeSize(16.w, min: 1.0),
                  vertical: CommonMethods.safeSize(12.h, min: 1.0)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "View Order Confirmation",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: CommonMethods.safeSize(16.sp, defaultValue: 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close,
                        color: Colors.white,
                        size: CommonMethods.safeSize(24.sp, defaultValue: 24)),
                  ),
                ],
              ),
            ),

            // PDF Body
            Expanded(
              child: isDownloading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFFDB833)))
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child:
                                Text(errorMessage, textAlign: TextAlign.center),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFE5E5E5), // Light grey background
                          child: _pdfController != null
                              ? PdfViewPinch(
                                  controller: _pdfController!,
                                  padding: 16.h,
                                  builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                                    options: const DefaultBuilderOptions(),
                                    documentLoaderBuilder: (_) =>
                                        const Center(child: CircularProgressIndicator()),
                                    pageLoaderBuilder: (_) =>
                                        const Center(child: CircularProgressIndicator()),
                                    errorBuilder: (_, error) =>
                                        Center(child: Text(error.toString())),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
            ),

            // Footer Button
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: CommonMethods.safeSize(16.h)),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDB833),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          CommonMethods.safeSize(4.r, defaultValue: 4))),
                  padding: EdgeInsets.symmetric(
                      horizontal: CommonMethods.safeSize(60.w),
                      vertical: CommonMethods.safeSize(12.h)),
                ),
                child: Text(
                  "Close",
                  style: TextStyle(
                      fontSize: CommonMethods.safeSize(14.sp, defaultValue: 14),
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
