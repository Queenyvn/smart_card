import 'package:flutter/material.dart';
import 'edit_profile.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isEditing = false;

  final nameController =
      TextEditingController(text: "Mary Jane Araco");
  final roleController =
      TextEditingController(text: "Perfume Business Owner");
  final businessNameController =
      TextEditingController(text: "Perfume de Acre");
  final businessDescController = TextEditingController(
    text:
        "A perfume company focused on designing distinctive, long-lasting fragrances that allow users to express their identity through scent.",
  );
  final emailController =
      TextEditingController(text: "maryjane@email.com");
  final phoneController =
      TextEditingController(text: "+63 912 345 6789");
  final addressController = TextEditingController(
    text:
        "Block 3 Lot 5, Tejeros Convention, Rosario, Cavite, 4106",
  );

  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    businessNameController.dispose();
    businessDescController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Widget buildTextOrField({
    required TextEditingController controller,
    required TextStyle style,
    int maxLines = 1,
    TextAlign align = TextAlign.center,
  }) {
    return isEditing
        ? TextField(
            controller: controller,
            maxLines: maxLines,
            textAlign: align,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          )
        : Text(
            controller.text,
            textAlign: align,
            style: style,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });

              if (!isEditing) {
                // 🔥 SAVE LOGIC HERE (Firebase / API / Local storage)
                debugPrint("Profile saved");
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/profile.jpg"),
            ),
            const SizedBox(height: 12),

            buildTextOrField(
              controller: nameController,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            buildTextOrField(
              controller: roleController,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 4),

            buildTextOrField(
              controller: businessNameController,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            buildTextOrField(
              controller: businessDescController,
              maxLines: 3,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            /// Contact & Address
            ListTile(
              leading: const Icon(Icons.email, color: Colors.red),
              title: isEditing
                  ? TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(emailController.text),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.red),
              title: isEditing
                  ? TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(phoneController.text),
            ),
            ListTile(
              leading:
                  const Icon(Icons.location_on, color: Colors.red),
              title: isEditing
                  ? TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(addressController.text),
            ),
          ],
        ),
      ),
    );
  }
}
