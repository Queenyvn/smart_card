import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backend/backend.dart';

class QRCodePage extends StatefulWidget {
  const QRCodePage({super.key});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  late Future<String?> _qrFuture;

  @override
  void initState() {
    super.initState();
    _qrFuture = _loadOrGenerateQR();
  }

  /// Reads qrCodeURL from Firestore first.
  /// If missing, auto-generates via qrserver.com and saves it — 
  /// exactly what qr_generator.js does on web.
  Future<String?> _loadOrGenerateQR() async {
    // Step 1: Check Firestore for existing URL
    final existing = await BackendService.fetchQRCodeURL();
    if (existing != null && existing.isNotEmpty) return existing;

    // Step 2: Not found — generate, upload, save, return
    return BackendService.generateAndSaveQR();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("QR Code"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: FutureBuilder<String?>(
          future: _qrFuture,
          builder: (context, snapshot) {
            // ── Loading ──────────────────────────────────────────────
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Generating your QR code...',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              );
            }

            // ── Error ────────────────────────────────────────────────
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load QR code.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _qrFuture = _loadOrGenerateQR()),
                    child: const Text('Retry'),
                  ),
                ],
              );
            }

            final qrUrl = snapshot.data;

            // ── Generation failed (null returned) ────────────────────
            if (qrUrl == null || qrUrl.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_2,
                      size: 64, color: Colors.black26),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not generate QR code.',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your connection and try again.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        setState(() => _qrFuture = _loadOrGenerateQR()),
                    child: const Text('Try Again'),
                  ),
                ],
              );
            }

            // ── QR ready ─────────────────────────────────────────────
            return SingleChildScrollView(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          qrUrl,
                          width: 220,
                          height: 220,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stack) {
                            return const SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                child: Icon(Icons.broken_image,
                                    size: 64, color: Colors.black26),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Scan this QR code to view your profile",
                        style: TextStyle(
                            fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: qrUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR image link copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy QR Link'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}