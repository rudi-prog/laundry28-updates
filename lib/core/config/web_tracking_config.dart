// Web Tracking URL Configuration
// Ganti URL ini setelah deploy halaman tracking ke hosting (Vercel/Netlify/GitHub Pages)
class WebTrackingConfig {
  // Placeholder - ganti dengan URL production setelah deploy
  static const String baseUrl = 'https://laundry28-tracking.vercel.app';
  
  // Generate full tracking URL dengan kode tracking
  static String getTrackingUrl(String trackingCode) {
    return '$baseUrl?code=$trackingCode';
  }
}
