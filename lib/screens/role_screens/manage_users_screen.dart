import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final CollectionReference usersRef =
      FirebaseFirestore.instance.collection('users');

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'customer';

  // Add User to Firebase Auth + Firestore
  Future<void> addUser() async {
    try {
      if (nameController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("All fields are required")));
        return;
      }

      // 1️⃣ Create user in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 2️⃣ Save user details in Firestore
      await usersRef.doc(userCredential.user!.uid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User Added Successfully")));

      Navigator.pop(context); // close dialog
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Update User name & role
  Future<void> updateUser(String docId, String currentName, String currentRole) async {
    nameController.text = currentName;
    selectedRole = currentRole;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['admin', 'kitchen', 'store', 'customer']
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedRole = value!;
              },
              decoration: const InputDecoration(labelText: "Role"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await usersRef.doc(docId).update({
                'name': nameController.text.trim(),
                'role': selectedRole,
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User Updated Successfully")));
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // Delete User from Firestore
  Future<void> deleteUser(String docId) async {
    bool confirm = false;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              confirm = true;
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm) {
      await usersRef.doc(docId).delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User Deleted Successfully")));
      setState(() {});
    }
  }

  // Add User Dialog
  void showAddUserDialog() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    selectedRole = 'customer';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New User"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: ['admin', 'kitchen', 'store', 'customer']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedRole = value!;
                },
                decoration: const InputDecoration(labelText: "Role"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: addUser,
            child: const Text("Add User"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddUserDialog,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: data.docs.length,
            itemBuilder: (context, index) {
              final userDoc = data.docs[index];
              final userData = userDoc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(userData['name'] ?? ""),
                  subtitle: Text("${userData['email'] ?? ""} • Role: ${userData['role'] ?? ""}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => updateUser(
                          userDoc.id,
                          userData['name'] ?? "",
                          userData['role'] ?? "customer",
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteUser(userDoc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}