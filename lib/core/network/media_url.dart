/// Batalat — Media / API URL helpers
import '../constants/app_constants.dart';

/// Resolves a media path from the API into a full URL the device can load.
String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  final origin = AppConstants.apiOrigin;
  if (path.startsWith('/')) {
    return '$origin$path';
  }
  return '$origin/$path';
}
