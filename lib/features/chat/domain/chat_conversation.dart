class ChatConversation {
  final String id;
  final String title;
  final String providerId;
  final String model;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    required this.title,
    required this.providerId,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
  });

  static String generateTitle(String firstMessage) {
    var title = firstMessage.trim();
    title = title.replaceAll(RegExp(r'\s+'), ' ');
    if (title.length > 40) {
      title = '${title.substring(0, 40)}...';
    }
    return title;
  }
}
