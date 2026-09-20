import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCPf1g-X2XAIDnRzw0XeoKpdlorXA0nMHY",
        authDomain: "svr-store.firebaseapp.com",
        projectId: "svr-store",
        storageBucket: "svr-store.firebasestorage.app",
        messagingSenderId: "1046220131659",
        appId: "1:1046220131659:web:68693d1a1b5112bc276cce",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const SVRStoreApp());
}

class SVRStoreApp extends StatelessWidget {
  const SVRStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SVR Store',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ---------------- PRODUCT & CART MODELS ----------------
class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final String description;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      category: data['category']?.toString() ?? 'General',
      price: double.tryParse(data['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: data['imageUrl']?.toString() ?? 'https://via.placeholder.com/150',
      description: data['description']?.toString() ?? '',
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

// ---------------- HOME SCREEN ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<CartItem> cart = [];
  String searchQuery = '';
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Electronics', 'Footwear', 'Accessories', 'Fashion'];

  final String adminEmail = "admin@svrstore.com";

  void addToCart(Product product) {
    setState(() {
      final index = cart.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        cart[index].quantity++;
      } else {
        cart.add(CartItem(product: product));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  int get totalCartItems => cart.fold(0, (total, item) => total + item.quantity);

  void _openAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => const AuthDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        final bool isLoggedIn = currentUser != null;
        final bool isAdmin = isLoggedIn && (currentUser.email?.toLowerCase() == adminEmail.toLowerCase());

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SVR Store', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                if (isLoggedIn)
                  Text(
                    isAdmin ? 'Admin Mode' : (currentUser.email ?? ''),
                    style: TextStyle(
                      fontSize: 11,
                      color: isAdmin ? Colors.amber.shade900 : Colors.grey.shade700,
                      fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
              ],
            ),
            actions: [
              // ADMIN CONTROLS
              if (isAdmin) ...[
                IconButton(
                  tooltip: 'Orders Dashboard',
                  icon: const Icon(Icons.receipt_long, color: Colors.deepPurple),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrdersDashboardScreen()),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Manage Products',
                  icon: const Icon(Icons.add_business, color: Colors.deepPurple),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminProductScreen()),
                    );
                  },
                ),
              ],

              // NORMAL CUSTOMER CONTROLS (My Orders & Profile)
              if (isLoggedIn && !isAdmin) ...[
                IconButton(
                  tooltip: 'My Orders',
                  icon: const Icon(Icons.local_shipping_outlined, color: Colors.deepPurple),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerOrdersScreen(currentUser: currentUser),
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'My Profile & Address',
                  icon: const Icon(Icons.account_circle_outlined, color: Colors.deepPurple),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerProfileScreen(currentUser: currentUser),
                      ),
                    );
                  },
                ),
              ],

              // CART
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: 'Cart',
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(
                            cart: cart,
                            currentUser: currentUser,
                            onUpdate: () => setState(() {}),
                          ),
                        ),
                      );
                    },
                  ),
                  if (totalCartItems > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          '$totalCartItems',
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),

              // LOGIN / LOGOUT
              if (!isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    onPressed: _openAuthDialog,
                  ),
                )
              else
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () => FirebaseAuth.instance.signOut(),
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products in SVR Store...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() => searchQuery = val),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    final products = docs.map((doc) => Product.fromFirestore(doc)).toList();

                    final filtered = products.where((product) {
                      final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
                      final matchesCategory = selectedCategory == 'All' || product.category == selectedCategory;
                      return matchesSearch && matchesCategory;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No products found in SVR Store!'));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.70,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    item.imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () => addToCart(item),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Text('Add to Cart', style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
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
      },
    );
  }
}

// ---------------- CUSTOMER: MY ORDERS SCREEN ----------------
class CustomerOrdersScreen extends StatelessWidget {
  final User currentUser;
  const CustomerOrdersScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No orders placed yet!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status']?.toString() ?? 'Pending';
              final List items = (data['items'] as List?) ?? [];
              final num total = data['totalAmount'] ?? 0;

              Color statusColor = Colors.orange;
              if (status == 'Shipped') statusColor = Colors.blue;
              if (status == 'Delivered') statusColor = Colors.green;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #${doc.id.substring(0, 6).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      ...items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item['name']} x ${item['quantity']}'),
                                Text('₹${(item['price'] * item['quantity']).toStringAsFixed(0)}'),
                              ],
                            ),
                          )),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount (COD):', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                        ],
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

// ---------------- CUSTOMER: PROFILE & SAVED ADDRESS SCREEN ----------------
class CustomerProfileScreen extends StatefulWidget {
  final User currentUser;
  const CustomerProfileScreen({super.key, required this.currentUser});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
        _cityController.text = data['city'] ?? '';
        _pincodeController.text = data['pincode'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'email': widget.currentUser.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile details saved!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile & Address')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(radius: 36, backgroundColor: Colors.deepPurple, child: Icon(Icons.person, size: 40, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(widget.currentUser.email ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Saved Delivery Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 12),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _addressController, maxLines: 2, decoration: const InputDecoration(labelText: 'Street Address', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _pincodeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Address'),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}

// ---------------- CART & CHECKOUT (AUTO FILL SAVED ADDRESS) ----------------
class CartScreen extends StatefulWidget {
  final List<CartItem> cart;
  final User? currentUser;
  final VoidCallback onUpdate;

  const CartScreen({
    super.key,
    required this.cart,
    required this.currentUser,
    required this.onUpdate,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double get totalPrice =>
      widget.cart.fold(0, (total, item) => total + (item.product.price * item.quantity));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SVR Store Cart')),
      body: widget.cart.isEmpty
          ? const Center(child: Text('Your cart is empty!'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final item = widget.cart[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.product.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('₹${(item.product.price * item.quantity).toStringAsFixed(0)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      widget.cart.removeAt(index);
                                    }
                                  });
                                  widget.onUpdate();
                                },
                              ),
                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() => item.quantity++);
                                  widget.onUpdate();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16)),
                          onPressed: () {
                            if (widget.currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please login first to place an order!')),
                              );
                              showDialog(context: context, builder: (context) => const AuthDialog());
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutScreen(
                                  cart: widget.cart,
                                  currentUser: widget.currentUser!,
                                  totalPrice: totalPrice,
                                  onOrderCompleted: () {
                                    setState(() => widget.cart.clear());
                                    widget.onUpdate();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cart;
  final User currentUser;
  final double totalPrice;
  final VoidCallback onOrderCompleted;

  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.currentUser,
    required this.totalPrice,
    required this.onOrderCompleted,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSavedAddress();
  }

  Future<void> _fetchSavedAddress() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _cityController.text = data['city'] ?? '';
          _pincodeController.text = data['pincode'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final orderData = {
        'userId': widget.currentUser.uid,
        'userEmail': widget.currentUser.email,
        'timestamp': FieldValue.serverTimestamp(),
        'totalAmount': widget.totalPrice,
        'status': 'Pending',
        'paymentMode': 'Cash on Delivery',
        'customer': {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        },
        'items': widget.cart.map((item) => {
          'name': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
        }).toList(),
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      // Save this address as default if user hasn't saved before
      await FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'email': widget.currentUser.email,
      }, SetOptions(merge: true));

      if (!mounted) return;
      widget.onOrderCompleted();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Order Placed Successfully! 🎉'),
          content: Text('Your order worth ₹${widget.totalPrice.toStringAsFixed(0)} will be delivered via Cash on Delivery.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().length < 10 ? 'Enter valid number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Delivery Address', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter address' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter city' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter pincode' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSubmitting ? null : _submitOrder,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Order (COD)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ORDERS DASHBOARD (ADMIN ONLY) ----------------
class OrdersDashboardScreen extends StatelessWidget {
  const OrdersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Orders Dashboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No orders placed yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status']?.toString() ?? 'Pending';
              final List items = (data['items'] as List?) ?? [];
              final num total = data['totalAmount'] ?? 0;
              final customer = data['customer'] as Map<String, dynamic>?;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #${doc.id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(status, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (customer != null)
                        Text('Customer: ${customer['name']} | ${customer['phone']} | ${customer['city']}'),
                      const Divider(),
                      ...items.map((i) => Text("${i['name']} x ${i['quantity']} - ₹${i['price'] * i['quantity']}")),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: ₹$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          DropdownButton<String>(
                            value: ['Pending', 'Shipped', 'Delivered'].contains(status) ? status : 'Pending',
                            items: ['Pending', 'Shipped', 'Delivered'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                FirebaseFirestore.instance.collection('orders').doc(doc.id).update({'status': newStatus});
                              }
                            },
                          ),
                        ],
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

// ---------------- MANAGE PRODUCTS (ADMIN ONLY) ----------------
class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Electronics';
  final List<String> _categories = ['Electronics', 'Footwear', 'Accessories', 'Fashion'];
  bool _isLoading = false;

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'category': _selectedCategory,
        'imageUrl': _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
        'description': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
      _nameController.clear();
      _priceController.clear();
      _imageUrlController.clear();
      _descriptionController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid price' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _addProduct,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Product'),
                ),
              ),
              const Divider(height: 32),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['name'] ?? ''),
                        subtitle: Text('₹${data['price']} • ${data['category']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => FirebaseFirestore.instance.collection('products').doc(doc.id).delete(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- AUTH DIALOG ----------------
class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoginMode = true;
  bool isLoading = false;

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      if (isLoginMode) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Authentication failed')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(isLoginMode ? Icons.login : Icons.person_add, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Text(isLoginMode ? 'Login to SVR Store' : 'Create Account'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading ? null : _submitAuth,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isLoginMode ? 'Login' : 'Sign Up'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => isLoginMode = !isLoginMode),
              child: Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
