import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:goodwill_circle/core/theme/app_theme.dart';
import 'package:goodwill_circle/core/theme/app_typography.dart';
import 'package:goodwill_circle/features/confessions/confession_controller.dart';
import 'package:goodwill_circle/features/confessions/models/confession.dart';
import 'package:goodwill_circle/shared/services/media_upload_service.dart';
import 'package:goodwill_circle/shared/widgets/app_card.dart';
import 'package:goodwill_circle/shared/widgets/section_header.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConfessionsScreen extends ConsumerStatefulWidget {
  const ConfessionsScreen({super.key});

  @override
  ConsumerState<ConfessionsScreen> createState() => _ConfessionsScreenState();
}

class _ConfessionsScreenState extends ConsumerState<ConfessionsScreen> {
  final _contentController = TextEditingController();
  String? _imageUrl;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final url = await MediaUploadService.pickAndUploadImage(
        folder: 'confessions',
      );
      if (mounted && url != null) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    await ref
        .read(confessionControllerProvider.notifier)
        .createConfession(content: content, imageUrl: _imageUrl);
    final state = ref.read(confessionControllerProvider);
    if (!mounted) return;
    if (state.error == null) {
      _contentController.clear();
      setState(() => _imageUrl = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confession posted anonymously.')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(confessionControllerProvider);
    final controller = ref.read(confessionControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SectionHeader(
            title: 'Anonymous Confessions',
            actionLabel: 'Refresh',
            onActionTap: () => controller.loadConfessions(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.loadConfessions(),
              child: ListView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: 120,
                ),
                children: [
                  AppCard(
                    color: AppColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _contentController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Confess anonymously',
                            hintText:
                                'Say the thing you need to release. Your name is hidden.',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_imageUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isUploadingImage ? null : _pickImage,
                              icon: const Icon(Icons.photo_outlined),
                              label: Text(
                                _isUploadingImage
                                    ? 'Uploading...'
                                    : _imageUrl == null
                                    ? 'Add photo'
                                    : 'Change photo',
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: state.isLoading ? null : _submit,
                              child: const Text('Post'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (state.isLoading && state.confessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.error != null && state.confessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Center(child: Text('Error: ${state.error}')),
                    )
                  else if (state.confessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: Text('No confessions yet.')),
                    )
                  else
                    for (final confession in state.confessions)
                      _ConfessionCard(confession: confession),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfessionCard extends ConsumerWidget {
  final Confession confession;

  const _ConfessionCard({required this.confession});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.visibility_off_outlined)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Anonymous',
                  style: AppTypography.textTheme.labelLarge,
                ),
              ),
              Text(
                timeago.format(confession.createdAt),
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(confession.content, style: AppTypography.textTheme.bodyMedium),
          if (confession.imageUrl != null &&
              confession.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(confession.imageUrl!, fit: BoxFit.cover),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: confession.isSupported
                ? null
                : () => ref
                      .read(confessionControllerProvider.notifier)
                      .supportConfession(confession.id),
            icon: Icon(
              confession.isSupported
                  ? Icons.favorite
                  : Icons.favorite_border_outlined,
              size: 16,
            ),
            label: Text(
              confession.isSupported
                  ? '${confession.supportCount} supported'
                  : 'Support ${confession.supportCount}',
            ),
          ),
        ],
      ),
    );
  }
}
