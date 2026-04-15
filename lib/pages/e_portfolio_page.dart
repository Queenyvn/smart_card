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

class MemberEPortfolioPage extends StatefulWidget {
  final String memberUid;
  const MemberEPortfolioPage({super.key, required this.memberUid});

  @override
  State<MemberEPortfolioPage> createState() => _MemberEPortfolioPageState();
}

class _MemberEPortfolioPageState extends State<MemberEPortfolioPage> {
  Map<String, dynamic>? _profileData;
  LatLng? _businessLocation;
  bool _isLoading = true;

  String _connectionStatus = 'none';
  bool _connectLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      BackendService.fetchPublicProfile(widget.memberUid),
      BackendService.getConnectionStatus(widget.memberUid),
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final status = results[1] as String;

    if (profile != null) {
      final loc = profile['location'];
      LatLng? latLng;
      if (loc != null) {
        final lat = (loc['lat'] as num?)?.toDouble();
        final lng = (loc['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          latLng = LatLng(lat, lng);
        }
      }
      if (mounted) {
        setState(() {
          _profileData = profile;
          _businessLocation = latLng;
          _connectionStatus = status;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleConnect() async {
    setState(() => _connectLoading = true);

    if (_connectionStatus == 'accepted') {
      final result = await BackendService.removeConnection(widget.memberUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.success
              ? 'Disconnected successfully.'
              : result.message ?? 'Failed to disconnect.'),
          backgroundColor: result.success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        if (result.success) {
          setState(() {
            _connectionStatus = 'none';
            _connectLoading = false;
          });
        } else {
          setState(() => _connectLoading = false);
        }
      }
    } else if (_connectionStatus == 'none') {
      final result =
          await BackendService.sendConnectionRequest(widget.memberUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.success
              ? 'Connection request sent!'
              : result.message ?? 'Failed to send request.'),
          backgroundColor: result.success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
        if (result.success) {
          setState(() {
            _connectionStatus = 'pending_sent';
            _connectLoading = false;
          });
        } else {
          setState(() => _connectLoading = false);
        }
      }
    } else if (_connectionStatus == 'pending_received') {
      final connData = await BackendService.getConnectionDocForAccept(
          widget.memberUid);
      if (connData != null) {
        final result =
            await BackendService.acceptConnectionRequest(connData['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.success
                ? 'Connected!'
                : result.message ?? 'Failed to accept.'),
            backgroundColor: result.success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
          if (result.success) {
            setState(() {
              _connectionStatus = 'accepted';
              _connectLoading = false;
            });
          } else {
            setState(() => _connectLoading = false);
          }
        }
      } else {
        setState(() => _connectLoading = false);
      }
    } else {
      setState(() => _connectLoading = false);
    }
  }

  String get _buttonLabel {
    final name = _profileData?['name'] ?? 'Member';
    switch (_connectionStatus) {
      case 'accepted':
        return 'Disconnect';
      case 'pending_sent':
        return 'Request Sent';
      case 'pending_received':
        return 'Accept Request';
      default:
        return 'Connect with $name';
    }
  }

  Color get _buttonColor {
    switch (_connectionStatus) {
      case 'accepted':
        return Colors.grey.shade400;
      case 'pending_sent':
        return Colors.orange.shade400;
      case 'pending_received':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  IconData get _buttonIcon {
    switch (_connectionStatus) {
      case 'accepted':
        return Icons.link_off_rounded;
      case 'pending_sent':
        return Icons.schedule_rounded;
      case 'pending_received':
        return Icons.person_add_outlined;
      default:
        return Icons.link_rounded;
    }
  }

  String get _appBarLabel {
    switch (_connectionStatus) {
      case 'accepted':
        return 'Connected';
      case 'pending_sent':
        return 'Pending';
      case 'pending_received':
        return 'Accept';
      default:
        return 'Connect';
    }
  }

  Color get _appBarBgColor {
    switch (_connectionStatus) {
      case 'accepted':
        return Colors.grey.shade100;
      case 'pending_sent':
        return Colors.orange.shade50;
      case 'pending_received':
        return Colors.blue.shade50;
      default:
        return Colors.red;
    }
  }

  Color get _appBarFgColor {
    switch (_connectionStatus) {
      case 'accepted':
        return Colors.grey.shade600;
      case 'pending_sent':
        return Colors.orange.shade700;
      case 'pending_received':
        return Colors.blue.shade700;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profileData?['name'] ?? 'Member';
    final userType = _profileData?['userType'] ?? '';
    final businessName = _profileData?['businessName'] ?? '';
    final email = _profileData?['email'] ?? '';
    final phone = _profileData?['phone'] ?? '';
    final address = _profileData?['location']?['address'] ??
        _profileData?['address'] ?? '';
    final logoUrl = _profileData?['logoUrl'] as String?;

    String? myUid;
    try {
      myUid = BackendService.currentUid;
    } catch (_) {}
    final isOwnProfile = myUid == widget.memberUid;

    final bool buttonDisabled =
        _connectLoading || _connectionStatus == 'pending_sent';

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'My E-Portfolio' : "$name's Portfolio"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (!isOwnProfile && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: buttonDisabled ? null : _toggleConnect,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _appBarBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _connectionStatus == 'none'
                          ? Colors.red
                          : _appBarFgColor.withOpacity(0.4),
                    ),
                  ),
                  child: _connectLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _appBarFgColor,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_buttonIcon,
                                size: 14, color: _appBarFgColor),
                            const SizedBox(width: 5),
                            Text(
                              _appBarLabel,
                              style: TextStyle(
                                color: _appBarFgColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.red))
          : _profileData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_outlined,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Member profile not found.',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 15)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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

                      if (!isOwnProfile) ...[
                        const SizedBox(height: 10),
                        if (_connectionStatus == 'accepted')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: Colors.green.shade200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 14, color: Colors.green),
                                SizedBox(width: 5),
                                Text('You are connected',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        else if (_connectionStatus == 'pending_sent')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.orange.shade200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule_rounded,
                                    size: 14, color: Colors.orange),
                                SizedBox(width: 5),
                                Text('Request pending',
                                    style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        else if (_connectionStatus == 'pending_received')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_add_outlined,
                                    size: 14, color: Colors.blue),
                                SizedBox(width: 5),
                                Text('Wants to connect with you',
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],

                      const SizedBox(height: 16),

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
                                interactionOptions:
                                    const InteractionOptions(
                                  flags: InteractiveFlag.pinchZoom |
                                      InteractiveFlag.drag,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.yourapp.smartcard',
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
                                                  color: Colors.red,
                                                  width: 2),
                                              boxShadow: const [
                                                BoxShadow(
                                                    blurRadius: 4,
                                                    color: Colors.black26)
                                              ],
                                              image: logoUrl != null
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                          logoUrl),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                            ),
                                            child: logoUrl == null
                                                ? const Icon(Icons.business,
                                                    color: Colors.red,
                                                    size: 24)
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

                      if (email.isNotEmpty)
                        ListTile(
                          leading:
                              const Icon(Icons.email, color: Colors.red),
                          title: Text(email),
                        ),
                      if (phone.isNotEmpty)
                        ListTile(
                          leading:
                              const Icon(Icons.phone, color: Colors.red),
                          title: Text(phone),
                        ),
                      if (address.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.location_on,
                              color: Colors.red),
                          title: Text(address),
                        ),

                      const SizedBox(height: 24),

                      if (!isOwnProfile)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: buttonDisabled ? null : _toggleConnect,
                            icon: _connectLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Icon(
                                    _buttonIcon,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                            label: Text(
                              _connectLoading
                                  ? 'Please wait...'
                                  : _buttonLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _buttonColor,
                              minimumSize:
                                  const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}