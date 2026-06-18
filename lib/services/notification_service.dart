class NotificationService {
  static Future<void> initialize() async {
    // Web testinde gerçek bildirim başlatmıyoruz.
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    // Şimdilik test için terminale yazdırıyoruz.
    print("$title - $body");
  }
}