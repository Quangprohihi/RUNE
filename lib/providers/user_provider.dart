import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/errors/friendly_error.dart';
import '../data/api/api_client.dart';
import '../data/repositories/auth_token_repository.dart';
import '../data/repositories/user_repository.dart';
import '../models/pet.dart';
import '../models/user_profile.dart';
import '../models/wallet.dart';

class UserProvider extends ChangeNotifier {
  UserProvider(
    this._repository,
    this._tokenRepository,
    this._api, {
    GoogleSignIn? googleSignIn,
  }) : _profile = _repository.load(),
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             serverClientId: _googleWebClientId.isNotEmpty
                 ? _googleWebClientId
                 : null,
           ) {
    _restoreSession();
  }

  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '281605282360-r6jn53e5inivskto405t3k3vdaglcdt7.apps.googleusercontent.com',
  );

  final UserRepository _repository;
  final AuthTokenRepository _tokenRepository;
  final ApiClient _api;
  final GoogleSignIn _googleSignIn;
  UserProfile _profile;
  Wallet? _latestWallet;
  Pet? _latestPet;
  Map<String, dynamic>? _latestStreak;
  bool _isLoading = false;
  bool _isRestoringSession = false;
  bool _accountSwitched = false;
  String? _error;

  UserProfile get profile => _profile;
  Wallet? get latestWallet => _latestWallet;
  Pet? get latestPet => _latestPet;
  Map<String, dynamic>? get latestStreak => _latestStreak;
  bool get isLoading => _isLoading;
  bool get isRestoringSession => _isRestoringSession;
  String? get error => _error;

  bool get hasLoggedIn => _profile.hasLoggedIn && _profile.id.isNotEmpty;

  /// True exactly once after a sign-in by a different account than the one
  /// whose data was on this device. The login flow uses it to reset all
  /// account-scoped providers before syncing the new user's server data.
  bool consumeAccountSwitched() {
    final switched = _accountSwitched;
    _accountSwitched = false;
    return switched;
  }

  Future<void> _restoreSession() async {
    _isRestoringSession = true;
    notifyListeners();
    try {
      final accessToken = await _tokenRepository.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        _api.accessToken = accessToken;
      }
      _api.userId = _profile.id.isNotEmpty ? _profile.id : null;

      if (_profile.hasLoggedIn && _profile.id.isNotEmpty) {
        // Adopt installs from before account-switch tracking existed: the
        // data on this device belongs to the restored (still signed-in) user.
        if (_repository.loadCurrentUserId() == null) {
          await _repository.saveCurrentUserId(_profile.id);
        }
        await _repository.migrateLegacyOnboardingFlag(_profile.id);
      }

      if (_profile.hasLoggedIn &&
          ((accessToken != null && accessToken.isNotEmpty) ||
              await _tokenRepository.hasRefreshToken())) {
        await refreshBootstrap();
      }
    } catch (_) {
      await _clearLocalSession();
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.post(
                '/auth/login',
                body: {'email': email.trim(), 'password': password},
              )
              as Map<String, dynamic>;
      await _applyAuthResponse(response);
      await _repository.save(_profile);
    } catch (error) {
      _error = friendlyError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _api.post(
                '/auth/register',
                body: {
                  'displayName': displayName.trim(),
                  'email': email.trim(),
                  'password': password,
                },
              )
              as Map<String, dynamic>;
      await _applyAuthResponse(response);
      await _repository.save(_profile);
    } catch (error) {
      _error = friendlyError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns false when the user dismissed the Google account picker —
  /// a deliberate action, not an error, so no message should be shown.
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Clear the cached Google account so users can choose another account
      // when they return to the login screen.
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google did not return an ID token');
      }

      final response =
          await _api.post('/auth/google', body: {'idToken': idToken})
              as Map<String, dynamic>;
      await _applyAuthResponse(response);
      await _repository.save(_profile);
      return true;
    } catch (error) {
      _error = friendlyError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBootstrap() async {
    if (!hasLoggedIn && !await _tokenRepository.hasRefreshToken()) return;
    try {
      final response = await _api.get('/me/bootstrap') as Map<String, dynamic>;
      _applyBootstrap(response);
      await _repository.save(_profile);
      notifyListeners();
    } catch (error) {
      _error = friendlyError(error);
      // Only end the session when the server rejected our credentials.
      // A network blip must not log the user out (and strand their local
      // data for whoever signs in next).
      if (error is ApiException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        await _clearLocalSession();
      }
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenRepository.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _api.post('/auth/logout', body: {'refreshToken': refreshToken});
      } catch (_) {}
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _clearLocalSession();
    notifyListeners();
  }

  Future<void> _clearLocalSession() async {
    _profile = UserProfile.guest();
    _latestWallet = null;
    _latestPet = null;
    _latestStreak = null;
    _api.invalidateSession();
    await _tokenRepository.clear();
    await _repository.clear();
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> response) async {
    final accessToken = response['accessToken'] as String?;
    final refreshToken = response['refreshToken'] as String?;
    if (accessToken == null ||
        refreshToken == null ||
        accessToken.isEmpty ||
        refreshToken.isEmpty) {
      throw StateError('Auth response did not include tokens');
    }

    await _tokenRepository.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    _api.accessToken = accessToken;
    _applyBootstrap(response);

    // A different account than the one whose data lives on this device just
    // signed in (covers brand-new accounts too): wipe the previous user's
    // local progress so nothing leaks into the new session.
    final previousUserId = _repository.loadCurrentUserId();
    if (previousUserId != _profile.id) {
      await _repository.clearAccountScopedData();
      _accountSwitched = true;
    } else {
      await _repository.migrateLegacyOnboardingFlag(_profile.id);
    }
    await _repository.saveCurrentUserId(_profile.id);
  }

  void _applyBootstrap(Map<String, dynamic> response) {
    final user = response['user'] as Map<String, dynamic>? ?? const {};
    _profile = UserProfile(
      id: user['id'] as String? ?? '',
      displayName: user['displayName'] as String? ?? 'Friend',
      email: user['email'] as String? ?? '',
      hasLoggedIn: true,
    );
    _api.userId = _profile.id;
    _latestWallet = Wallet.fromJson(
      response['wallet'] as Map<String, dynamic>? ?? const {},
    );
    _latestPet = Pet.fromJson(
      response['pet'] as Map<String, dynamic>? ?? const {},
    );
    _latestStreak = response['streak'] as Map<String, dynamic>?;
  }
}
