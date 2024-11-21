import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MyBooksPage extends StatefulWidget {
  @override
  _MyBooksPageState createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage> {
  List<dynamic> myBooks = [];
  bool isLoading = true;
  String currentCurrencySymbol = 'Rp'; // Simbol default IDR
  String currentTimeZone = 'WIB'; // Zona waktu default WIB
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchMyBooks();
  }

  Future<void> fetchMyBooks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final domain = prefs.getString('domain');
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('$domain/api/my-books'), // Pastikan URL benar
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            myBooks = data['books'];
            isLoading = false;
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('Error fetching books: $e');
    }
  }

// Fungsi Konversi Mata Uang
  void convertCurrency(String toCurrency, String symbol) {
    const rates = {
      'USD': 0.000066,
      'EUR': 0.000062,
      'JPY': 0.0098,
      'SGD': 0.00009,
      'IDR': 1.0, // Base currency
    };

    setState(() {
      for (var book in myBooks) {
        final rate = rates[toCurrency] ?? 1.0;
        book['price'] = (book['originalPrice'] * rate).toStringAsFixed(2);
      }
      currentCurrencySymbol = symbol; // Simpan simbol mata uang
    });
  }

  // Fungsi Konversi Waktu
  void convertTime(String toTimeZone) {
    setState(() {
      currentTimeZone = toTimeZone; // Simpan zona waktu aktif
      for (var book in myBooks) {
        // Simpan waktu asli jika belum disimpan
        if (!book.containsKey('originalPurchasedAt')) {
          book['originalPurchasedAt'] = book['purchasedAt'];
        }

        final originalTime = DateTime.parse(book['originalPurchasedAt']);
        DateTime convertedTime;

        // Konversi waktu berdasarkan zona waktu yang dipilih
        switch (toTimeZone) {
          case 'WITA':
            convertedTime = originalTime.add(Duration(hours: 1));
            break;
          case 'WIT':
            convertedTime = originalTime.add(Duration(hours: 2));
            break;
          case 'GMT':
            convertedTime = originalTime.subtract(Duration(hours: 7));
            break;
          default: // WIB
            convertedTime = originalTime;
        }

        // Update waktu hasil konversi
        book['purchasedAt'] = convertedTime.toIso8601String();
      }
    });
  }

  void _showCurrencyConverterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konversi Mata Uang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            {'currency': 'USD', 'symbol': '\$'},
            {'currency': 'EUR', 'symbol': '€'},
            {'currency': 'JPY', 'symbol': '¥'},
            {'currency': 'SGD', 'symbol': 'S\$'},
            {'currency': 'IDR', 'symbol': 'Rp'}
          ].map((option) {
            return ListTile(
              title: Text('Ke ${option['currency']}'),
              onTap: () {
                convertCurrency(option['currency']!, option['symbol']!);
                Navigator.pop(context); // Tutup dialog setelah dipilih
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTimeConverterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konversi Waktu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['WIB', 'WITA', 'WIT', 'GMT']
              .map((zone) => ListTile(
                    title: Text('Ke $zone'),
                    onTap: () {
                      convertTime(zone);
                      Navigator.pop(context); // Tutup dialog setelah dipilih
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buku Saya'),
        backgroundColor: Color(0xFF6B4EFF),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _showCurrencyConverterDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text('Konversi Mata Uang'),
                      ),
                      ElevatedButton(
                        onPressed: _showTimeConverterDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text('Konversi Waktu'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: myBooks.length,
                    itemBuilder: (context, index) {
                      final book = myBooks[index];
                      return BookCard(
                        book: book,
                        currencySymbol: currentCurrencySymbol,
                        timeZone: currentTimeZone,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final String currencySymbol;
  final String timeZone;

  const BookCard({
    required this.book,
    required this.currencySymbol,
    required this.timeZone,
  });

  String _formatPrice(dynamic price) {
    return NumberFormat.currency(locale: 'en', symbol: currencySymbol)
        .format(double.tryParse(price.toString()) ?? 0);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tanggal tidak tersedia';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return 'Tanggal tidak valid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder Book Cover
            Container(
              width: 80,
              height: 120,
              color: Colors.grey[200],
              child: Icon(Icons.book, size: 40, color: Colors.grey),
            ),
            SizedBox(width: 16),
            // Book Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] ?? 'Untitled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    book['author'] ?? 'Unknown Author',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatPrice(book['price']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4EFF),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Dibeli pada: ${_formatDate(book['purchasedAt'])} ($timeZone)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
