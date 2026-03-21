import 'package:flutter/material.dart';
import '../services/emergency_prompts.dart';
import '../theme/app_theme.dart';

/// Protocol Library View
/// Browse and view step-by-step emergency procedures
class ProtocolLibraryView extends StatelessWidget {
  const ProtocolLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Protocols'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: QuickActionProtocol.protocols.length,
        itemBuilder: (context, index) {
          final protocol = QuickActionProtocol.protocols[index];
          return _buildProtocolCard(context, protocol);
        },
      ),
    );
  }

  Widget _buildProtocolCard(BuildContext context, QuickActionProtocol protocol) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showProtocolDetail(context, protocol),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  protocol.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      protocol.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showProtocolDetail(BuildContext context, QuickActionProtocol protocol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProtocolDetailSheet(protocol: protocol),
    );
  }
}

/// Protocol detail bottom sheet
class ProtocolDetailSheet extends StatelessWidget {
  final QuickActionProtocol protocol;

  const ProtocolDetailSheet({super.key, required this.protocol});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.emergencyGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(
                  protocol.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        protocol.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        protocol.category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Warning message
          if (protocol.warningMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warningYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warningYellow,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.warningYellow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      protocol.warningMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Steps
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: protocol.steps.length,
              itemBuilder: (context, index) {
                return _buildStep(context, index + 1, protocol.steps[index]);
              },
            ),
          ),

          // Emergency call button
          Container(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: () {
                // In a real app, this would call emergency services
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('In emergency: Call 911 or local emergency number'),
                  ),
                );
              },
              icon: const Icon(Icons.phone),
              label: const Text('CALL EMERGENCY SERVICES'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.emergencyRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int number, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.emergencyGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
