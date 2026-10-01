class UserModel {
  final int? id;
  final String? userId;
  final String? username;
  final String? email;
  final String? avatar;
  final String? bio;
  final int credits;
  final int level;
  final DateTime? membershipExpiry;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool isSuperuser;
  final String? oauthProvider;
  final String? oauthId;
  final bool hasPassword;

  UserModel({
    this.id,
    this.userId,
    this.username,
    this.email,
    this.avatar,
    this.bio,
    this.credits = 0,
    this.level = 0,
    this.membershipExpiry,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.isSuperuser = false,
    this.oauthProvider,
    this.oauthId,
    this.hasPassword = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      email: json['email'],
      avatar: json['avatar'],
      bio: json['bio'],
      credits: json['credits'] ?? 0,
      level: json['level'] ?? 0,
      membershipExpiry: json['membership_expiry'] != null
          ? DateTime.parse(json['membership_expiry'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isActive: json['is_active'] ?? true,
      isSuperuser: json['is_superuser'] ?? false,
      oauthProvider: json['oauth_provider'],
      oauthId: json['oauth_id'],
      hasPassword: json['has_password'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'email': email,
      'avatar': avatar,
      'bio': bio,
      'credits': credits,
      'level': level,
      'membership_expiry': membershipExpiry?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'oauth_provider': oauthProvider,
      'oauth_id': oauthId,
      'has_password': hasPassword,
    };
  }

  UserModel copyWith({
    int? id,
    String? userId,
    String? username,
    String? email,
    String? avatar,
    String? bio,
    int? credits,
    int? level,
    DateTime? membershipExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isSuperuser,
    String? oauthProvider,
    String? oauthId,
    bool? hasPassword,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      credits: credits ?? this.credits,
      level: level ?? this.level,
      membershipExpiry: membershipExpiry ?? this.membershipExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isSuperuser: isSuperuser ?? this.isSuperuser,
      oauthProvider: oauthProvider ?? this.oauthProvider,
      oauthId: oauthId ?? this.oauthId,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }

  bool get isPremium => level >= 1;
  bool get isPro => level >= 2;
  bool get isMembershipActive =>
      membershipExpiry != null && membershipExpiry!.isAfter(DateTime.now());
}
