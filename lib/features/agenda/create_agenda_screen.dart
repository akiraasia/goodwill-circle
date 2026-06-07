import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/agenda/agenda_controller.dart';

class CreateAgendaScreen extends ConsumerStatefulWidget {
  const CreateAgendaScreen({super.key});

  @override
  ConsumerState<CreateAgendaScreen> createState() => _CreateAgendaScreenState();
}

class _CreateAgendaScreenState extends ConsumerState<CreateAgendaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ngoNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _seatsController = TextEditingController(text: '1');
  final _certificateTitleController = TextEditingController(
    text: 'Community Mentor',
  );
  final _certificateIssuerController = TextEditingController();
  String _selectedSkillArea = 'Education';
  String _selectedBadgeId = 'mentor';

  final List<String> _skillAreas = const [
    'Education',
    'Career',
    'Digital Skills',
    'Health Awareness',
    'Language',
    'Arts',
    'Operations',
    'Other',
  ];

  final Map<String, String> _badges = const {
    'mentor': 'Mentor',
    'community_builder': 'Community Builder',
    'goodwill_ambassador': 'Goodwill Ambassador',
  };

  @override
  void dispose() {
    _ngoNameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _seatsController.dispose();
    _certificateTitleController.dispose();
    _certificateIssuerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(agendaControllerProvider.notifier);
    await controller.createAgendaItem(
      ngoName: _ngoNameController.text.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      skillArea: _selectedSkillArea,
      location: _locationController.text.trim(),
      seatsNeeded: int.tryParse(_seatsController.text.trim()) ?? 1,
      rewardBadgeId: _selectedBadgeId,
      certificateTitle: _certificateTitleController.text.trim(),
      certificateIssuer: _certificateIssuerController.text.trim(),
    );

    final state = ref.read(agendaControllerProvider);
    if (state.error == null) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agenda item created successfully!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agendaControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add NGO agenda')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      'Create a nonprofit opportunity with a clear outcome, badge, and certificate.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _ngoNameController,
                      decoration: const InputDecoration(labelText: 'NGO name'),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Agenda title',
                        hintText: 'Need a teacher for weekend math classes',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'What help is needed?',
                        hintText:
                            'Who will be helped, expected commitment, and success criteria.',
                      ),
                      maxLines: 6,
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSkillArea,
                      decoration: const InputDecoration(labelText: 'Skill area'),
                      items: _skillAreas
                          .map(
                            (area) => DropdownMenuItem(
                              value: area,
                              child: Text(area),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSkillArea = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location or online link',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seatsController,
                      decoration: const InputDecoration(
                        labelText: 'People needed',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final seats = int.tryParse(value ?? '');
                        if (seats == null || seats < 1) {
                          return 'Enter at least 1 person';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBadgeId,
                      decoration: const InputDecoration(labelText: 'Badge'),
                      items: _badges.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedBadgeId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _certificateTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Certificate title',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _certificateIssuerController,
                      decoration: const InputDecoration(
                        labelText: 'Certificate issuer',
                        hintText: 'Name of NGO issuing it',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Post agenda'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }
}
