import 'package:url_launcher/url_launcher.dart';

class ExternalContactService {
  static String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static Future<bool> call(String phone) {
    return _launch(Uri(scheme: 'tel', path: normalizePhone(phone)));
  }

  static Future<bool> chat(String phone, {String? message}) {
    final normalized = normalizePhone(phone);
    return _launch(
      Uri(
        scheme: 'sms',
        path: normalized,
        queryParameters: message == null ? null : {'body': message},
      ),
    );
  }

  static Future<bool> video(String phone) {
    final normalized = normalizePhone(phone).replaceFirst('+', '');
    return _launch(Uri.parse('https://wa.me/$normalized'));
  }

  static Future<bool> _launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
