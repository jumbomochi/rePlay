import 'dart:convert';
import 'dart:io';

class BarcodeLookupService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  Future<String?> lookupBarcode(String barcode) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$_baseUrl/$barcode.json'));
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['status'] != 1) return null;
      final product = data['product'] as Map<String, dynamic>?;
      return product?['product_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
