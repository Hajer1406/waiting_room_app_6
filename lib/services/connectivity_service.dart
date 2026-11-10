import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final SupabaseClient? _supabase;
  final bool _useStub;

  ConnectivityService(
    this._supabase, {
    Connectivity? connectivity,
    bool useStub = false,
  })  : _connectivity = connectivity ?? Connectivity(),
        _useStub = useStub;

  Future<bool> hasNetwork() async {
    if (_useStub) return true;
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Stream<bool> get networkChanges {
    if (_useStub) return const Stream.empty();
    return _connectivity.onConnectivityChanged.map(
      (results) => results.any((result) => result != ConnectivityResult.none),
    );
  }

  Future<bool> isSupabaseAvailable() async {
    if (_useStub) return true;
    final supabase = _supabase;
    if (supabase == null) return false;
    try {
      await supabase
          .from('clients')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }
}
