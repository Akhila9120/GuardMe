class EmergencyAlert {
  final int? id;
  final DateTime? alertTime;
  final String? message;
  final String? status;
  final double? latitude;
  final double? longitude;

  EmergencyAlert({
    this.id,
    this.alertTime,
    this.message,
    this.status,
    this.latitude,
    this.longitude,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'] as int?,
      alertTime: json['alertTime'] != null
          ? DateTime.parse(json['alertTime'] as String)
          : null,
      message: json['message'] as String?,
      status: json['status'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (alertTime != null) 'alertTime': alertTime!.toIso8601String(),
      if (message != null) 'message': message,
      if (status != null) 'status': status,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  bool get isResolved => status == 'RESOLVED';
  bool get isSent => status == 'SENT';
}
