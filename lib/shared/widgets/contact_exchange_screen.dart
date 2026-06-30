import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.myRole == 'helper' ? Icons.people_outline : Icons.handshake_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.myRole == 'helper'
                                ? 'No helpies have joined yet.'
                                : 'No helpers have joined yet.',
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Share this ${widget.entityType} to get more connections!',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        final isAccepted = contact['status'] == 'accepted';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: const Icon(Icons.person, color: Colors.blue),
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
                                    const Icon(Icons.mail, size: 14, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        contact['email'] ?? 'No email',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isAccepted 
                                            ? Colors.green.shade50 
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Status: ${contact['status'] ?? 'pending'}',
                                        style: TextStyle(
                                          color: isAccepted ? Colors.green.shade700 : Colors.orange.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (contact['join_type'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          contact['join_type'] == 'multiple' ? '👥 Group' : '👤 Individual',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
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
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    child: const Text('Confirm Help', style: TextStyle(fontSize: 12)),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () {
                                      final email = contact['email'] as String?;
                                      if (email != null && email.isNotEmpty) {
                                        Clipboard.setData(ClipboardData(text: email));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Copied email: $email')),
                                        );
                                      }
                                    },
                                    tooltip: 'Show email',
                                  ),
                          ),
                        );
                      },
                    ),
    );
  }
}
