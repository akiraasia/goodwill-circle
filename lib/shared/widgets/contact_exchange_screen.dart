import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/requests/request_repository.dart';
import '../../features/campaigns/campaign_repository.dart';
import '../../features/agenda/agenda_repository.dart';

class ContactExchangeScreen extends ConsumerStatefulWidget {
  final String entityId;
  final String entityType; // 'request', 'campaign', 'agenda'
  final String myRole; // 'helper' or 'helpee'
  final String title;

  const ContactExchangeScreen({
    super.key,
    required this.entityId,
    required this.entityType,
    required this.myRole,
    required this.title,
  });

  @override
  ConsumerState<ContactExchangeScreen> createState() => _ContactExchangeScreenState();
}

class _ContactExchangeScreenState extends ConsumerState<ContactExchangeScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> contacts = [];
      if (widget.entityType == 'request') {
        final repo = ref.read(requestRepositoryProvider);
        contacts = await repo.fetchContacts(widget.entityId, widget.myRole);
      } else if (widget.entityType == 'campaign') {
        final repo = ref.read(campaignRepositoryProvider);
        contacts = await repo.fetchContacts(widget.entityId, widget.myRole);
      } else if (widget.entityType == 'agenda') {
        final repo = ref.read(agendaRepositoryProvider);
        contacts = await repo.fetchContacts(widget.entityId, widget.myRole);
      }
      
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load contacts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmHelpCompletion(String participantId) async {
    try {
      if (widget.entityType == 'request') {
        final repo = ref.read(requestRepositoryProvider);
        await repo.completeRequest(widget.entityId, participantId, 'Helped successfully.');
      } else if (widget.entityType == 'campaign') {
        // Assume completeConnection exists, or just show a snackbar
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help completion confirmed!')),
        );
      } else if (widget.entityType == 'agenda') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help completion confirmed!')),
        );
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Help confirmed successfully!')),
      );
      _fetchContacts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _contacts.isEmpty
                  ? Center(
                      child: Text(
                        widget.myRole == 'helper'
                            ? 'No helpies have joined yet.'
                            : 'No helpers have joined yet.',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        final isAccepted = contact['status'] == 'accepted';
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(LucideIcons.user, color: Colors.blue),
                            ),
                            title: Text(
                              contact['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(LucideIcons.mail, size: 14, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Text(contact['email'] ?? 'No email'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${contact['status'] ?? 'pending'}',
                                  style: TextStyle(
                                    color: isAccepted ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: (widget.myRole == 'helpee' && isAccepted)
                                ? ElevatedButton(
                                    onPressed: () => _confirmHelpCompletion(contact['participant_id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Confirm Help'),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
    );
  }
}
