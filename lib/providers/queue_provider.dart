import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import '../models/queue_state.dart';
import '../models/sync_status.dart';
import '../repositories/queue_repository.dart';
import '../services/geolocation_service.dart';
import '../storage/local_queue_storage.dart';

class QueueProvider extends ChangeNotifier {
  final QueueRepository _repository;
  final GeolocationService _geolocationService;
  final List<Client> _clients = [];
  QueueState _state = QueueState.initial;
  String? _errorMessage;
  int _page = 0;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  RealtimeChannel? _realtimeChannel;

  /// Production constructor — requires explicit dependencies
  QueueProvider(this._repository, this._geolocationService) {
    _subscribeRealtime();
  }

  /// Named-parameter factory used by older tests that pass localDb + geoService
  factory QueueProvider.withDependencies({
    required dynamic supabaseClient,
    required GeolocationService geoService,
    required dynamic localDb,
  }) {
    final storage = localDb is LocalQueueStorage
        ? localDb
        : LocalQueueStorage(inMemory: true);
    final repo = QueueRepository(supabase: supabaseClient, storage: storage);
    return QueueProvider(repo, geoService);
  }

  List<Client> get clients => List.unmodifiable(_clients);
  QueueState get state => _state;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchInitialQueue() async {
    _state = QueueState.loading;
    _page = 0;
    _hasMore = true;
    notifyListeners();
    try {
      final data = await _repository.fetchPage(offset: 0, limit: _pageSize);
      _clients.clear();
      _clients.addAll(data);
      _state = _clients.isEmpty ? QueueState.empty : QueueState.loaded;
      if (data.length < _pageSize) _hasMore = false;
    } catch (e) {
      _errorMessage = 'Failed to load queue';
      _state = QueueState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      _page++;
      final newClients = await _repository.fetchPage(
        offset: _page * _pageSize,
        limit: _pageSize,
      );
      final existingIds = _clients.map((c) => c.id).toSet();
      final uniqueNewClients =
          newClients.where((c) => !existingIds.contains(c.id));
      _clients.addAll(uniqueNewClients);
      if (newClients.length < _pageSize) _hasMore = false;
    } catch (_) {
      _page--;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    final client = _repository.supabaseClient;
    if (client == null) return;
    try {
      _realtimeChannel = client
          .channel('public:clients')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'clients',
            callback: (payload) {
              final record = payload.newRecord;
              if (record.isNotEmpty) {
                final newClient = Client.fromSupabaseMap(record);
                handleRealtimeInsert(newClient);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'clients',
            callback: (payload) {
              final deletedId = payload.oldRecord['id']?.toString();
              if (deletedId != null) {
                _clients.removeWhere((c) => c.id == deletedId);
                if (_clients.isEmpty) _state = QueueState.empty;
                notifyListeners();
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void handleRealtimeInsert(Client client) {
    final exists = _clients.any((c) => c.id == client.id);
    if (!exists) {
      _clients.add(client);
      if (_state == QueueState.empty || _state == QueueState.initial) {
        _state = QueueState.loaded;
      }
      notifyListeners();
    }
  }

  Future<String?> addClient(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Client name cannot be empty';
    }

    final position = await _geolocationService.getCurrentPosition();

    final newClient = Client(
      id: const Uuid().v4(),
      name: trimmed,
      lat: position?.latitude,
      lng: position?.longitude,
      locationAccuracy: position?.accuracy,
      createdAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    await _repository.saveClientLocally(newClient);

    // Append at end (FIFO order: first registered = first in queue)
    _clients.add(newClient);
    if (_state == QueueState.empty || _state == QueueState.initial) {
      _state = QueueState.loaded;
    }
    notifyListeners();

    try {
      await _repository.registerOnServer(newClient);
      await _repository.storage.updateSyncStatus(newClient.id, SyncStatus.synced);
      final idx = _clients.indexWhere((c) => c.id == newClient.id);
      if (idx != -1) {
        _clients[idx] = Client(
          id: newClient.id,
          name: newClient.name,
          lat: newClient.lat,
          lng: newClient.lng,
          locationAccuracy: newClient.locationAccuracy,
          createdAt: newClient.createdAt,
          syncStatus: SyncStatus.synced,
        );
        notifyListeners();
      }
    } catch (_) {
      // Offline fallback: persists as pending
    }

    return null;
  }

  Future<String?> removeClient(String id) async {
    _clients.removeWhere((c) => c.id == id);
    if (_clients.isEmpty) {
      _state = QueueState.empty;
    }
    notifyListeners();
    await _repository.removeClient(id);
    return null;
  }

  Future<String?> nextClient() async {
    if (_clients.isEmpty) return 'Queue is empty';
    final first = _clients.first;
    return await removeClient(first.id);
  }

  Future<void> refresh() async {
    await fetchInitialQueue();
  }

  @override
  void dispose() {
    final client = _repository.supabaseClient;
    final ch = _realtimeChannel;
    if (client != null && ch != null) {
      client.removeChannel(ch);
    }
    super.dispose();
  }
}
