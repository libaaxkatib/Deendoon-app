/// Path fragments relative to `Env.apiBaseUrl`, matching `deendoon/routes/api.php`
/// exactly (flat auth paths, not the older REST spec's `/auth/*` prefix).
class ApiEndpoints {
  static const login = 'login';
  static const register = 'register';
  static const refresh = 'refresh';
  static const logout = 'logout';
  static const forgotPassword = 'forgot-password';
  static const resetPassword = 'reset-password';
  static const googleLogin = 'google-login';
  static const googleRegister = 'google-register';
}
