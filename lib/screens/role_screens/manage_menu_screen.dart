import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final CollectionReference menuCollection =
      FirebaseFirestore.instance.collection('menu_items');

  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedCategory = 'Burger';
  File? selectedImage;
  String? editingDocId;

  final List<String> categories = ['Burger', 'Pizza', 'Biryani', 'Dessert'];

  // Pick Image
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => selectedImage = File(image.path));
    }
  }

  // Upload image if selected
  Future<String?> uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
      return null;
    }
  }

  // Add / Edit menu item
  Future<void> saveMenuItem() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0;

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter valid name & price")));
      return;
    }

    try {
      String? imageUrl;
      if (selectedImage != null) {
        imageUrl = await uploadImage(selectedImage!);
      }

      if (editingDocId == null) {
        // Add new item
        await menuCollection.add({
          'name': name,
          'price': price,
          'category': selectedCategory,
          'imageUrl': imageUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing
        final doc = menuCollection.doc(editingDocId);
        await doc.update({
          'name': name,
          'price': price,
          'category': selectedCategory,
          if (imageUrl != null) 'imageUrl': imageUrl,
        });
      }

      // Reset form
      setState(() {
        nameController.clear();
        priceController.clear();
        selectedCategory = 'Burger';
        selectedImage = null;
        editingDocId = null;
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Menu item saved")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to save item: $e")));
    }
  }

  // Delete menu item
  Future<void> deleteMenuItem(String docId) async {
    try {
      await menuCollection.doc(docId).delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Item deleted")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  // Open Add/Edit dialog
  void openMenuDialog({DocumentSnapshot? doc}) {
    if (doc != null) {
      editingDocId = doc.id;
      nameController.text = doc['name'];
      priceController.text = doc['price'].toString();
      selectedCategory = doc['category'];
      selectedImage = null; // optional: show existing image if needed
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editingDocId == null ? "Add Menu Item" : "Edit Menu Item"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Item Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedCategory = val);
                },
                decoration: const InputDecoration(labelText: "Category"),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Pick Image"),
                  ),
                  const SizedBox(width: 10),
                  if (selectedImage != null) const Text("Image Selected"),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                nameController.clear();
                priceController.clear();
                selectedCategory = 'Burger';
                selectedImage = null;
                editingDocId = null;
              });
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: saveMenuItem,
            child: Text(editingDocId == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Menu"),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: menuCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading menu"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final items = snapshot.data!.docs;

          if (items.isEmpty) return const Center(child: Text("No menu items yet"));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: (item['imageUrl'] != null && item['imageUrl'] != '')
                      ? Image.network(
                          item['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.fastfood, size: 40, color: Colors.deepOrange),
                  title: Text(item['name']),
                  subtitle: Text("₹${item['price']} • ${item['category']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => openMenuDialog(doc: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteMenuItem(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
        onPressed: () => openMenuDialog(),
      ),
    );
  }
}