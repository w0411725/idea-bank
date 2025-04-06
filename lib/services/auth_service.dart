import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  
  User? _user;
  User? get currentUser => _user;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  bool get isAuthenticated => _user != null;
  
  AuthService() {
    // Initialize user from session if available
    _user = _client.auth.currentUser;
    
    // Listen for auth state changes
    _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        _user = session.user;
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });
  }
  
  // Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      _user = response.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _client.auth.resetPasswordForEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    await _client.auth.signOut();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }
  
  // Get user ID
  String? getUserId() {
    return _user?.id;
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}