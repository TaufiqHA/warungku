import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Response DTO dari endpoint autentikasi login
class LoginResponse extends Equatable {
  final String token;
  final String? refreshToken;
  final UserModel user;
  final String? message;

  const LoginResponse({
    required this.token,
    this.refreshToken,
    required this.user,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Menangani payload langsung atau yang dibungkus dalam objek data
    final Map<String, dynamic> payload = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final token = payload['token']?.toString() ??
        payload['jwt_token']?.toString() ??
        payload['access_token']?.toString() ??
        payload['accessToken']?.toString() ??
        json['token']?.toString() ??
        json['access_token']?.toString() ??
        '';

    final refreshToken = payload['refreshToken']?.toString() ??
        payload['refresh_token']?.toString() ??
        json['refreshToken']?.toString() ??
        json['refresh_token']?.toString();

    final Map<String, dynamic> userJson = (payload['user'] is Map)
        ? Map<String, dynamic>.from(payload['user'] as Map)
        : ((json['user'] is Map)
            ? Map<String, dynamic>.from(json['user'] as Map)
            : payload);

    return LoginResponse(
      token: token,
      refreshToken: refreshToken,
      user: UserModel.fromJson(userJson),
      message: json['message']?.toString() ?? payload['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      if (refreshToken != null) 'refreshToken': refreshToken,
      'user': user.toJson(),
      if (message != null) 'message': message,
    };
  }

  @override
  List<Object?> get props => [token, refreshToken, user, message];
}
