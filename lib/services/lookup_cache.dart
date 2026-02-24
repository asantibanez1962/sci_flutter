class LookupCache {
  static final Map<String, Map<int, String>> _cache = {};

  static bool has(String entity) => _cache.containsKey(entity);

  static Map<int, String>? get(String entity) => _cache[entity];

  static void set(String entity, Map<int, String> data) {
    _cache[entity] = data;
  }
}