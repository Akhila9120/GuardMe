import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/data/repositories/contact_repository.dart';
import 'package:guardme_app/domain/entities/contact.dart';

class ContactState {
  final List<Contact> contacts;
  final bool isLoading;
  final String? error;

  const ContactState({
    this.contacts = const [],
    this.isLoading = false,
    this.error,
  });

  ContactState copyWith({
    List<Contact>? contacts,
    bool? isLoading,
    String? error,
  }) {
    return ContactState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ContactNotifier extends StateNotifier<ContactState> {
  final Ref _ref;

  ContactNotifier(this._ref) : super(const ContactState());

  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(contactRepositoryProvider);
      final contacts = await repo.getContacts();
      state = ContactState(contacts: contacts);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addContact(Contact contact) async {
    try {
      final repo = _ref.read(contactRepositoryProvider);
      final created = await repo.createContact(contact);
      state = state.copyWith(contacts: [...state.contacts, created]);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateContact(int id, Contact contact) async {
    try {
      final repo = _ref.read(contactRepositoryProvider);
      final updated = await repo.updateContact(id, contact);
      final list = state.contacts.map((c) {
        return c.id == id ? updated : c;
      }).toList();
      state = state.copyWith(contacts: list);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      final repo = _ref.read(contactRepositoryProvider);
      await repo.deleteContact(id);
      final list = state.contacts.where((c) => c.id != id).toList();
      state = state.copyWith(contacts: list);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final contactProvider =
    StateNotifierProvider<ContactNotifier, ContactState>((ref) {
  return ContactNotifier(ref);
});
