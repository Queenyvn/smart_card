import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backend/backend.dart';

class QRCodePage extends StatefulWidget {
  const QRCodePage({super.key});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  late Future<_QRData?> _qrFuture;

  @override
  void initState() {
    super.initState();
    _qrFuture = _loadOrGenerateQR();
  }

  Future<_QRData?> _loadOrGenerateQR() async {
    final existing = await BackendService.fetchQRCodeURL();
    final url = (existing != null && existing.isNotEmpty)
        ? existing
        : await BackendService.generateAndSaveQR();
    if (url == null || url.isEmpty) return null;

    // Reconstruct the portfolio URL from the QR image URL stored in Firestore
    // The portfolio link is stored separately in Firestore or we rebuild it:
    final portfolioUrl = await BackendService.fetchPortfolioURL();
    return _QRData(qrImageUrl: url, portfolioUrl: portfolioUrl ?? '');
  }

  Future<void> _openPortfolio(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the portfolio link.')),
        );
      }
    }
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
        child: FutureBuilder<_QRData?>(
          future: _qrFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating your QR code...',
                      style: TextStyle(color: Colors.black54)),
                ],
              );
            }

            if (snapshot.hasError) {
              return _ErrorView(
                message: 'Failed to load QR code.\n${snapshot.error}',
                onRetry: () =>
                    setState(() => _qrFuture = _loadOrGenerateQR()),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return _ErrorView(
                message:
                    'Could not generate QR code.\nPlease check your connection and try again.',
                onRetry: () =>
                    setState(() => _qrFuture = _loadOrGenerateQR()),
              );
            }

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
                          data.qrImageUrl,
                          width: 220,
                          height: 220,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              width: 220,
                              height: 220,
                              child:
                                  Center(child: CircularProgressIndicator()),
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
                        style:
                            TextStyle(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // ── Opens portfolio URL without showing the raw link ──
                      if (data.portfolioUrl.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () =>
                              _openPortfolio(data.portfolioUrl),
                          icon: const Icon(Icons.open_in_browser, size: 18),
                          label: const Text('View My Portfolio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
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

// ── Simple data holder ────────────────────────────────────────────────────────
class _QRData {
  final String qrImageUrl;
  final String portfolioUrl;
  const _QRData({required this.qrImageUrl, required this.portfolioUrl});
}

// ── Reusable error widget ─────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}