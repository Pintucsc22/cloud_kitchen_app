import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_screen.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  // Firestore orders collection
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('orders');

  final User? user = FirebaseAuth.instance.currentUser;

  // Update order status
  void updateStatus(String orderId, String status) async {
    try {
      await ordersCollection.doc(orderId).update({'status': status});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Order marked $status')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  // Build a list of orders filtered by status
  Widget buildOrderList(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: ordersCollection
          .where('status', isEqualTo: statusFilter)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) return Text('No $statusFilter orders');

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final items = List.from(order['items']);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: ExpansionTile(
                title: Text('Order #${order.id} • ₹${order['totalPrice']}'),
                subtitle: Text('Status: ${order['status']}'),
                children: [
                  ...items.map((item) => ListTile(
                        title: Text(item['name']),
                        trailing: Text('x${item['quantity']}'),
                      )),
                  ButtonBar(
                    children: [
                      if (statusFilter == 'Pending')
                        ElevatedButton(
                          onPressed: () => updateStatus(order.id, 'Cooking'),
                          child: const Text('Start Cooking'),
                        ),
                      if (statusFilter == 'Cooking')
                        ElevatedButton(
                          onPressed: () => updateStatus(order.id, 'Completed'),
                          child: const Text('Mark Completed'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
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
        title: const Text("Kitchen Dashboard"),
        actions: [
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
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
                    "Welcome Kitchen 👨‍🍳",
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
                    "View and manage ongoing orders",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pending Orders",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  buildOrderList('Pending'),
                  const SizedBox(height: 20),
                  const Text(
                    "Cooking Orders",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  buildOrderList('Cooking'),
                  const SizedBox(height: 20),
                  const Text(
                    "Completed Orders",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  buildOrderList('Completed'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}