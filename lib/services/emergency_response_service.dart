import 'package:flutter/foundation.dart';
import 'package:runanywhere/runanywhere.dart';
import 'emergency_prompts.dart';

/// Emergency Response Service
/// Manages emergency AI interactions with specialized prompts and knowledge
class EmergencyResponseService extends ChangeNotifier {
  EmergencyCategory _currentCategory = EmergencyCategory.general;
  List<EmergencyMessage> _conversationHistory = [];
  bool _isProcessing = false;
  String? _error;

  EmergencyCategory get currentCategory => _currentCategory;
  List<EmergencyMessage> get conversationHistory => _conversationHistory;
  bool get isProcessing => _isProcessing;
  String? get error => _error;

  /// Set the current emergency category and update system prompt
  void setCategory(EmergencyCategory category) {
    _currentCategory = category;
    _error = null;
    notifyListeners();
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
    _error = null;
    notifyListeners();
  }

  /// Add a user message to history
  void addUserMessage(String message) {
    _conversationHistory.add(EmergencyMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
      category: _currentCategory,
    ));
    notifyListeners();
  }

  /// Add an AI response to history
  void addAIMessage(String message) {
    _conversationHistory.add(EmergencyMessage(
      text: message,
      isUser: false,
      timestamp: DateTime.now(),
      category: _currentCategory,
    ));
    notifyListeners();
  }

  /// Get emergency response using the LLM with specialized prompts
  Future<String> getEmergencyResponse(String userQuery) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Get the appropriate system prompt for the current category
      final systemPrompt = EmergencyPrompts.getPromptForCategory(_currentCategory);

      // Build conversation context properly keeping both sides of conversation
      final pastHistory = _conversationHistory.length > 1
          ? _conversationHistory.sublist(0, _conversationHistory.length - 1)
          : <EmergencyMessage>[];
          
      final recentHistory = pastHistory.length > 6 
          ? pastHistory.sublist(pastHistory.length - 6) 
          : pastHistory;

      String formattedPrompt = '';
      
      if (recentHistory.isNotEmpty) {
        formattedPrompt += "Previous conversation context:\n";
        for (var m in recentHistory) {
          formattedPrompt += "${m.isUser ? 'User' : 'Assistant'}: ${m.text}\n";
        }
        formattedPrompt += "\n---\n\n";
      }

      final fullPrompt = '''
$formattedPrompt
Based on the context, provide a direct, helpful, and concise response to the user's latest message. DO NOT quote or repeat the user's message. DO NOT repeat the conversation history. DO NOT use conversational filler if an emergency procedure is needed.

User: $userQuery
Assistant:''';

      // Generate response using RunAnywhere SDK
      final result = await RunAnywhere.generate(
        fullPrompt,
        options: LLMGenerationOptions(
          maxTokens: 200,
          temperature: 0.3, // Lower temperature for more consistent, reliable responses
          systemPrompt: systemPrompt,
        ),
      );

      final response = result.text.trim();

      // Add AI response to history
      addAIMessage(response);

      _isProcessing = false;
      notifyListeners();

      return response;
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Stream emergency response for real-time updates
  Stream<String> streamEmergencyResponse(String userQuery) async* {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Get the appropriate system prompt
      final systemPrompt = EmergencyPrompts.getPromptForCategory(_currentCategory);

      // Build conversation context properly keeping both sides of conversation
      final pastHistory = _conversationHistory.length > 1
          ? _conversationHistory.sublist(0, _conversationHistory.length - 1)
          : <EmergencyMessage>[];
          
      final recentHistory = pastHistory.length > 6 
          ? pastHistory.sublist(pastHistory.length - 6) 
          : pastHistory;

      String formattedPrompt = '';
      
      if (recentHistory.isNotEmpty) {
        formattedPrompt += "Previous conversation context:\n";
        for (var m in recentHistory) {
          formattedPrompt += "${m.isUser ? 'User' : 'Assistant'}: ${m.text}\n";
        }
        formattedPrompt += "\n---\n\n";
      }

      final fullPrompt = '''
$formattedPrompt
Based on the context, provide a direct, helpful, and concise response to the user's latest message. DO NOT quote or repeat the user's message. DO NOT repeat the conversation history. DO NOT use conversational filler if an emergency procedure is needed.

User: $userQuery
Assistant:''';

      // Stream tokens
      final streamResult = await RunAnywhere.generateStream(
        fullPrompt,
        options: LLMGenerationOptions(
          maxTokens: 200,
          temperature: 0.3,
          systemPrompt: systemPrompt,
        ),
      );

      String fullResponse = '';
      await for (final token in streamResult.stream) {
        fullResponse += token;
        yield token;
      }

      // Add complete response to history
      addAIMessage(fullResponse.trim());

      _isProcessing = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Quick protocol lookup - get step-by-step guide for emergency action
  QuickActionProtocol? getProtocol(String protocolTitle) {
    try {
      return QuickActionProtocol.protocols.firstWhere(
        (p) => p.title.toLowerCase() == protocolTitle.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get protocols for current category
  List<QuickActionProtocol> getCurrentCategoryProtocols() {
    return QuickActionProtocol.protocols
        .where((p) => p.category.toLowerCase().contains(_currentCategory.name))
        .toList();
  }

  /// Search knowledge base (simulated RAG)
  /// In production, this would query a vector database with medical protocols
  Future<List<String>> searchKnowledge(String query) async {
    // Simulated RAG: In production, this would use vector embeddings
    // and search through WHO, Red Cross, and medical protocol databases
    
    final results = <String>[];
    
    // Example knowledge snippets (in production, these would be in a vector DB)
    final knowledgeBase = _getKnowledgeBase();
    
    // Simple keyword matching (in production: semantic search with embeddings)
    final queryLower = query.toLowerCase();
    for (final entry in knowledgeBase) {
      if (entry.keywords.any((k) => queryLower.contains(k.toLowerCase()))) {
        results.add(entry.content);
      }
    }
    
    return results.take(3).toList(); // Return top 3 results
  }

  /// Get knowledge base entries
  List<KnowledgeEntry> _getKnowledgeBase() {
    return [
      KnowledgeEntry(
        keywords: ['cpr', 'cardiac', 'heart attack', 'chest compression'],
        content: 'CPR Protocol: Call 911. Place heel of hand on center of chest. Push hard and fast at 100-120 compressions per minute, 2 inches deep for adults. After 30 compressions, give 2 rescue breaths. Continue until help arrives.',
      ),
      KnowledgeEntry(
        keywords: ['bleeding', 'blood', 'hemorrhage', 'wound'],
        content: 'Severe Bleeding Control: Apply direct pressure with clean cloth. Press firmly for at least 10 minutes without peeking. If blood soaks through, add more cloth on top. Elevate injury above heart if possible. Call 911 for severe bleeding.',
      ),
      KnowledgeEntry(
        keywords: ['choking', 'airway', 'heimlich'],
        content: 'Choking Adult: Stand behind person. Give 5 back blows between shoulder blades. Then give 5 abdominal thrusts (Heimlich maneuver). Alternate until object clears or person becomes unconscious.',
      ),
      KnowledgeEntry(
        keywords: ['burn', 'fire', 'scald'],
        content: 'Burn Treatment: Remove from heat source. Cool burn with running water for 10-20 minutes. Remove jewelry before swelling. Cover with clean, dry cloth. Do NOT use ice, butter, or ointments. Call 911 for large burns or burns on face/hands.',
      ),
      KnowledgeEntry(
        keywords: ['shock', 'pale', 'cold', 'weak'],
        content: 'Shock Treatment: Have person lie down. Elevate legs 12 inches if no spinal injury. Keep warm with blanket. Do NOT give food or water. Monitor breathing. Call 911 immediately.',
      ),
      KnowledgeEntry(
        keywords: ['fracture', 'broken bone', 'break'],
        content: 'Fracture Management: Do NOT move person if spinal injury suspected. Immobilize injured area. Splint above and below injury. Apply ice (not directly on skin). Check circulation beyond injury. Call 911.',
      ),
      KnowledgeEntry(
        keywords: ['earthquake', 'tremor', 'seismic'],
        content: 'Earthquake Safety: DROP to hands and knees. COVER head under sturdy table. HOLD ON until shaking stops. Stay away from windows. If outdoors, move away from buildings.',
      ),
      KnowledgeEntry(
        keywords: ['hypothermia', 'cold', 'freezing'],
        content: 'Hypothermia Treatment: Move to warm location. Remove wet clothing. Warm center of body first (chest, neck, head). Use warm blankets. Give warm drinks if conscious. Do NOT rub limbs. Call 911.',
      ),
      KnowledgeEntry(
        keywords: ['heat stroke', 'heat exhaustion', 'hot'],
        content: 'Heat Stroke (Life-threatening): Move to shade. Cool person with water and ice packs on neck, armpits, groin. Call 911 immediately. Symptoms: body temp over 103°F, confusion, rapid pulse.',
      ),
      KnowledgeEntry(
        keywords: ['poison', 'toxic', 'overdose'],
        content: 'Poisoning: Call Poison Control (1-800-222-1222) or 911. Do NOT induce vomiting unless told. If skin/eye exposure, flush with water for 15 minutes. If inhaled, get to fresh air. Monitor breathing.',
      ),
    ];
  }
}

/// Emergency message in conversation
class EmergencyMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final EmergencyCategory category;

  EmergencyMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.category,
  });
}

/// Knowledge base entry for RAG simulation
class KnowledgeEntry {
  final List<String> keywords;
  final String content;

  KnowledgeEntry({
    required this.keywords,
    required this.content,
  });
}

/// Emergency assessment helper
class EmergencyAssessment {
  /// Assess urgency level from user query
  static EmergencyUrgency assessUrgency(String query) {
    final lowerQuery = query.toLowerCase();
    
    // Critical keywords
    final critical = ['unconscious', 'not breathing', 'severe bleeding', 
                     'chest pain', 'heart attack', 'stroke', 'seizure'];
    if (critical.any((k) => lowerQuery.contains(k))) {
      return EmergencyUrgency.critical;
    }
    
    // High urgency keywords
    final high = ['bleeding', 'broken', 'burn', 'choking', 'pain'];
    if (high.any((k) => lowerQuery.contains(k))) {
      return EmergencyUrgency.high;
    }
    
    // Medium urgency
    final medium = ['cut', 'sprain', 'bite', 'sting', 'rash'];
    if (medium.any((k) => lowerQuery.contains(k))) {
      return EmergencyUrgency.medium;
    }
    
    return EmergencyUrgency.low;
  }
}

enum EmergencyUrgency {
  critical('CALL 911 NOW'),
  high('Immediate Action Required'),
  medium('Prompt Care Needed'),
  low('Non-Emergency');

  final String message;
  const EmergencyUrgency(this.message);
}
