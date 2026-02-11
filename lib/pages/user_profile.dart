import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class Business {
  final TextEditingController name;
  final TextEditingController desc;
  final TextEditingController address;
  final TextEditingController phone;
  final List<File> images;
  final ImagePicker _picker = ImagePicker();

  Business({
    required this.name,
    required this.desc,
    required this.address,
    required this.phone,
    List<File>? images,
  }) : images = images ?? [];

  bool get isEmpty =>
      name.text.isEmpty &&
      desc.text.isEmpty &&
      address.text.isEmpty &&
      phone.text.isEmpty &&
      images.isEmpty;
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isEditing = false;
  File? profileImage;

  final ImagePicker _picker = ImagePicker();

  final nameController = TextEditingController(text: "Mary Jane Araco");
  final roleController = TextEditingController(text: "Perfume Business Owner");
  final emailController = TextEditingController(text: "maryjane@email.com");
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  final List<Business> businesses = [
    Business(
      name: TextEditingController(text: "Perfume de Acre"),
      desc: TextEditingController(
        text: "A perfume company focused on designing distinctive, long-lasting fragrances.",
      ),
      address: TextEditingController(),
      phone: TextEditingController(),
    ),
  ];

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    for (final b in businesses) {
      b.name.dispose();
      b.desc.dispose();
      b.address.dispose();
      b.phone.dispose();
    }
    super.dispose();
  }

  Future<void> pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> addBusinessImage(Business business) async {
    if (business.images.length >= 5) return;
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        business.images.add(File(file.path));
      });
    }
  }

  Widget businessImages(Business business) {
    if (!isEditing && business.images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Business Images",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < business.images.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      business.images[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isEditing)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.red,
                        onPressed: () {
                          setState(() {
                            business.images.removeAt(i);
                          });
                        },
                      ),
                    ),
                ],
              ),
            if (isEditing && business.images.length < 5)
              GestureDetector(
                onTap: () => addBusinessImage(business),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_a_photo),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget labeledField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool required = false,
  }) {
    if (!isEditing && controller.text.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? "$label (Required)" : label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        isEditing
            ? TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )
            : Text(controller.text),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget businessSection(int index) {
    final business = businesses[index];
    if (!isEditing && business.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Business ${index + 1}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        businesses.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            labeledField(label: "Business Name", controller: business.name),
            businessImages(business),
            labeledField(label: "Business Description", controller: business.desc, maxLines: 3),
            labeledField(label: "Business Address", controller: business.address, maxLines: 2),
            labeledField(label: "Business Contact Number", controller: business.phone),
          ],
        ),
      ),
    );
  }

  void cancelEdit() {
    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: isEditing ? pickProfileImage : null,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : const AssetImage("assets/profile.jpg") as ImageProvider,
                    ),
                    if (isEditing)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            /// PERSONAL INFO
            labeledField(label: "Name", controller: nameController, required: true),
            labeledField(label: "Role", controller: roleController),
            labeledField(label: "Personal Email", controller: emailController),
            labeledField(label: "Personal Phone Number", controller: phoneController),
            labeledField(label: "Personal Address", controller: addressController, maxLines: 2),

            const SizedBox(height: 16),

            /// BUSINESSES
            Text(
              "Businesses",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < businesses.length; i++) businessSection(i),

            if (isEditing)
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Business"),
                onPressed: () {
                  setState(() {
                    businesses.add(
                      Business(
                        name: TextEditingController(),
                        desc: TextEditingController(),
                        address: TextEditingController(),
                        phone: TextEditingController(),
                      ),
                    );
                  });
                },
              ),

            if (isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: cancelEdit,
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                        });
                        debugPrint("Profile saved");
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
