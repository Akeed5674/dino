// No-op AdsService for testing (no ads).
class AdsService {
  static Future<void> init() async {
    // nothing
  }

  static Future<void> maybeShowInterstitial() async {
    // nothing
  }
}
