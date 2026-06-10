import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guardme_app/domain/entities/contact.dart';
import 'package:guardme_app/presentation/providers/contact_provider.dart';
import 'package:guardme_app/presentation/widgets/my_button.dart';
import 'package:guardme_app/presentation/widgets/my_text_field.dart';

class ContactListPage extends ConsumerStatefulWidget {
  const ContactListPage({super.key});

  @override
  ConsumerState<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends ConsumerState<ContactListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(contactProvider.notifier).loadContacts());
  }

  void _showAddEditDialog({Contact? contact}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final emailController = TextEditingController(text: contact?.email ?? '');
    final relationshipController =
        TextEditingController(text: contact?.relationship ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyTextField(
                    controller: nameController,
                    hintText: 'Name',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  MyTextField(
                    controller: phoneController,
                    hintText: 'Phone',
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 12),
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  MyTextField(
                    controller: relationshipController,
                    hintText: 'Relationship',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            MyButton(
              text: contact == null ? 'Add' : 'Save',
              width: 100,
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final newContact = Contact(
                  id: contact?.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  relationship: relationshipController.text.trim(),
                );
                if (contact == null) {
                  ref.read(contactProvider.notifier).addContact(newContact);
                } else if (contact.id != null) {
                  ref
                      .read(contactProvider.notifier)
                      .updateContact(contact.id!, newContact);
                }
                Navigator.pop(dialogContext);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactState = ref.watch(contactProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emergency Contacts',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: contactState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : contactState.contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No emergency contacts',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first emergency contact',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(contactProvider.notifier).loadContacts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: contactState.contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contactState.contacts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Text(
                              contact.name.isNotEmpty
                                  ? contact.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            contact.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact.phone),
                              if (contact.relationship != null &&
                                  contact.relationship!.isNotEmpty)
                                Text(
                                  contact.relationship!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showAddEditDialog(contact: contact);
                              } else if (value == 'delete' &&
                                  contact.id != null) {
                                ref
                                    .read(contactProvider.notifier)
                                    .deleteContact(contact.id!);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20,
                                        color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
