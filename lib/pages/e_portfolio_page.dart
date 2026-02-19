import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../backend/backend.dart';

class EPortfolioPage extends StatefulWidget {
  const EPortfolioPage({super.key});

  @override
  State<EPortfolioPage> createState() => _EPortfolioPageState();
}

class _EPortfolioPageState extends State<EPortfolioPage> {
  LatLng? _businessLocation;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final loc = data['location'];

        setState(() {
          _profileData = data;
          if (loc != null) {
            final lat = (loc['lat'] as num?)?.toDouble();
            final lng = (loc['lng'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              _businessLocation = LatLng(lat, lng);
            }
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profileData?['name'] ?? 'User';
    final userType = _profileData?['userType'] ?? '';
    final businessName = _profileData?['businessName'] ?? '';
    final email = _profileData?['email'] ?? '';
    final phone = _profileData?['phone'] ?? '';
    final address = _profileData?['location']?['address'] ??
        _profileData?['address'] ?? '';
    final logoUrl = _profileData?['logoUrl'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("E-Portfolio"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile / logo avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: logoUrl != null
                        ? NetworkImage(logoUrl) as ImageProvider
                        : const AssetImage("assets/profile.jpg"),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (userType.isNotEmpty)
                    Text(
                      userType,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                  if (businessName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      businessName,
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // MAP SECTION
                  if (_businessLocation != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Business Location",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 250,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: _businessLocation!,
                            initialZoom: 16,
                            // Read-only in portfolio — no interaction needed
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom |
                                  InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.yourapp.smartcard',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _businessLocation!,
                                  width: 56,
                                  height: 66,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors.red, width: 2),
                                          boxShadow: const [
                                            BoxShadow(
                                                blurRadius: 4,
                                                color: Colors.black26)
                                          ],
                                          image: logoUrl != null
                                              ? DecorationImage(
                                                  image:
                                                      NetworkImage(logoUrl),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: logoUrl == null
                                            ? const Icon(Icons.business,
                                                color: Colors.red, size: 24)
                                            : null,
                                      ),
                                      Container(
                                          width: 2,
                                          height: 10,
                                          color: Colors.red),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Contact info
                  if (email.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.red),
                      title: Text(email),
                    ),
                  if (phone.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.red),
                      title: Text(phone),
                    ),
                  if (address.isNotEmpty)
                    ListTile(
                      leading:
                          const Icon(Icons.location_on, color: Colors.red),
                      title: Text(address),
                    ),
                ],
              ),
            ),
    );
  }
}