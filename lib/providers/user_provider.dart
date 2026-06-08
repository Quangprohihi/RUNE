import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  String? _error;

  UserProfile get profile => _profile;
  Wallet? get latestWallet => _latestWallet;
  Pet? get latestPet => _latestPet;
  Map<String, dynamic>? get latestStreak => _latestStreak;
  bool get isLoading => _isLoading;
  bool get isRestoringSession => _isRestoringSession;
  String? get error => _error;

  bool get hasLoggedIn => _profile.hasLoggedIn && _profile.id.isNotEmpty;

  Future<void> _restoreSession() async {
    _isRestoringSession = true;
    notifyListeners();
    try {
      final accessToken = await _tokenRepository.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        _api.accessToken = accessToken;
      }
      _api.userId = _profile.id.isNotEmpty ? _profile.id : null;

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
      _error = error.toString();
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
      _error = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Clear the cached Google account so users can choose another account
      // when they return to the login screen.
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw StateError('Google sign-in was cancelled');
      }

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
    } catch (error) {
      _error = error.toString();
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
      _error = error.toString();
      await _clearLocalSession();
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
    _api.accessToken = null;
    _api.userId = null;
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
