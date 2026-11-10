import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client.dart';
import '../storage/local_queue_storage.dart';

class QueueRepository {
  final SupabaseClient? _supabase;
  final LocalQueueStorage _storage;

  QueueRepository({
    SupabaseClient? supabase,
    LocalQueueStorage? storage,
  })  : _supabase = supabase,
        _storage = storage ?? LocalQueueStorage();

  LocalQueueStorage get storage => _storage;
  SupabaseClient? get supabaseClient => _supabase;

  Stream<List<Client>>? get realtimeStream {
    final client = _supabase;
    if (client == null) return null;
    return client
        .from('clients')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((rows) => rows.map((r) => Client.fromSupabaseMap(r)).toList());
  }

  /// Fetches a paginated slice of clients ordered by created_at
  Future<List<Client>> fetchPage({
    required int offset,
    required int limit,
  }) async {
    final supabase = _supabase;
    if (supabase == null) {
      // No Supabase: load from local storage only
      return _fetchLocalPage(offset, limit);
    }
    try {
      final response = await supabase
          .from('clients')
          .select()
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      final list = (response as List)
          .map((item) => Client.fromSupabaseMap(item as Map<String, dynamic>))
          .toList();

      // Persist to local storage as synced
      for (final client in list) {
        await _storage.saveClient(client.toLocalMap());
      }

      return list;
    } catch (_) {
      // Offline fallback: load from local SQLite
      return _fetchLocalPage(offset, limit);
    }
  }

  Future<List<Client>> _fetchLocalPage(int offset, int limit) async {
    final localRows = await _storage.getClients();
    final clients = localRows.map((m) => Client.fromLocalMap(m)).toList();
    if (offset >= clients.length) return [];
    final end = (offset + limit < clients.length) ? offset + limit : clients.length;
    return clients.sublist(offset, end);
  }

  /// Registers a client on Supabase via RPC or upsert
  Future<void> registerOnServer(Client client) async {
    final supabase = _supabase;
    if (supabase == null) throw Exception('No Supabase client available');
    try {
      await supabase.rpc('register_queue_client', params: {
        'p_id': client.id,
        'p_name': client.name,
        'p_lat': client.lat,
        'p_lng': client.lng,
        'p_accuracy': client.locationAccuracy,
        'p_created_at': client.createdAt.toIso8601String(),
      });
    } catch (e) {
      // Fallback to standard upsert if RPC is not created yet
      await supabase.from('clients').upsert(client.toSupabaseMap());
    }
  }

  /// Saves client locally as pending
  Future<void> saveClientLocally(Client client) async {
    await _storage.saveClient(client.toLocalMap());
  }

  /// Removes client both locally and remotely
  Future<void> removeClient(String id) async {
    await _storage.deleteClient(id);
    final supabase = _supabase;
    if (supabase == null) return;
    try {
      await supabase.from('clients').delete().eq('id', id);
    } catch (_) {
      // Silent catch if offline
    }
  }
}

