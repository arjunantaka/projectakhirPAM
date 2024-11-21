import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'PurchasePage.dart';

class BookDetailPage extends StatelessWidget {
  final Map<String, dynamic> bookData;

  const BookDetailPage({required this.bookData});

  Future<void> buyBook(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PurchasePage(bookData: bookData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final volumeInfo = bookData['volumeInfo'];
    final saleInfo = bookData['saleInfo'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Buku'),
        backgroundColor: Color(0xFF6B4EFF),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                volumeInfo['imageLinks']?['thumbnail'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.book, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    volumeInfo['title'] ?? 'No Title',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Author
                  Text(
                    'by ${volumeInfo['authors']?.join(", ") ?? "Unknown Author"}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Description
                  Text(
                    volumeInfo['description'] ?? 'Deskripsi tidak tersedia.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  // Price
                  Text(
                    saleInfo != null && saleInfo['listPrice'] != null
                        ? 'Harga: Rp ${(saleInfo['listPrice']['amount'] ?? 0).toStringAsFixed(0)}'
                        : 'Gratis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4EFF),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Buy Button
                  ElevatedButton(
                    onPressed: () => buyBook(context),
                    child: Text(
                      'Beli',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6B4EFF),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
