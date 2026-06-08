import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goodwill_circle/features/requests/request_controller.dart';
import 'package:goodwill_circle/features/trust/trust_repository.dart';
import 'package:goodwill_circle/shared/services/media_upload_service.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _financialVerificationController = TextEditingController();
  String _selectedCategory = 'Other';
  String _selectedUrgency = 'normal';
  String? _imageUrl;
  bool _isUploadingImage = false;

  final List<String> _categories = [
    'Education',
    'Career',
    'Food',
    'Medical',
    'Finance',
    'Housing',
    'Emotional Support',
    'Other',
  ];

  final Map<String, int> _urgencyRewards = const {
    'low': 5,
    'normal': 10,
    'urgent': 25,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _financialVerificationController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final reward = _urgencyRewards[_selectedUrgency] ?? 10;
      final isFinancialHelp = _selectedCategory == 'Finance';
      final financialNote = _financialVerificationController.text.trim();

      if (isFinancialHelp && financialNote.length < 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add verification details for financial help.'),
          ),
        );
        return;
      }

      final controller = ref.read(requestControllerProvider.notifier);
      final requestId = await controller.createRequest(
        title: title,
        description: description,
        category: _selectedCategory,
        reward: reward,
        imageUrl: _imageUrl,
      );

      final state = ref.read(requestControllerProvider);
      if (state.error == null && requestId != null) {
        var financialVerificationQueued = false;
        if (isFinancialHelp) {
          try {
            await ref
                .read(trustRepositoryProvider)
                .submitFinancialHelpVerification(
                  requestId: requestId,
                  note: financialNote,
                  evidenceUrl: _imageUrl,
                );
            financialVerificationQueued = true;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Financial review could not be queued: $e'),
                ),
              );
            }
          }
        }

        if (mounted) {
          if (isFinancialHelp) {
            context.go('/trust');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  financialVerificationQueued
                      ? 'Request posted and sent for financial review.'
                      : 'Request posted. Review your trust settings here.',
                ),
              ),
            );
          } else {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request created successfully!')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ask for help')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      'Be specific. Be honest. Someone here probably understands.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'What do you need help with?',
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter a title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Tell the story',
                        hintText:
                            'Context, what you have tried, and what would actually help.',
                      ),
                      maxLines: 6,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter a description'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isUploadingImage
                          ? null
                          : () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(
                                context,
                              );
                              setState(() => _isUploadingImage = true);
                              try {
                                final url =
                                    await MediaUploadService.pickAndUploadImage(
                                      folder: 'requests',
                                    );
                                if (mounted && url != null) {
                                  setState(() => _imageUrl = url);
                                }
                              } catch (e) {
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Image upload failed: $e'),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isUploadingImage = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(
                        _isUploadingImage
                            ? 'Uploading...'
                            : _imageUrl == null
                            ? 'Add photo'
                            : 'Change photo',
                      ),
                    ),
                    if (_imageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(_imageUrl!, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                    if (_selectedCategory == 'Finance') ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Financial help review',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add enough context for moderators to verify the need. If you attach a photo, it will also enter the media authenticity queue.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _financialVerificationController,
                                decoration: const InputDecoration(
                                  labelText: 'Verification details',
                                  hintText:
                                      'What is the expense, amount, and what proof can reviewers check?',
                                ),
                                minLines: 3,
                                maxLines: 5,
                                validator: (_) {
                                  if (_selectedCategory != 'Finance') {
                                    return null;
                                  }
                                  return _financialVerificationController.text
                                              .trim()
                                              .length <
                                          20
                                      ? 'Add clear verification details'
                                      : null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUrgency,
                      decoration: const InputDecoration(labelText: 'Urgency'),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Text('Low - whenever'),
                        ),
                        DropdownMenuItem(
                          value: 'normal',
                          child: Text('Normal - 10 credits'),
                        ),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Text('Urgent - 25 credits'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedUrgency = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This request offers ${_urgencyRewards[_selectedUrgency]} goodwill credits.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Post my request'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
