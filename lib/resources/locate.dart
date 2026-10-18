/// Where a value from session data points. Skills name images and animations as `data:` URIs, http(s) URLs,
/// `/res/...` paths under the ovos-gui cache, or absolute paths on the OVOS host (OCP). The desktop reads the last
/// two from disk; the web build fetches them from the sidecar's `/res/` and `/res-abs/` routes.
library;

enum ResourceKind { data, http, cache, absolute, none }

class Resource {
  const Resource(this.kind, this.value);

  const Resource.none() : this(ResourceKind.none, '');

  /// The data URI, the URL, the path relative to the cache root, or the absolute path.
  final String value;
  final ResourceKind kind;

  bool get isImage => kind == ResourceKind.data ? value.startsWith('data:image/') : imageSuffixes.contains(suffix);

  String get suffix {
    final dot = value.lastIndexOf('.');
    return dot < 0 ? '' : value.substring(dot).toLowerCase();
  }
}

const imageSuffixes = {'.svg', '.png', '.jpg', '.jpeg', '.gif', '.webp'};
const cachePrefix = '/res/';
const _fileScheme = 'file://';

Resource locate(String? value) {
  final src = (value ?? '').trim();
  if (src.startsWith('data:')) return Resource(ResourceKind.data, src);
  if (src.startsWith('http://') || src.startsWith('https://')) return Resource(ResourceKind.http, src);
  if (src.startsWith(cachePrefix)) return Resource(ResourceKind.cache, src.substring(cachePrefix.length));
  final path = src.replaceFirst(_fileScheme, '');
  if (path.startsWith('/')) return Resource(ResourceKind.absolute, path);
  return const Resource.none();
}
