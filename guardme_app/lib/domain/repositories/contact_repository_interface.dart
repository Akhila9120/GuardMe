import 'package:guardme_app/domain/entities/contact.dart';

abstract class ContactRepositoryInterface {
  Future<List<Contact>> getContacts();
  Future<Contact> createContact(Contact contact);
  Future<Contact> updateContact(int id, Contact contact);
  Future<void> deleteContact(int id);
}
