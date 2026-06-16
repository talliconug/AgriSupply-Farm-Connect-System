import 'dart:convert';

import 'api_service.dart';

class AIMessage {

  AIMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.imageUrl,
  });

  factory AIMessage.fromJson(final Map<String, dynamic> json) => AIMessage(
    role: json['role'] as String,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    imageUrl: json['image_url'] as String?,
  );
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'image_url': imageUrl,
  };
}

class ChatSession {

  ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromJson(final Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    messages: (json['messages'] as List? ?? [])
        .map((final m) => AIMessage.fromJson(m as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
  final String id;
  final String userId;
  final String title;
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'messages': messages.map((final m) => m.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class AIService {
  final ApiService _apiService = ApiService();

  // Note: System prompt is handled by the backend API
  // Kept here for reference only
  /*
  static const String _systemPrompt = '''
You are AgriSupply AI, a helpful farming assistant for farmers in Uganda. 
You provide advice on:
- Crop cultivation and best practices
- Pest and disease management
- Weather-based farming recommendations
- Market prices and trends in Uganda
- Sustainable farming techniques
- Organic farming methods
- Soil health and fertilization
- Irrigation and water management
- Post-harvest handling and storage
- Agricultural regulations in Uganda

Always provide practical, actionable advice suitable for Ugandan farming conditions.
Consider local climate, common crops (maize, beans, cassava, coffee, bananas, etc.), 
and local market conditions in your responses.

Be friendly, supportive, and encouraging to farmers.
If asked about topics outside of farming and agriculture, politely redirect the 
conversation back to farming-related topics.
''';
  */

  // Send message and get AI response
  Future<String> sendMessage({
    required final String message,
    required final String userId,
    final String? sessionId,
    final String? imageBase64,
    final List<AIMessage>? conversationHistory,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': message,
        'user_id': userId,
      };

      if (sessionId != null) body['session_id'] = sessionId;
      if (imageBase64 != null) body['image'] = imageBase64;

      final response = await _apiService.post('/ai/chat', body: body);

      return (response['response'] ?? response['message'] ?? response['content'] ?? "I apologize, but I couldn't generate a response. Please try again.") as String;
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  // Simple chat method
  Future<String> chat(final String message) async {
    try {
      final response = await _apiService.post('/ai/chat', body: {
        'message': message,
      });

      // Backend returns: { success: true, data: { message: "...", sessionId: "..." } }
      if (response['data'] != null && response['data']['message'] != null) {
        return response['data']['message'] as String;
      }
      
      return response['message'] as String? ?? "I apologize, but I couldn't generate a response. Please try again.";
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  // Analyze crop image
  Future<Map<String, dynamic>> analyzeCropImage({
    required final String imageBase64,
    required final String userId,
  }) async {
    try {
      final response = await _apiService.post('/ai/analyze-crop', body: {
        'image': imageBase64,
        'user_id': userId,
      });

      return {
        'crop_name': response['crop_name'],
        'health_status': response['health_status'],
        'issues': response['issues'] ?? <dynamic>[],
        'recommendations': response['recommendations'] ?? <dynamic>[],
        'confidence': response['confidence'] ?? 0.0,
      };
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  // Get farming tips
  Future<List<String>> getFarmingTips({
    final String? crop,
    final String? season,
    final String? region,
  }) async {
    try {
      final params = <String, String>{};
      if (crop != null) params['crop'] = crop;
      if (season != null) params['season'] = season;
      if (region != null) params['region'] = region;

      final response = await _apiService.get('/ai/farming-tips', queryParams: params);
      return List<String>.from((response['tips'] as List?) ?? []);
    } catch (e) {
      throw Exception('Failed to get farming tips: $e');
    }
  }

  // Get market price predictions
  Future<Map<String, dynamic>> getMarketPredictions({
    required final String crop,
    required final String region,
  }) async {
    try {
      final response = await _apiService.get('/ai/market-predictions', queryParams: {
        'crop': crop,
        'region': region,
      });

      return {
        'current_price': response['current_price'],
        'predicted_price': response['predicted_price'],
        'trend': response['trend'],
        'best_time_to_sell': response['best_time_to_sell'],
        'confidence': response['confidence'],
      };
    } catch (e) {
      throw Exception('Failed to get market predictions: $e');
    }
  }

  // Get weather-based recommendations
  Future<List<String>> getWeatherRecommendations({
    required final double latitude,
    required final double longitude,
  }) async {
    try {
      final response = await _apiService.get('/ai/weather-recommendations', queryParams: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
      });

      return List<String>.from((response['recommendations'] as List?) ?? []);
    } catch (e) {
      throw Exception('Failed to get weather recommendations: $e');
    }
  }

  // Save chat session
  Future<void> saveChatSession({
    required final String userId,
    required final String sessionId,
    required final String title,
    required final List<AIMessage> messages,
  }) async {
    try {
      final existingSession = await _apiService.getById('ai_chat_sessions', sessionId);
      
      if (existingSession != null) {
        await _apiService.update('ai_chat_sessions', sessionId, {
          'messages': jsonEncode(messages.map((final m) => m.toJson()).toList()),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _apiService.insert('ai_chat_sessions', {
          'id': sessionId,
          'user_id': userId,
          'title': title,
          'messages': jsonEncode(messages.map((final m) => m.toJson()).toList()),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to save chat session: $e');
    }
  }

  // Get chat sessions
  Future<List<ChatSession>> getChatSessions(final String userId) async {
    try {
      final data = await _apiService.query(
        'ai_chat_sessions',
        filters: {'user_id': userId},
        orderBy: 'updated_at',
        limit: 50,
      );

      return data.map((final json) {
        if (json['messages'] is String) {
          json['messages'] = jsonDecode(json['messages'] as String);
        }
        return ChatSession.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get chat sessions: $e');
    }
  }

  // Delete chat session
  Future<void> deleteChatSession(final String sessionId) async {
    try {
      await _apiService.deleteRecord('ai_chat_sessions', sessionId);
    } catch (e) {
      throw Exception('Failed to delete chat session: $e');
    }
  }

  // Quick questions for the AI assistant
  static List<String> get quickQuestions => [
    'What crops grow best in my region?',
    'How do I prevent pests naturally?',
    'When is the best time to plant maize?',
    'How can I improve soil fertility?',
    'What are current market prices?',
    'How do I store my harvest properly?',
    'What organic fertilizers can I use?',
    'How do I identify crop diseases?',
  ];

  // Generate title from first message
  String generateSessionTitle(final String firstMessage) {
    if (firstMessage.length <= 50) {
      return firstMessage;
    }
    return '${firstMessage.substring(0, 47)}...';
  }
}
