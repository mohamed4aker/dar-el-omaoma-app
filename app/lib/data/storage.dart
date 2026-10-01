import 'package:shared_preferences/shared_preferences.dart';

/// Where the app keeps its data between launches.
///
/// Everything lives in one JSON document. The app is offline-first: a phone
/// holds the hospital's catalogue, the accounts registered on it and their
/// bookings. A shared server (so bookings made on a patient's phone reach the
/// reception's phone) replaces this class and nothing above it.
abstract interface class StorageBackend {
  Future<String?> read();
  Future<void> write(String document);
}

class PrefsStorage implements StorageBackend {
  static const _key = 'dar_el_omouma.store.v1';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String document) async =>
      (await SharedPreferences.getInstance()).setString(_key, document);
}

/// Keeps the document in memory only. Used by tests.
class MemoryStorage implements StorageBackend {
  MemoryStorage([this.document]);

  String? document;
  int writes = 0;

  @override
  Future<String?> read() async => document;

  @override
  Future<void> write(String value) async {
    document = value;
    writes++;
  }
}
