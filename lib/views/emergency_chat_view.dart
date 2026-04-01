import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/model_service.dart';
import '../services/emergency_response_service.dart';
import '../services/emergency_prompts.dart';
import '../theme/app_theme.dart';
import '../widgets/audio_visualizer.dart';

/// Emergency Chat View
/// Premium text-based emergency guidance with multimodal input

class EmergencyChatView extends StatefulWidget {
  final EmergencyCategory initialCategory;

  const EmergencyChatView({
    super.key,
    this.initialCategory = EmergencyCategory.general,
  });

  @override
  State<EmergencyChatView> createState() => _EmergencyChatViewState();
}

class _EmergencyChatViewState extends State<EmergencyChatView> {
  late EmergencyResponseService _emergencyService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isStreaming = false;
  String _streamingText = '';

  // Manual Voice Mode State
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isVoiceMode = false;
  bool _isRecording = false;
  bool _isProcessingVoice = false;
  bool _lastQueryWasVoice = false;
  double _audioLevel = 0.0;
  String _voiceStatus = '';
  List<int> _audioBuffer = [];
  StreamSubscription<Uint8List>? _recordingSubscription;
  Timer? _levelTimer;

  @override
  void initState() {
    super.initState();
    _emergencyService = EmergencyResponseService();
    _emergencyService.setCategory(widget.initialCategory);
  }

  @override
  void dispose() {
    _recordingSubscription?.cancel();
    _levelTimer?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _emergencyService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (!_lastQueryWasVoice) {
      _textController.clear();
    } else {
      _textController.clear();
    }

    // 🔥 SHOW USER MESSAGE
    setState(() {
      _emergencyService.conversationHistory.add(
        EmergencyMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
          category: widget.initialCategory,
        ),
      );
    });

    _scrollToBottom();

    // AI response
    setState(() {
      _isStreaming = true;
      _streamingText = '';
    });
    
    String generatedOutput = "";

    try {
      await for (final token in _emergencyService.streamEmergencyResponse(text)) {
        if (!mounted) return;
        setState(() {
          _streamingText += token;
          generatedOutput = _streamingText;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStreaming = false;
          _streamingText = '';
        });
        if (_lastQueryWasVoice && generatedOutput.isNotEmpty) {
           _synthesizeAndPlay(generatedOutput);
           _lastQueryWasVoice = false;
        }
        _scrollToBottom();
      }
    }
  }

  void _handleImageInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image input coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleVoiceInput() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final modelService = Provider.of<ModelService>(context, listen: false);
    if (!modelService.isVoiceAgentReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading voice models... please wait.')),
      );
      if (!modelService.isSTTLoaded) await modelService.downloadAndLoadSTT();
      if (!modelService.isLLMLoaded) await modelService.downloadAndLoadLLM();
      if (!modelService.isTTSLoaded) await modelService.downloadAndLoadTTS();
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    await _audioPlayer.stop();

    setState(() {
      _isVoiceMode = true;
      _isRecording = true;
      _isProcessingVoice = false;
      _lastQueryWasVoice = true;
      _audioBuffer = [];
      _voiceStatus = 'Listening...';
    });

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _recordingSubscription = stream.listen((data) {
      _audioBuffer.addAll(data);
    });

    _levelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final amplitude = await _recorder.getAmplitude();
      if (mounted) {
        setState(() {
          final dB = amplitude.current;
          _audioLevel = ((dB + 60) / 60).clamp(0.0, 1.0);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordingSubscription?.cancel();
    _levelTimer?.cancel();
    await _recorder.stop();

    setState(() {
      _isRecording = false;
      _audioLevel = 0.0;
      _voiceStatus = 'Processing...';
      _isProcessingVoice = true;
    });

    try {
      final audioData = Uint8List.fromList(_audioBuffer);
      if (audioData.length > 1600) {
        String text = await RunAnywhere.transcribe(audioData);
        text = text.trim();

        // 🛑 Filter out Whisper hallucination loops on silence
        text = text.replaceAll(RegExp(r'(Hello\.\s*){3,}'), 'Hello.');
        text = text.replaceAll(RegExp(r'(Thank you\.\s*){3,}'), '');
        final cleanedForCheck = text.replaceAll('.', '').replaceAll(' ', '').toLowerCase();
        if (cleanedForCheck == 'hello' || cleanedForCheck == 'thankyou') {
           text = ''; // Ignore short dead-air hallucinations
        }

        if (mounted) {
          setState(() {
            _isProcessingVoice = false;
            _isVoiceMode = false;
          });
          if (text.isNotEmpty && text.length > 2) {
             _textController.text = text;
             _sendMessage();
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not hear you clearly. Please try again.'))
             );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessingVoice = false;
            _isVoiceMode = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Recording too short.'))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingVoice = false;
          _isVoiceMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'))
        );
      }
    }
  }

  Future<void> _synthesizeAndPlay(String text) async {
    if (text.isEmpty) return;
    try {
      // Clean up markdown hashes and stars for the voice synthesizer
      String cleanText = text.replaceAll('*', '').replaceAll('#', '').replaceAll('\n', ' ');
      
      // Split into sentences so Kokoro TTS doesn't timeout/fail on huge text blocks
      final chunks = cleanText.split(RegExp(r'(?<=[.!?])\s+'));
      
      for (int i = 0; i < chunks.length; i++) {
         final chunk = chunks[i].trim();
         if (chunk.isEmpty) continue;
         
         // In an emergency, we don't want a 2-minute voice monolog. Max 3 sentences spoken.
         if (i >= 3) break;

         final result = await RunAnywhere.synthesize(chunk, rate: 1.0);
         final wavData = _createWavFromFloat32(result.samples, result.sampleRate);
         final tempDir = await getTemporaryDirectory();
         final tempFile = File('${tempDir.path}/tts_chunk_${i}_${DateTime.now().millisecondsSinceEpoch}.wav');
         await tempFile.writeAsBytes(wavData);
         
         await _audioPlayer.play(DeviceFileSource(tempFile.path));
         
         // Crucial: Wait until audio is completely done before synthesizing/playing next
         await _audioPlayer.onPlayerComplete.first;
      }
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  Uint8List _createWavFromFloat32(Float32List samples, int sampleRate) {
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = samples.length * 2;
    final fileSize = 36 + dataSize;

    final buffer = BytesBuilder();
    buffer.add('RIFF'.codeUnits);
    buffer.add(_int32ToBytes(fileSize));
    buffer.add('WAVE'.codeUnits);

    buffer.add('fmt '.codeUnits);
    buffer.add(_int32ToBytes(16));
    buffer.add(_int16ToBytes(1));
    buffer.add(_int16ToBytes(numChannels));
    buffer.add(_int32ToBytes(sampleRate));
    buffer.add(_int32ToBytes(byteRate));
    buffer.add(_int16ToBytes(blockAlign));
    buffer.add(_int16ToBytes(bitsPerSample));

    buffer.add('data'.codeUnits);
    buffer.add(_int32ToBytes(dataSize));

    for (final sample in samples) {
      final int16Sample = (sample * 32767).clamp(-32768, 32767).toInt();
      buffer.add(_int16ToBytes(int16Sample));
    }
    return buffer.toBytes();
  }

  List<int> _int32ToBytes(int value) => [value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF];
  List<int> _int16ToBytes(int value) => [value & 0xFF, (value >> 8) & 0xFF];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.primaryBg
          : AppColors.lightBg,
      resizeToAvoidBottomInset: true,

      // 🔥 DOPED APPBAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF0F172A).withOpacity(0.85)
                    : Colors.white.withOpacity(0.85),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.lightTextPrimary,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2D55), Color(0xFFE6003B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2D55).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Siren Zero AI',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.lightTextPrimary,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                  ),
                  Text(
                    'Emergency Assistant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF2D55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: _emergencyService.conversationHistory.isEmpty &&
                    !_isStreaming
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _emergencyService.conversationHistory.length +
                        (_isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isStreaming &&
                          index ==
                              _emergencyService.conversationHistory.length) {
                        return _buildMessageBubble(
                          _streamingText,
                          false,
                          isStreaming: true,
                        );
                      }

                      final message =
                          _emergencyService.conversationHistory[index];

                      return _buildMessageBubble(
                        message.text,
                        message.isUser,
                      );
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 💎 PREMIUM ICON BOX
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2D55), Color(0xFFE6003B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2D55).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: -5,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 32),

          // 💎 PREMIUM TITLE
          Text(
            'Start a Conversation',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.lightTextPrimary,
                ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1),

          const SizedBox(height: 12),

          // SUBTEXT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ask me anything about emergency procedures, first aid, or medical guidance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : AppColors.lightTextSecondary,
                    height: 1.5,
                    fontSize: 15,
                  ),
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.1),

          const SizedBox(height: 48),

          // 🔥 PREMIUM CASCADING CHIPS
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuickPrompt('How to perform CPR?', Icons.favorite, 0),
              const SizedBox(height: 12),
              _buildQuickPrompt('Treating burns immediately', Icons.local_fire_department, 1),
              const SizedBox(height: 12),
              _buildQuickPrompt('Stop severe bleeding', Icons.bloodtype, 2),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildQuickPrompt(String text, IconData icon, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _textController.text = text;
          _sendMessage();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B).withOpacity(0.6)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF38BDF8).withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF38BDF8).withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.emergencyRed),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.lightTextPrimary,
                      ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.black26),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (400 + (index * 100)).ms, duration: 500.ms).slideX(begin: 0.05);
  }

  Widget _buildMessageBubble(String text, bool isUser,
      {bool isStreaming = false}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2D55), Color(0xFFE6003B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2D55).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
            ).animate().scale(delay: 200.ms, duration: 300.ms, curve: Curves.easeOutBack),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)], // User gets nice blue
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser
                    ? null
                    : (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B).withOpacity(0.8) // Glassmorphic AI bubble
                        : Colors.white.withOpacity(0.95)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        width: 1.5,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF38BDF8).withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: isUser ? 0 : 10, sigmaY: isUser ? 0 : 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (text.isEmpty && isStreaming)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFF2D55),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Thinking...',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.white70 : AppColors.lightTextMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                               .fade(begin: 0.4, end: 1.0, duration: 600.ms),
                            ],
                          ),
                        )
                      else
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: text,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isUser
                                          ? Colors.white
                                          : (Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.95)
                                              : AppColors.lightTextPrimary),
                                      height: 1.5,
                                      fontSize: 14,
                                    ),
                              ),
                              if (isStreaming && !isUser)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    width: 6,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF2D55),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                                   .fade(begin: 0.2, end: 1.0, duration: 400.ms),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                )
              ),
              child: Icon(Icons.person_rounded, 
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 : Colors.black54, 
                  size: 14),
          ).animate().scale(delay: 100.ms, duration: 250.ms, curve: Curves.easeOutBack),
          ]
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F172A).withOpacity(0.7)
                : Colors.white.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF38BDF8).withOpacity(0.15)
                    : Colors.black.withOpacity(0.06),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF38BDF8).withOpacity(0.05)
                    : Colors.transparent,
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            bottom: true,
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active Quick Replies during chat
                if (_emergencyService.conversationHistory.isNotEmpty)
                  _buildActiveQuickReplies(),
                  
                // Input Container
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B).withOpacity(0.7)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF38BDF8).withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Image Button
                      if (!_isVoiceMode)
                        _buildInputIconButton(
                          Icons.image_outlined,
                          const Color(0xFF38BDF8),
                          'Add Image',
                          _handleImageInput,
                        ),
                      if (!_isVoiceMode)
                        const SizedBox(width: 8),

                      // Voice Button
                      _buildInputIconButton(
                        _isRecording ? Icons.stop_rounded : Icons.mic_outlined,
                        _isRecording ? AppColors.emergencyRed : const Color(0xFFFF9500),
                        _isRecording ? 'Stop Voice' : 'Voice Input',
                        _handleVoiceInput,
                      ),
                      const SizedBox(width: 12),

                      // Text Field OR Voice Visualizer
                      if (_isVoiceMode || _isProcessingVoice)
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: _isProcessingVoice
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9500)),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Analyzing...',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: const Color(0xFFFF9500),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                               .fade(begin: 0.4, end: 1.0, duration: 600.ms),
                                            ],
                                          )
                                        : AudioVisualizer(
                                            level: _audioLevel,
                                            color: const Color(0xFFFF9500),
                                          ),
                                  ),
                                ),
                                if (!_isProcessingVoice) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _voiceStatus,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFFFF9500),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: 'Describe emergency...',
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white30
                                        : AppColors.lightTextMuted,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 12,
                              ),
                            ),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                                  fontSize: 15,
                                ),
                            maxLines: null,
                            minLines: 1,
                            enabled: !_isStreaming,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      const SizedBox(width: 8),

                      // Send Button
                      if (!_isVoiceMode)
                        _buildSendButton(),
                    ],
                  ),
                ),

                // Feature Pills
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeaturePill(Icons.offline_bolt_rounded, 'OFFLINE'),
                      const SizedBox(width: 8),
                      _buildFeaturePill(Icons.lock_outline_rounded, 'PRIVATE'),
                      const SizedBox(width: 8),
                      _buildFeaturePill(Icons.speed_rounded, '7ms LATENCY'),
                    ],
                  ),
                ),
              ],
            ), // closes Column
          ), // closes SafeArea
        ), // closes Container
      ), // closes BackdropFilter
    ); // closes ClipRRect
  }

  Widget _buildInputIconButton(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isStreaming ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isStreaming
                  ? AppColors.textMuted.withOpacity(0.05)
                  : color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isStreaming
                    ? AppColors.textMuted.withOpacity(0.1)
                    : color.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: _isStreaming
                  ? []
                  : [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              color: _isStreaming ? AppColors.textMuted : color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isStreaming ? null : _sendMessage,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: _isStreaming
                ? null
                : const LinearGradient(
                    colors: [Color(0xFFFF2D55), Color(0xFFE6003B)],
                  ),
            color: _isStreaming ? AppColors.textMuted.withOpacity(0.3) : null,
            shape: BoxShape.circle,
            boxShadow: _isStreaming
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFFFF2D55).withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Icon(
            _isStreaming ? Icons.stop_rounded : Icons.send_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3), width: 1.2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.05),
            blurRadius: 6,
          ),
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF38BDF8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveQuickReplies() {
    final defaultReplies = [
      'Call 911',
      'They are unconscious',
      'Not breathing',
      'It\'s getting worse',
      'Patient is bleeding',
    ];
    
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: defaultReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = defaultReplies[index];
          return ActionChip(
            label: Text(
              reply,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : AppColors.lightTextPrimary,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B).withOpacity(0.8)
                : Colors.white,
            side: BorderSide(
              color: AppColors.emergencyRed.withOpacity(0.3),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () {
              if (!_isStreaming) {
                _textController.text = reply;
                _sendMessage();
              }
            },
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.5);
  }
}
