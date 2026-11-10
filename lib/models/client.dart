import 'sync_status.dart';

class Client {
  final String id;
  final String name;
  final double? lat;
  final double? lng;
  final double? locationAccuracy;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  const Client({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
    this.locationAccuracy,
    required this.createdAt,
    this.syncStatus = SyncStatus.synced,
  });

  bool get hasLocation => lat != null && lng != null;

  String get locationText {
    if (!hasLocation) {
      return 'Location not captured';
    }
    return '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}';
  }

  /// Backward-compatibility getter for previous workshops/tests
  bool get isSynced => syncStatus == SyncStatus.synced;

  /// Serialization for Supabase (Business data only)
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'location_accuracy_m': locationAccuracy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Serialization for SQLite (Includes local synchronization status)
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'location_accuracy_m': locationAccuracy,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus.name,
    };
  }

  /// Backward-compatibility map serialization
  Map<String, dynamic> toMap() => toSupabaseMap();

  factory Client.fromSupabaseMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'].toString(),
      name: map['name'] as String,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      locationAccuracy: (map['location_accuracy_m'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      syncStatus: SyncStatus.synced,
    );
  }

  factory Client.fromLocalMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      locationAccuracy: (map['location_accuracy_m'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      syncStatus: SyncStatus.values.firstWhere(
        (status) => status.name == map['sync_status'],
        orElse: () => SyncStatus.pending,
      ),
    );
  }

  /// Backward-compatibility factory
  factory Client.fromMap(Map<String, dynamic> map) {
    if (map.containsKey('sync_status')) {
      return Client.fromLocalMap(map);
    }
    final status = (map['is_synced'] == 1 || map['is_synced'] == true)
        ? SyncStatus.synced
        : SyncStatus.pending;
    return Client(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      locationAccuracy: (map['location_accuracy_m'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      syncStatus: status,
    );
  }

  @override
  String toString() =>
      'Client(id: $id, name: $name, lat: $lat, lng: $lng, syncStatus: $syncStatus)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
