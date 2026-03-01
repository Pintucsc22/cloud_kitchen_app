import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final CollectionReference menuCollection =
      FirebaseFirestore.instance.collection('menu_items');

  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('orders');

  List<Map<String, dynamic>> cart = [];

  // ✅ Add to cart with quantity logic
  void addToCart(DocumentSnapshot item) {
    setState(() {
      int index =
          cart.indexWhere((element) => element['name'] == item['name']);

      if (index != -1) {
        cart[index]['quantity'] += 1;
      } else {
        cart.add({
          'name': item['name'],
          'price': item['price'],
          'quantity': 1,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item['name']} added to cart")),
    );
  }

  // ✅ Place Order
  Future<void> placeOrder() async {
    double total = 0;

    for (var item in cart) {
      total += item['price'] * item['quantity'];
    }

    await ordersCollection.add({
      'customerId': user!.uid,
      'items': cart,
      'totalPrice': total,
      'status': 'Pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      cart.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order placed successfully")),
    );
  }

  // ✅ Show Cart Dialog
  void showCartDialog() {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty")),
      );
      return;
    }

    double total = 0;
    for (var item in cart) {
      total += item['price'] * item['quantity'];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Your Cart"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...cart.map((item) => ListTile(
                      title: Text(item['name']),
                      subtitle: Text("Qty: ${item['quantity']}"),
                      trailing: Text(
                        "₹${item['price'] * item['quantity']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    )),
                const Divider(),
                Text(
                  "Total: ₹$total",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await placeOrder();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange),
              child: const Text("Confirm Order"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepOrange,
        title: const Text("Cloud Kitchen"),
        actions: [
          // ✅ Cart with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: showCartDialog,
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cart.length.toString(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),

      body: Column(
        children: [
          // 🔥 Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome 👋",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  user?.email ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "What would you like to eat today?",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Menu From Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: menuCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text("Error loading menu"));
                }

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final items = snapshot.data!.docs;

                if (items.isEmpty) {
                  return const Center(
                      child: Text("No menu items available"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fastfood,
                              size: 40,
                              color: Colors.deepOrange),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "₹${item['price']}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => addToCart(item),
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.deepOrange),
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}