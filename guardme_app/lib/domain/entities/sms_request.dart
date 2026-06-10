class SmsRequest {
  final int contactId;
  final String message;

  SmsRequest({
    required this.contactId,
    required this.message,
  });

  factory SmsRequest.fromJson(Map<String, dynamic> json) {
    return SmsRequest(
      contactId: json['contactId'] as int,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contactId': contactId,
      'message': message,
    };
  }
}
