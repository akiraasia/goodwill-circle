import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'virtue_models.dart';
import 'virtue_hub_repository.dart';

class VirtueMaterialsTab extends ConsumerStatefulWidget {
  final String virtue;
  final Color accentColor;

  const VirtueMaterialsTab({
    Key? key,
    required this.virtue,
    required this.accentColor,
  }) : super(key: key);

  @override
  ConsumerState<VirtueMaterialsTab> createState() => _VirtueMaterialsTabState();
}

class _VirtueMaterialsTabState extends ConsumerState<VirtueMaterialsTab> {
  @override
  Widget build(BuildContext context) {
    final materialsAsync =
        ref.watch(virtueMaterialsProvider(widget.virtue));

    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        onPressed: () => _showPostDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Share Material', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: materialsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.red)),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.red))),
        data: (materials) {
          if (materials.isEmpty) {
            return _EmptyMaterialsState(
              virtue: widget.virtue,
              accentColor: widget.accentColor,
              onPost: () => _showPostDialog(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: materials.length,
            itemBuilder: (ctx, i) => _MaterialCard(
              material: materials[i],
              accentColor: widget.accentColor,
            ),
          );
        },
      ),
    );
  }

  void _showPostDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PostMaterialSheet(
        virtue: widget.virtue,
        accentColor: widget.accentColor,
        onPosted: () => ref.invalidate(virtueMaterialsProvider(widget.virtue)),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final VirtueMaterial material;
  final Color accentColor;

  static const _typeIcons = {
    'meme': Icons.insert_emoticon,
    'book': Icons.menu_book,
    'song': Icons.music_note,
    'video': Icons.play_circle_outline,
    'article': Icons.article_outlined,
  };

  const _MaterialCard({required this.material, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcons[material.materialType] ?? Icons.link;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.tan1, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (material.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                material.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.redPale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: AppColors.red, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            material.materialType.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.thumb_up_outlined, color: AppColors.textLight, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${material.upvotes}',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  material.title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (material.description != null && material.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    material.description!,
                    style: const TextStyle(color: AppColors.textMid, fontSize: 13, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'by ${material.posterName}',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                    const Spacer(),
                    if (material.url != null)
                      TextButton.icon(
                        onPressed: () async {
                          final uri = Uri.tryParse(material.url!);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Open'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.red,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostMaterialSheet extends StatefulWidget {
  final String virtue;
  final Color accentColor;
  final VoidCallback onPosted;

  const _PostMaterialSheet({
    required this.virtue,
    required this.accentColor,
    required this.onPosted,
  });

  @override
  State<_PostMaterialSheet> createState() => _PostMaterialSheetState();
}

class _PostMaterialSheetState extends State<_PostMaterialSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedType = 'book';
  bool _isPosting = false;

  static const _types = ['meme', 'book', 'song', 'video', 'article'];
  static const _typeIcons = {
    'meme': Icons.insert_emoticon,
    'book': Icons.menu_book,
    'song': Icons.music_note,
    'video': Icons.play_circle_outline,
    'article': Icons.article_outlined,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isPosting = true);

    final client = Supabase.instance.client;
    final repo = VirtueHubRepository(client);
    final posterName =
        client.auth.currentUser?.userMetadata?['name'] as String? ??
            'Anonymous';

    try {
      await repo.postMaterial(
        virtueName: widget.virtue,
        materialType: _selectedType,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        url: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        posterName: posterName,
      );
      widget.onPosted();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Share to ${widget.virtue} Board',
                style: const TextStyle(
                  color: AppColors.red,
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textMid),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = _types[i];
                final selected = t == _selectedType;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.red : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.red : AppColors.tan1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_typeIcons[t],
                            size: 14,
                            color: selected ? AppColors.white : AppColors.textMid),
                        const SizedBox(width: 4),
                        Text(
                          t[0].toUpperCase() + t.substring(1),
                          style: TextStyle(
                            color: selected ? AppColors.white : AppColors.textMid,
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.textDark),
            decoration: const InputDecoration(hintText: 'Title *'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descController,
            style: const TextStyle(color: AppColors.textDark),
            decoration: const InputDecoration(hintText: 'Description (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppColors.textDark),
            decoration: const InputDecoration(hintText: 'Link / URL (optional)'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _post,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: _isPosting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : const Text('Post to Board', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMaterialsState extends StatelessWidget {
  final String virtue;
  final Color accentColor;
  final VoidCallback onPost;

  const _EmptyMaterialsState({
    required this.virtue,
    required this.accentColor,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark_outlined,
                color: AppColors.red.withValues(alpha: 0.5), size: 64),
            const SizedBox(height: 20),
            Text(
              'Nothing shared yet for $virtue',
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Found an inspiring book, meme, or song? Be the first to share it with the community!',
              style: TextStyle(color: AppColors.textMid, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPost,
              icon: const Icon(Icons.add),
              label: const Text('Share Something'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
