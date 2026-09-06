import 'package:flutter/material.dart'; // تم تعديل حرف الـ i ليكون صغيراً

void main() {
  runApp(const ClothingStoreApp());
}

class ClothingStoreApp extends StatelessWidget {
  const ClothingStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.star, color: Colors.deepPurple),
        title: const Text(
          'متجر الملابس',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. قسم الفئات الأفقية للملابس
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  CategoryItem(title: 'تيشرتات', iconData: Icons.checkroom),
                  CategoryItem(title: 'بناطيل', iconData: Icons.shopping_bag),
                  CategoryItem(title: 'جواكت', iconData: Icons.dry_cleaning),
                  CategoryItem(title: 'أحذية', iconData: Icons.local_mall),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'New Arrivals',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            // 2. قسم المنتجات الجديدة (بدون مسارات الصور حالياً)
            SizedBox(
              height: 220,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  ProductCard(title: 'جاكيت شتوي أنيق'),
                  ProductCard(title: 'تيشرت كاجوال قطن'),
                  ProductCard(title: 'تيشرت كاجوال قطن'),
                  ProductCard(title: 'تيشرت كاجوال قطن'),
                  ProductCard(title: 'تيشرت كاجوال قطن'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  const CategoryItem({super.key, required this.title, required this.iconData});
  final String title;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(iconData, color: Colors.deepPurple),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  // قمنا بإزالة مسار الصورة من المتطلبات هنا
  const ProductCard({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              // استبدلنا الصورة الحقيقية بمربع رمادي مؤقت بداخله أيقونة صورة
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
