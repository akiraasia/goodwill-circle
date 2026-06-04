import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/campaigns/campaign_controller.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final goal = int.tryParse(_goalController.text) ?? 0;

      final controller = ref.read(campaignControllerProvider.notifier);
      await controller.createCampaign(
        title: title,
        description: description,
        goalAmount: goal,
        endDate: _selectedDate,
      );

      final state = ref.read(campaignControllerProvider);
      if (state.error == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign started successfully!')),
          );
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
    final state = ref.watch(campaignControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Start a Campaign')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Campaign Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter a title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description & Impact',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Describe your campaign'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _goalController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Amount (Goodwill Credits)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a goal amount';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: Text(
                        _selectedDate == null
                            ? 'Select End Date (Optional)'
                            : 'Ends on: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Launch Campaign'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
