class WarningCard {
  final String title;
  final String content;
  final String severity; // 'high' | 'medium' | 'low'

  const WarningCard({
    required this.title,
    required this.content,
    required this.severity,
  });

  factory WarningCard.fromJson(Map<String, dynamic> json) => WarningCard(
        title: json['title'] as String,
        content: json['content'] as String,
        severity: json['severity'] as String,
      );
}

class MapPin {
  final String name;
  final double lat;
  final double lng;
  final String type; // 'labor' | 'welfare' | 'legal'
  final String? phone;
  final String? address;

  const MapPin({
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
    this.phone,
    this.address,
  });

  factory MapPin.fromJson(Map<String, dynamic> json) => MapPin(
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        type: json['type'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
      );
}

class ChatApiResponse {
  final String sessionId;
  final String reply;
  final List<WarningCard> warningCards;
  final List<MapPin> mapPins;
  final List<String> nextActions;

  const ChatApiResponse({
    required this.sessionId,
    required this.reply,
    this.warningCards = const [],
    this.mapPins = const [],
    this.nextActions = const [],
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) => ChatApiResponse(
        sessionId: json['session_id'] as String,
        reply: json['reply'] as String,
        warningCards: (json['warning_cards'] as List<dynamic>? ?? [])
            .map((e) => WarningCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        mapPins: (json['map_pins'] as List<dynamic>? ?? [])
            .map((e) => MapPin.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextActions: (json['next_actions'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );

  bool get hasWarnings => warningCards.isNotEmpty;
  bool get hasPins => mapPins.isNotEmpty;
}
