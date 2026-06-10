import 'dart:async';
import 'dart:io';

import '../../data/api/api_client.dart';

/// Turns any thrown error / provider error value into a short, human-friendly
/// message safe to show a user. Raw exceptions (SocketException, DioException,
/// "Bad state: ...", stack traces) never reach the UI.
///
/// Usage:
///   _error = friendlyError(error);              // in providers
///   message: friendlyError(provider.error)      // in widgets (accepts String/Object/null)
String friendlyError(Object? error, {String? fallback}) {
  final fb = fallback ?? 'Something went wrong. Please try again.';
  if (error == null) return fb;

  // Backend gave us an intentional, already-friendly message.
  if (error is ApiException) {
    final msg = error.message.trim();
    if (msg.isNotEmpty && !_looksRaw(msg)) return msg;
    return _byStatus(error.statusCode, fb);
  }

  // Network-level failures: no connection / DNS / timeout.
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException) {
    return "Can't reach the server. Check your connection and try again.";
  }

  // A String error already stored on a provider (e.g. _error = ...).
  if (error is String) {
    final s = error.trim();
    if (s.isEmpty) return fb;
    return _looksRaw(s) ? _cleanRaw(s, fb) : s;
  }

  return _cleanRaw(error.toString(), fb);
}

/// Friendly copy for common HTTP status codes.
String _byStatus(int status, String fallback) {
  switch (status) {
    case 400:
      return "That didn't work. Please check and try again.";
    case 401:
    case 403:
      return 'Your session expired. Please sign in again.';
    case 404:
      return "We couldn't find that. It may have been removed.";
    case 408:
      return 'The request timed out. Please try again.';
    case 429:
      return "You're going a bit fast. Please wait a moment and try again.";
    default:
      if (status >= 500) {
        return 'The server is having trouble right now. Please try again soon.';
      }
      return fallback;
  }
}

/// Heuristic: does this string look like a raw exception rather than a
/// user-facing sentence?
bool _looksRaw(String s) {
  final lower = s.toLowerCase();
  return lower.contains('exception') ||
      lower.contains('bad state') ||
      lower.contains('errno') ||
      lower.contains('failed host lookup') ||
      lower.contains('stack trace') ||
      lower.startsWith('type ') ||
      s.contains('#0 ');
}

/// Pull a usable sentence out of a raw error, else fall back.
String _cleanRaw(String raw, String fallback) {
  final lower = raw.toLowerCase();
  // google_sign_in surfaces config/device issues as
  // PlatformException(sign_in_failed, ...ApiException: 10/12500...).
  if (lower.contains('sign_in_failed') ||
      lower.contains('sign_in_canceled') ||
      lower.contains('id token')) {
    return "Google sign-in didn't work. Please try again or log in with email.";
  }
  if (lower.contains('socket') ||
      lower.contains('host lookup') ||
      lower.contains('connection') ||
      lower.contains('network')) {
    return "Can't reach the server. Check your connection and try again.";
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'The request timed out. Please try again.';
  }
  return fallback;
}
