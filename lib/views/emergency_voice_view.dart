import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';
import '../services/model_service.dart';
import '../services/emergency_prompts.dart';
import '../theme/app_theme.dart';

/// Emergency Voice Assistant View
/// Hands-free emergency guidance using VAD → STT → LLM → TTS pipeline
class EmergencyVoiceView extends StatefulWidget {
  const EmergencyVoiceView({super.key});

  @override
  State<EmergencyVoiceView> createState() => _EmergencyVoiceViewState();
}

class _EmergencyVoiceViewState extends State<EmergencyVoiceView> {
  VoiceSessionHandle? _session;
  List<_ConversationTurn> _conversation = [];
  double _audioLevel = 0.0;
  String _status = 'Tap to start voice assistant';
  bool _isActive = false;
  EmergencyCategory _category = EmergencyCategory.general;

  @override
  void dispose() {
    _session?.stop();
    super.dispose();
  }

  Future<void> _toggleSession() async {
    if (_session != null) {
      _session!.stop();
      setState(() {
        _session = null;
        _isActive = false;
        _status = 'Stopped';
      });
      return;
    }

    final modelService = Provider.of<ModelService>(context, listen: false);
    
    // Check if all models are ready
    if (!modelService.isVoiceAgentReady) {
      setState(() => _status = 'Loading models...');
      
      // Load all models
      if (!modelService.isSTTLoaded) {
        await modelService.downloadAndLoadSTT();
      }
      if (!modelService.isLLMLoaded) {
        await modelService.downloadAndLoadLLM();
      }
      if (!modelService.isTTSLoaded) {
        await modelService.downloadAndLoadTTS();
      }
    }

    // Start voice session
    try {
      _session = await RunAnywhere.startVoiceSession(
        config: VoiceSessionConfig(
          silenceDuration: 1.5,
          autoPlayTTS: true,
          continuousMode: true,
        ),
      );

      setState(() => _isActive = true);

      // Handle events
      _session!.events.listen((event) {
        if (!mounted) return;
        
        setState(() {
          switch (event) {
            case VoiceSessionListening(:final audioLevel):
              _audioLevel = audioLevel;
              _status = 'Listening... (speak now)';

            case VoiceSessionSpeechStarted():
              _status = 'Speech detected...';

            case VoiceSessionProcessing():
              _status = 'Processing...';

            case VoiceSessionTranscribed(:final text):
              _conversation.add(_ConversationTurn(text: text, isUser: true));
              _status = 'Generating response...';

            case VoiceSessionResponded(:final text):
              _conversation.add(_ConversationTurn(text: text, isUser: false));
              _status = 'Speaking response...';

            case VoiceSessionSpeaking():
              _status = 'Speaking...';

            case VoiceSessionTurnCompleted():
              _status = 'Listening...';

            case VoiceSessionError(:final message):
              _status = 'Error: $message';

            case VoiceSessionStopped():
              _status = 'Stopped';
              _isActive = false;
            
            default:
              break;
          }
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        actions: [
          PopupMenuButton<EmergencyCategory>(
            icon: const Icon(Icons.category),
            onSelected: (category) {
              setState(() => _category = category);
            },
            itemBuilder: (context) {
              return EmergencyCategory.values.map((category) {
                return PopupMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Text(category.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(category.title),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _conversation.length,
              itemBuilder: (context, index) {
                final turn = _conversation[index];
                return _buildMessageBubble(turn.text, turn.isUser);
              },
            ),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildCategoryBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.infoBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(_category.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _category.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Voice-guided emergency assistance',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.infoBlue
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.volume_up, size: 16, color: AppColors.infoBlue),
              ),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(
            color: AppColors.textMuted.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Audio level indicator
            if (_isActive)
              Container(
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(
                  value: _audioLevel.clamp(0.0, 1.0),
                  backgroundColor: AppColors.surfaceElevated,
                  color: AppColors.infoBlue,
                ),
              ),
            
            // Status text
            Text(
              _status,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Main control button
            GestureDetector(
              onTap: _toggleSession,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: _isActive
                      ? const LinearGradient(
                          colors: [AppColors.emergencyRed, Color(0xFFD50000)],
                        )
                      : const LinearGradient(
                          colors: [AppColors.infoBlue, Color(0xFF0091EA)],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isActive ? AppColors.emergencyRed : AppColors.infoBlue).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isActive ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isActive ? 'TAP TO STOP' : 'TAP TO START',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTurn {
  final String text;
  final bool isUser;

  _ConversationTurn({required this.text, required this.isUser});
}
