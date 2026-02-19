import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import '../backend/backend.dart';

const LatLng _caviteCenter = LatLng(14.2456, 120.8786);

final LatLngBounds _caviteBounds = LatLngBounds(
  const LatLng(14.10, 120.60),
  const LatLng(14.50, 121.10),
);

class CaviteMapSection extends StatefulWidget {
  const CaviteMapSection({super.key});

  @override
  State<CaviteMapSection> createState() => _CaviteMapSectionState();
}

class _CaviteMapSectionState extends State<CaviteMapSection> {
  List<BusinessPin> _pins = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pins = await BackendService.fetchCaviteBusinessPins();
      if (mounted) setState(() { _pins = pins; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text("Business Map",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${_pins.length} locations",
                    style: const TextStyle(
                        fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _loading ? null : () => _openFullMap(context),
              child: const Text("View Full Map",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: _loading ? null : () => _openFullMap(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.red))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off, color: Colors.grey),
                              const SizedBox(height: 4),
                              const Text("Could not load map",
                                  style: TextStyle(color: Colors.grey)),
                              TextButton(onPressed: _loadPins, child: const Text("Retry")),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            FlutterMap(
                              options: const MapOptions(
                                initialCenter: _caviteCenter,
                                initialZoom: 11,
                                interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                  userAgentPackageName: 'com.yourapp.smartcard',
                                ),
                                MarkerLayer(markers: _buildMarkers(size: 32, interactive: false)),
                              ],
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.open_in_full, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text("Tap to expand",
                                        style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }

  void _openFullMap(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog.fullscreen(
        child: StatefulBuilder(
          builder: (ctx, setDialog) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Cavite Business Map"),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _loadPins();
                      if (context.mounted) _openFullMap(context);
                    },
                  ),
                ],
              ),
              body: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _caviteCenter,
                      initialZoom: 11,
                      minZoom: 10,
                      maxZoom: 18,
                      cameraConstraint: CameraConstraint.containCenter(
                        bounds: _caviteBounds,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.yourapp.smartcard',
                        maxZoom: 18,
                      ),
                      MarkerLayer(
                        markers: _buildMarkers(
                          size: 52,
                          interactive: true,
                          onTap: (pin) => _showBusinessCard(dialogCtx, pin),
                        ),
                      ),
                    ],
                  ),

                  // Pin count badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "${_pins.length} business${_pins.length == 1 ? '' : 'es'}",
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tap hint
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Tap a pin to see business info",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Marker> _buildMarkers({
    required double size,
    required bool interactive,
    void Function(BusinessPin)? onTap,
  }) {
    return _pins.map((pin) {
      // Total marker height = circle + pointer triangle
      final double pinHeight = size + (size * 0.45);
      return Marker(
        point: LatLng(pin.lat, pin.lng),
        width: size,
        height: pinHeight,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: interactive && onTap != null ? () => onTap(pin) : null,
          child: _MapPinWidget(pin: pin, size: size),
        ),
      );
    }).toList();
  }

  // ── BUSINESS INFO CARD (popup when tapping pin) ──
  void _showBusinessCard(BuildContext context, BusinessPin pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: logo + name + type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.red.shade300, width: 2),
                          image: pin.logoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(pin.logoUrl!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: pin.logoUrl == null
                            ? const Icon(Icons.business, color: Colors.red, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pin.businessName,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            if (pin.name.isNotEmpty &&
                                pin.name != pin.businessName) ...[
                              const SizedBox(height: 2),
                              Text(pin.name,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                            ],
                            if (pin.userType.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  pin.userType,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Details rows
                  if (pin.email.isNotEmpty)
                    _infoRow(Icons.email_outlined, pin.email),
                  if (pin.phone.isNotEmpty)
                    _infoRow(Icons.phone_outlined, pin.phone),
                  if (pin.address.isNotEmpty)
                    _infoRow(Icons.location_on_outlined, pin.address),
                  if (pin.businessDesc.isNotEmpty)
                    _infoRow(Icons.info_outline, pin.businessDesc),

                  const SizedBox(height: 16),

                  // Action button — View Profile
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.person, size: 18),
                      label: const Text("View Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MAP PIN WIDGET — teardrop shape with logo inside
// ================================================================
class _MapPinWidget extends StatelessWidget {
  final BusinessPin pin;
  final double size;

  const _MapPinWidget({required this.pin, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TearDropPainter(),
      child: SizedBox(
        width: size,
        height: size + (size * 0.45),
        child: Align(
          alignment: const Alignment(0, -0.35),
          child: SizedBox(
            width: size * 0.62,
            height: size * 0.62,
            child: ClipOval(
              child: pin.logoUrl != null
                  ? Image.network(
                      pin.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: Colors.white,
      child: Icon(Icons.business, color: Colors.red.shade700, size: size * 0.38),
    );
  }
}

// Draws the classic Google Maps-style teardrop pin in red
class _TearDropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Circle radius and center
    final double r = w / 2;
    final Offset center = Offset(r, r);

    // Paint for the main red body
    final Paint bodyPaint = Paint()
      ..color = const Color(0xFFB71C1C)
      ..style = PaintingStyle.fill;

    // Paint for the white inner circle (where logo sits)
    final Paint innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Paint for subtle shadow/border
    final Paint borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw teardrop using ui.Path (from dart:ui)
    final ui.Path path = ui.Path();

    final Offset tipPoint = Offset(r, h);

    final double dx = r - r;
    final double dy = h - r;
    final double tangentAngle = r / dy;

    final double angle = tangentAngle.clamp(0.0, 1.0);
    final double halfAngle = (angle * (3.14159 / 2)).clamp(0.0, 1.3);

    final Offset leftPt = Offset(
      center.dx + r * -1 * (1 - halfAngle * 0.3),
      center.dy + r * 0.7,
    );
    final Offset rightPt = Offset(
      center.dx + r * (1 - halfAngle * 0.3),
      center.dy + r * 0.7,
    );

    path.addOval(Rect.fromCircle(center: center, radius: r));
    path.moveTo(leftPt.dx, leftPt.dy);
    path.quadraticBezierTo(r, h * 1.05, rightPt.dx, rightPt.dy);

    // Shadow
    canvas.drawShadow(path, Colors.black, 4, true);

    // Main body
    canvas.drawPath(path, bodyPaint);

    // Border
    canvas.drawPath(path, borderPaint);

    // Inner white circle (slightly smaller than radius)
    canvas.drawCircle(center, r * 0.68, innerPaint);

    // Thin red ring between white inner and red outer
    final Paint ringPaint = Paint()
      ..color = const Color(0xFFB71C1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.06;
    canvas.drawCircle(center, r * 0.68, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}