import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guardme_app/data/repositories/emergency_repository.dart';
import 'package:guardme_app/domain/entities/contact.dart';
import 'package:guardme_app/domain/entities/emergency_alert.dart';
import 'package:guardme_app/presentation/providers/contact_provider.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:twilio_voice_sms/twilio_voice_sms.dart';
import 'package:url_launcher/url_launcher.dart';

final toolServiceProvider = Provider<ToolService>((ref) {
  return ToolService(ref);
});

class ToolService {
  final Ref _ref;

  ToolService(this._ref);

  static List<Tool> get toolDefinitions => [
        Tool.function(
          name: 'call_emergency_contact',
          description:
              'Call the user\'s emergency contact immediately. Use this when the user is in distress, danger, scared, hurt, or asks for emergency help. Specify contact_name to call a specific person.',
          parameters: {
            'type': 'object',
            'properties': {
              'contact_name': {
                'type': 'string',
                'description':
                    'Optional specific contact name to call. If not provided, calls the first available emergency contact.',
              },
            },
          },
        ),
        Tool.function(
          name: 'get_current_location',
          description:
              'Get the user\'s current GPS location including latitude, longitude, place name, area, and full address. Use this to help with navigation, share your location in emergencies, or provide location-aware assistance.',
          parameters: {
            'type': 'object',
            'properties': {},
          },
        ),
        Tool.function(
          name: 'list_emergency_contacts',
          description:
              'List all the user\'s emergency contacts with their names, phone numbers, and relationships. Use this when the user asks about their contacts or wants to know who is saved.',
          parameters: {
            'type': 'object',
            'properties': {},
          },
        ),
        Tool.function(
          name: 'send_emergency_alert',
          description:
              'Send an emergency alert with current location to all emergency contacts. Use this in serious emergency situations to notify all contacts at once.',
          parameters: {
            'type': 'object',
            'properties': {
              'message': {
                'type': 'string',
                'description': 'Optional message to include with the alert.',
              },
            },
          },
        ),
        Tool.function(
          name: 'send_sms_message',
          description:
              'Send an SMS text message to one of the user\'s emergency contacts. Use this when the user wants to send a specific message to a specific person, or to check in with someone. Specify contact_name to send to a specific person.',
          parameters: {
            'type': 'object',
            'properties': {
              'contact_name': {
                'type': 'string',
                'description':
                    'Optional specific contact name to send the SMS to. If not provided, sends to the first available emergency contact.',
              },
              'message': {
                'type': 'string',
                'description': 'The message content to send via SMS.',
              },
            },
            'required': ['message'],
          },
        ),
      ];

  Future<Map<String, dynamic>> executeTool(ToolCall toolCall) async {
    switch (toolCall.function.name) {
      case 'call_emergency_contact':
        final args = toolCall.function.argumentsMap;
        return emergencyCall(contactName: args['contact_name'] as String?);
      case 'get_current_location':
        return _getCurrentLocation();
      case 'list_emergency_contacts':
        return _listContacts();
      case 'send_emergency_alert':
        return _sendEmergencyAlert(toolCall);
      case 'send_sms_message':
        final args = toolCall.function.argumentsMap;
        return _sendSms(
          contactName: args['contact_name'] as String?,
          message: args['message'] as String? ?? '',
        );
      default:
        return {'error': 'Unknown tool: ${toolCall.function.name}'};
    }
  }

  Future<Map<String, dynamic>> emergencyCall({String? contactName}) async {
    try {
      final contactState = _ref.read(contactProvider);
      var contacts = contactState.contacts;

      if (contacts.isEmpty) {
        await _ref.read(contactProvider.notifier).loadContacts();
        contacts = _ref.read(contactProvider).contacts;
      }

      if (contacts.isEmpty) {
        return {'success': false, 'error': 'No emergency contacts available'};
      }

      Contact target;
      if (contactName != null && contactName.isNotEmpty) {
        final match = contacts.where(
          (c) => c.name.toLowerCase().contains(contactName.toLowerCase()),
        );
        if (match.isEmpty) {
          return {
            'success': false,
            'error': 'Contact "$contactName" not found. Available contacts: ${contacts.map((c) => c.name).join(', ')}',
          };
        }
        target = match.first;
      } else {
        target = contacts.first;
      }

      final uri = Uri(scheme: 'tel', path: target.phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return {
          'success': true,
          'contactName': target.name,
          'phone': target.phone,
        };
      } else {
        return {
          'success': false,
          'error': 'Cannot initiate call to ${target.name}: phone dialer not available',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Failed to call: $e'};
    }
  }

  Future<Map<String, dynamic>> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'error': 'Location service is disabled'};
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'error': 'Location permission denied'};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {'error': 'Location permission permanently denied'};
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final result = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
      };

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final pName = p.name;
          final pStreet = p.street;
          final pSubLocality = p.subLocality;
          final pLocality = p.locality;
          final pAdminArea = p.administrativeArea;
          final pCountry = p.country;
          final nameParts = <String>[
            if (pName != null && pName.isNotEmpty) pName,
            if (pStreet != null && pStreet.isNotEmpty) pStreet,
          ];
          final areaParts = <String>[
            if (pSubLocality != null && pSubLocality.isNotEmpty)
              pSubLocality,
            if (pLocality != null && pLocality.isNotEmpty) pLocality,
            if (pAdminArea != null && pAdminArea.isNotEmpty) pAdminArea,
            if (pCountry != null && pCountry.isNotEmpty) pCountry,
          ];
          final placeName = nameParts.isNotEmpty ? nameParts.join(', ') : null;
          final area = areaParts.isNotEmpty ? areaParts.join(', ') : null;
          result['place_name'] = placeName;
          result['area'] = area;
          result['address'] = [if (placeName != null) placeName, if (area != null) area]
              .join(', ');
        }
      } catch (_) {
        // Reverse geocoding failed — coordinates are still available
      }

      return result;
    } catch (e) {
      return {'error': 'Failed to get location: $e'};
    }
  }

  Future<Map<String, dynamic>> _listContacts() async {
    try {
      final contactState = _ref.read(contactProvider);
      var contacts = contactState.contacts;

      if (contacts.isEmpty) {
        await _ref.read(contactProvider.notifier).loadContacts();
        contacts = _ref.read(contactProvider).contacts;
      }

      return {
        'contacts': contacts.map((c) => {
          'name': c.name,
          'phone': c.phone,
          if (c.relationship != null) 'relationship': c.relationship,
          if (c.email != null) 'email': c.email,
        }).toList(),
      };
    } catch (e) {
      return {'error': 'Failed to load contacts: $e'};
    }
  }

  Future<Map<String, dynamic>> _sendEmergencyAlert(ToolCall toolCall) async {
    try {
      final args = toolCall.function.argumentsMap;
      final message = args['message'] as String?;

      double? lat;
      double? lng;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition();
            lat = pos.latitude;
            lng = pos.longitude;
          }
        }
      } catch (_) {}

      final repo = _ref.read(emergencyRepositoryProvider);
      final alert = await repo.createAlert(EmergencyAlert(
        message: message,
        latitude: lat,
        longitude: lng,
        status: 'SENT',
      ));

      return {
        'success': true,
        'alertId': alert.id,
        'message': message,
        'includedLocation': lat != null,
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to send alert: $e'};
    }
  }

  Future<Map<String, dynamic>> _sendSms({
    String? contactName,
    required String message,
  }) async {
    try {
      final contactState = _ref.read(contactProvider);
      var contacts = contactState.contacts;

      if (contacts.isEmpty) {
        await _ref.read(contactProvider.notifier).loadContacts();
        contacts = _ref.read(contactProvider).contacts;
      }

      if (contacts.isEmpty) {
        return {'success': false, 'error': 'No emergency contacts available'};
      }

      Contact target;
      if (contactName != null && contactName.isNotEmpty) {
        final match = contacts.where(
          (c) => c.name.toLowerCase().contains(contactName.toLowerCase()),
        );
        if (match.isEmpty) {
          return {
            'success': false,
            'error': 'Contact "$contactName" not found. Available contacts: ${contacts.map((c) => c.name).join(', ')}',
          };
        }
        target = match.first;
      } else {
        target = contacts.first;
      }

      final msg = await FlutterTwilio.instance.sms.send(
        to: target.phone,
        body: message,
      );

      return {
        'success': true,
        'contactName': target.name,
        'phone': target.phone,
        'status': msg.status,
      };
    } on TwilioSmsException catch (e) {
      return {
        'success': false,
        'error': 'SMS failed: ${e.message} (code: ${e.twilioCode})',
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to send SMS: $e'};
    }
  }
}
