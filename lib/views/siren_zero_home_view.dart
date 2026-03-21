import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/model_service.dart';
import '../services/emergency_prompts.dart';
import '../theme/app_theme.dart';
import 'emergency_chat_view.dart';
import 'emergency_voice_view.dart';
import 'protocol_library_view.dart';

/// Siren-Zero Main Screen
/// Emergency-first UI for rapid access to life-saving guidance
class SirenZeroHomeView extends StatefulWidget {
  const SirenZeroHomeView({super.key});

  @override
  State<SirenZeroHomeView> createState() => _SirenZeroHomeViewState();
}

class _SirenZeroHomeViewState extends State<SirenZeroHomeView> {
  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    final modelService = Provider.of<ModelService>(context, listen: false);
    // Auto-load models if they're downloaded but not loaded
    final isDownloaded = await modelService.isModelDownloaded(ModelService.llmModelId);
    if (!modelService.isLLMLoaded && isDownloaded) {
      await modelService.downloadAndLoadLLM();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildOfflineStatus(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickEmergencyButtons(),
                      const SizedBox(height: 24),
                      _buildEmergencyCategoryGrid(),
                      const SizedBox(height: 24),
                      _buildToolsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.emergencyGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIREN-ZERO',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Offline Emergency Co-Pilot',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.emergencyRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.emergencyRed.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.emergencyRed,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Always call emergency services when available (911)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineStatus() {
    return Consumer<ModelService>(
      builder: (context, modelService, child) {
        final isReady = modelService.isLLMLoaded;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isReady 
                ? AppColors.safeGreen.withOpacity(0.1)
                : AppColors.warningYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isReady ? AppColors.safeGreen : AppColors.warningYellow,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isReady ? Icons.check_circle : Icons.download,
                color: isReady ? AppColors.safeGreen : AppColors.warningYellow,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReady ? '100% OFFLINE READY' : 'SETUP REQUIRED',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isReady ? AppColors.safeGreen : AppColors.warningYellow,
                      ),
                    ),
                    Text(
                      isReady 
                          ? 'All AI models loaded. No internet required.'
                          : 'Download AI models to enable offline guidance.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!isReady)
                TextButton(
                  onPressed: () => _showModelSetup(),
                  child: const Text('SETUP'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickEmergencyButtons() {
    final quickActions = [
      _QuickAction('CPR', Icons.favorite, EmergencyCategory.cardiac),
      _QuickAction('BLEEDING', Icons.bloodtype, EmergencyCategory.bleeding),
      _QuickAction('CHOKING', Icons.air, EmergencyCategory.breathing),
      _QuickAction('BURN', Icons.local_fire_department, EmergencyCategory.burns),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CRITICAL EMERGENCIES',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.emergencyRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            final action = quickActions[index];
            return _buildQuickActionButton(action);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(_QuickAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleQuickAction(action.category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.emergencyGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.emergencyRed.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                action.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCategoryGrid() {
    final categories = EmergencyCategory.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EMERGENCY CATEGORIES',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(categories[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(EmergencyCategory category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleQuickAction(category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textMuted.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                category.title.toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                category.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOOLS',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildToolCard(
          'Voice Assistant',
          'Hands-free emergency guidance',
          Icons.mic,
          AppColors.infoBlue,
          () => _navigateToVoiceAssistant(),
        ),
        const SizedBox(height: 12),
        _buildToolCard(
          'Protocol Library',
          'Step-by-step emergency procedures',
          Icons.library_books,
          AppColors.alertOrange,
          () => _navigateToProtocolLibrary(),
        ),
      ],
    );
  }

  Widget _buildToolCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleQuickAction(EmergencyCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyChatView(initialCategory: category),
      ),
    );
  }

  void _navigateToVoiceAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyVoiceView(),
      ),
    );
  }

  void _navigateToProtocolLibrary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProtocolLibraryView(),
      ),
    );
  }

  void _showModelSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModelSetupSheet(),
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  final EmergencyCategory category;

  _QuickAction(this.title, this.icon, this.category);
}

/// Model setup bottom sheet
class ModelSetupSheet extends StatelessWidget {
  const ModelSetupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Required',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Download AI models to enable offline emergency guidance. This only needs to be done once.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ModelService>(
              builder: (context, modelService, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildModelItem(
                        context,
                        'Language Model (LLM)',
                        'SmolLM2 for emergency guidance',
                        '~400MB',
                        false, // Will check async
                        modelService.isLLMLoaded,
                        modelService.isLLMDownloading ? modelService.llmDownloadProgress : null,
                        () => modelService.downloadAndLoadLLM(),
                      ),
                      const SizedBox(height: 12),
                      _buildModelItem(
                        context,
                        'Speech-to-Text (STT)',
                        'Whisper Tiny for voice input',
                        '~80MB',
                        false, // Will check async
                        modelService.isSTTLoaded,
                        modelService.isSTTDownloading ? modelService.sttDownloadProgress : null,
                        () => modelService.downloadAndLoadSTT(),
                      ),
                      const SizedBox(height: 12),
                      _buildModelItem(
                        context,
                        'Text-to-Speech (TTS)',
                        'Piper TTS for voice output',
                        '~100MB',
                        false, // Will check async
                        modelService.isTTSLoaded,
                        modelService.isTTSDownloading ? modelService.ttsDownloadProgress : null,
                        () => modelService.downloadAndLoadTTS(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelItem(
    BuildContext context,
    String title,
    String subtitle,
    String size,
    bool isDownloaded,
    bool isLoaded,
    double? progress,
    VoidCallback onDownload,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$subtitle • $size',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isLoaded)
                const Icon(Icons.check_circle, color: AppColors.safeGreen)
              else if (progress != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                  ),
                )
              else
                IconButton(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
