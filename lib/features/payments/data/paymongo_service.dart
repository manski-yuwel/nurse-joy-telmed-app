import 'dart:convert';
import 'package:http/http.dart' as http;

class PayMongoService {
  static const _secretKey = 'sk_test_LNzYT5SD79VMDDscV9ftcKX3';
  static const _baseUrl = 'https://api.paymongo.com/v1';

  static Future<String> createGcashCheckout(int amount, String userId) async {
    final payload = {
      "data": {
        "attributes": {
          "send_email_receipt": false,
          "show_description": true,
          "show_line_items": true,
          "cancel_url": "https://nursejoy.app/nursejoy/cancel",
          "description": "GCash Payment",
          "line_items": [
            {
              "currency": "PHP",
              "amount": amount * 100,
              "name": "Wallet Top-up",
              "quantity": 1
            }
          ],
          "payment_method_types": ["gcash"],
          "reference_number": "user-$userId-${DateTime.now().millisecondsSinceEpoch}",
          "success_url": "https://nursejoy.app/nursejoy/success"
        }
      }
    };

    final response = await http.post(
      Uri.parse("$_baseUrl/checkout_sessions"),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_secretKey:'))}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      print("PayMongo Error Response: ${response.body}");
      throw Exception("PayMongo error: ${data['errors']?[0]?['detail'] ?? 'Unknown error'}");
    }

    final checkoutUrl = data['data']?['attributes']?['checkout_url'];

    if (checkoutUrl == null) {
      throw Exception("Missing checkout_url in PayMongo response");
    }

    return checkoutUrl;
  }
}
