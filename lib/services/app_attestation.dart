import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Enabled only after registering Android/Web providers in Firebase Console.
class AppAttestation {
  static const enabled =
      bool.fromEnvironment('PLANTIFY_APP_CHECK', defaultValue: false);
  static const webSiteKey =
      String.fromEnvironment('PLANTIFY_RECAPTCHA_SITE_KEY');

  static Future<void> initialize() async {
    if (!enabled) return;
    if (kIsWeb && webSiteKey.isEmpty) {
      throw StateError(
          'App Check requires PLANTIFY_RECAPTCHA_SITE_KEY on Web.');
    }
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerWeb: kIsWeb ? ReCaptchaV3Provider(webSiteKey) : null,
    );
  }

  static Future<Map<String, String>> headers() async {
    if (!enabled) return const {};
    final token = await FirebaseAppCheck.instance.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('App verification failed. Please try again.');
    }
    return {'X-Firebase-AppCheck': token};
  }
}
