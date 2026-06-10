class Trip {
  final int? id;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final String? status;
  final int? appUserId;

  Trip({
    this.id,
    this.startTime,
    this.endTime,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.status,
    this.appUserId,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      startLat: (json['startLat'] as num?)?.toDouble(),
      startLng: (json['startLng'] as num?)?.toDouble(),
      endLat: (json['endLat'] as num?)?.toDouble(),
      endLng: (json['endLng'] as num?)?.toDouble(),
      status: json['status'] as String?,
      appUserId: json['appUserId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (startTime != null) 'startTime': startTime!.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      if (startLat != null) 'startLat': startLat,
      if (startLng != null) 'startLng': startLng,
      if (endLat != null) 'endLat': endLat,
      if (endLng != null) 'endLng': endLng,
      if (status != null) 'status': status,
      if (appUserId != null) 'appUserId': appUserId,
    };
  }

  bool get isActive => status == 'ACTIVE' || status == 'STARTED';
  bool get isEmergency => status == 'EMERGENCY';
  bool get isCompleted => status == 'COMPLETED';
}
