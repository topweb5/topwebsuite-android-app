import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.phone = '',
    this.country = '',
    this.timezone = 'Africa/Lagos',
    this.roleTitle = '',
    this.avatar,
    this.isEmailVerified = false,
    this.trialRemaining,
  });

  final int id;
  final String email;
  final String username;
  final String fullName;
  final String phone;
  final String country;
  final String timezone;
  final String roleTitle;
  final String? avatar;
  final bool isEmailVerified;
  final int? trialRemaining;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName:
          json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? 'Africa/Lagos',
      roleTitle: json['role_title']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      isEmailVerified: json['is_email_verified'] == true,
      trialRemaining: int.tryParse('${json['trial_remaining'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'phone': phone,
      'country': country,
      'timezone': timezone,
      'role_title': roleTitle,
      'avatar': avatar,
      'is_email_verified': isEmailVerified,
      'trial_remaining': trialRemaining,
    };
  }

  String get displayName => fullName.isNotEmpty ? fullName : username;

  @override
  List<Object?> get props => [
    id,
    email,
    username,
    fullName,
    phone,
    country,
    timezone,
    roleTitle,
    avatar,
    isEmailVerified,
    trialRemaining,
  ];
}
