import 'package:flutter/material.dart';
import 'package:flutter_application_1/notification_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PurchasePage extends StatefulWidget {
  final Map<String, dynamic> bookData;

  const PurchasePage({required this.bookData});

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  String selectedCurrency = 'IDR';
  double conversionRate = 1.0;

  // Hardcoded conversion rates for demonstration
  final Map<String, double> conversionRates = {
    'IDR': 1.0,
    'USD': 0.000067, // Example conversion rate
    'EUR': 0.000058, // Example conversion rate
    'GBP': 0.000050, // Example conversion rate
    'JPY': 0.0073, // Example conversion rate
  };

  String getPrice(dynamic saleInfo) {
    if (saleInfo != null && saleInfo['listPrice'] != null) {
      var amount = saleInfo['listPrice']['amount'];
      if (amount is int || amount is double) {
        double price = amount.toDouble() * conversionRate;
        return price > 0
            ? '${selectedCurrency} ${price.toStringAsFixed(2)}'
            : '0'; // Return '0' if the price is free
      }
    }
    return '0'; // Return '0' if no price is available
  }

  Future<void> _purchaseBook(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final volumeInfo = widget.bookData['volumeInfo'];
    final saleInfo = widget.bookData['saleInfo'];

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final domain = prefs.getString('domain');

      final userResponse = await http.get(
        Uri.parse('$domain/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final bookTitle = volumeInfo['title'] ?? '';

        final purchaseData = {
          'googleBookId': widget.bookData['id'] ?? '',
          'title': bookTitle,
          'author': volumeInfo['authors']?.join(', ') ?? 'Unknown',
          'price': (saleInfo['listPrice'] != null &&
                  saleInfo['listPrice']['amount'] > 0)
              ? saleInfo['listPrice']['amount']
              : 0,
          'purchasedBy': userData['_id'] ?? '',
        };

        final response = await http.post(
          Uri.parse('$domain/api/purchase'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(purchaseData),
        );

        if (response.statusCode == 201) {
          // Show local notification
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'purchase_channel',
            'Purchase Notifications',
            channelDescription: 'Notifications for successful purchases',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);

          await LocalNotificationHelper.flutterLocalNotificationsPlugin.show(
            0,
            'Pembelian Berhasil! 🎉',
            'Buku "$bookTitle" telah ditambahkan ke koleksi Anda',
            platformChannelSpecifics,
          );

          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Pembayaran berhasil')),
          );
          navigator.pop();
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Gagal melakukan pembelian: ${response.body}'),
            ),
          );
        }
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data pengguna')),
        );
      }
    } catch (e) {
      print('Error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _changeCurrency(String currency) {
    setState(() {
      selectedCurrency = currency;
      conversionRate = conversionRates[currency] ?? 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final volumeInfo = widget.bookData['volumeInfo'];
    final saleInfo = widget.bookData['saleInfo'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Konfirmasi Pembayaran'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volumeInfo['title'] ?? 'No Title',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Author: ${volumeInfo['authors']?.join(', ') ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontFamily: 'Roboto',
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Harga: ${getPrice(saleInfo)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Pilih Mata Uang:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _currencyButton('IDR'),
                        _currencyButton('USD'),
                        _currencyButton('EUR'),
                        _currencyButton('GBP'),
                        _currencyButton('JPY'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _purchaseBook(context),
                child: Text(
                  'Bayar Sekarang',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  backgroundColor: Colors.indigo,
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyButton(String currency) {
    return ElevatedButton(
      onPressed: () => _changeCurrency(currency),
      style: ElevatedButton.styleFrom(
        foregroundColor:
            selectedCurrency == currency ? Colors.white : Colors.black,
        backgroundColor: selectedCurrency == currency
            ? Colors.indigo
            : Color(0xFFEEEEEE), // Warna teks tombol
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: selectedCurrency == currency ? 4 : 0,
        textStyle: TextStyle(
          fontSize: 16,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Text(currency),
    );
  }
}
