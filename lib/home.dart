import 'package:flutter/material.dart';
import 'package:flutter_application_1/profile.dart';
import 'package:flutter_application_1/mybooks.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'BookDetailPage.dart';
import 'kesan.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> books = [];
  bool isLoading = true;
  int startIndex = 0;
  String currentQuery = 'programming';
  final int maxResults = 10;

  final List<Category> categories = [
    Category(icon: Icons.code, name: "Pemrograman", query: "buku pemrograman"),
    Category(icon: Icons.business, name: "Bisnis", query: "buku bisnis"),
    Category(
        icon: Icons.psychology,
        name: "Pengembangan Diri",
        query: "buku pengembangan diri"),
    Category(icon: Icons.menu_book, name: "Novel", query: "novel indonesia"),
    Category(icon: Icons.science, name: "Sains", query: "buku sains"),
  ];

  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        isLoading = true;
        startIndex = 0;
      });
    }

    try {
      final query = selectedCategory ?? currentQuery;
      final apiKey = ''; // Ganti dengan kunci API Anda
      final url =
          'https://www.googleapis.com/books/v1/volumes?q=$query&langRestrict=id&startIndex=$startIndex&maxResults=$maxResults&key=$apiKey';
      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null) {
          setState(() {
            if (loadMore) {
              books.addAll(data['items']);
              startIndex += maxResults;
            } else {
              books = data['items'];
              startIndex = maxResults;
            }
            isLoading = false;
          });
        } else {
          setState(() {
            books = [];
            isLoading = false;
          });
        }
      } else {
        throw Exception(
            'Failed to load books. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF6B4EFF),
        title: Text('BookStore', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MyBooksPage()));
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfilePage()));
            },
          ),
        ],
      ),
      body: isLoading && books.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EFF))))
          : RefreshIndicator(
              onRefresh: () => fetchBooks(),
              child: CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF6B4EFF),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Cari buku...',
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              currentQuery = _searchController.text;
                              fetchBooks();
                            },
                            child: Icon(Icons.search, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.3),
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Categories
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kategori',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return CategoryCard(
                                  category: category,
                                  isSelected:
                                      category.query == selectedCategory,
                                  onTap: () {
                                    setState(() {
                                      selectedCategory =
                                          selectedCategory == category.query
                                              ? null
                                              : category.query;
                                    });
                                    fetchBooks();
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Books Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Rekomendasi Buku',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // Books Grid
                  SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = books[index];
                        final volumeInfo = book['volumeInfo'];
                        final saleInfo = book['saleInfo'];
                        return BookCard(
                          title: volumeInfo['title'] ?? 'No Title',
                          author: getAuthors(volumeInfo),
                          imageUrl: getImageUrl(volumeInfo),
                          price: getPrice(saleInfo),
                          bookData: book,
                        );
                      },
                      childCount: books.length,
                    ),
                  ),

                  // Show More Button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed:
                            isLoading ? null : () => fetchBooks(loadMore: true),
                        child: isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white))
                            : Text(
                                'Tampilkan Lebih Banyak',
                                style: TextStyle(color: Colors.white),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6B4EFF),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF6B4EFF),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Keranjang'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.feedback), label: 'Kesan & Pesan'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => MyBooksPage()));
          } else if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ProfilePage()));
          } else if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => FeedbackPage()));
          }
        },
      ),
    );
  }
}

// Helper functions to parse book data
String getAuthors(dynamic volumeInfo) {
  return volumeInfo['authors'] != null && volumeInfo['authors'].isNotEmpty
      ? volumeInfo['authors'][0]
      : 'Unknown Author';
}

String getImageUrl(dynamic volumeInfo) {
  return volumeInfo['imageLinks'] != null &&
          volumeInfo['imageLinks']['thumbnail'] != null
      ? volumeInfo['imageLinks']['thumbnail']
      : '';
}

String getPrice(dynamic saleInfo) {
  if (saleInfo != null && saleInfo['listPrice'] != null) {
    final double price = (saleInfo['listPrice']['amount'] ?? 0).toDouble();
    return 'Rp ${price.toStringAsFixed(0)}';
  }
  return 'Gratis';
}

class Category {
  final IconData icon;
  final String name;
  final String query;

  Category({required this.icon, required this.name, required this.query});
}

class CategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard(
      {required this.category, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF6B4EFF) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(category.icon,
                  size: 24, color: isSelected ? Colors.white : Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Color(0xFF6B4EFF) : Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final String title;
  final String author;
  final String imageUrl;
  final String price;
  final Map<String, dynamic> bookData;

  const BookCard(
      {required this.title,
      required this.author,
      required this.imageUrl,
      required this.price,
      required this.bookData});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BookDetailPage(bookData: bookData)));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover, width: double.infinity)
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.book, size: 48, color: Colors.grey)),
              ),
            ),
            // Book details
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4),
                  Text(author,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 8),
                  Text(price,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4EFF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
