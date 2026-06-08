class Profile {
  final String id;
  final String? name;
  final String? photoUrl;
  final String? phone;
  final String? bio;
  final String accountType;
  final String verificationStatus;
  final String? organizationName;
  final String? verificationNote;
  final DateTime? verificationRequestedAt;
  final DateTime? verifiedAt;
  final String trustedAccountStatus;
  final DateTime? trustReviewedAt;
  final String? trustNote;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.name,
    this.photoUrl,
    this.phone,
    this.bio,
    this.accountType = 'individual',
    this.verificationStatus = 'unverified',
    this.organizationName,
    this.verificationNote,
    this.verificationRequestedAt,
    this.verifiedAt,
    this.trustedAccountStatus = 'standard',
    this.trustReviewedAt,
    this.trustNote,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String?,
      photoUrl: json['photo_url'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      accountType: json['account_type'] as String? ?? 'individual',
      verificationStatus:
          json['verification_status'] as String? ?? 'unverified',
      organizationName: json['organization_name'] as String?,
      verificationNote: json['verification_note'] as String?,
      verificationRequestedAt: json['verification_requested_at'] == null
          ? null
          : DateTime.parse(json['verification_requested_at'] as String),
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      trustedAccountStatus:
          json['trusted_account_status'] as String? ?? 'standard',
      trustReviewedAt: json['trust_reviewed_at'] == null
          ? null
          : DateTime.parse(json['trust_reviewed_at'] as String),
      trustNote: json['trust_note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isVerified => verificationStatus == 'verified';

  bool get isTrusted => trustedAccountStatus == 'trusted';

  bool get isVerificationPending => verificationStatus == 'pending';

  bool get isNgo => accountType == 'ngo';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
      'account_type': accountType,
      'verification_status': verificationStatus,
      if (organizationName != null) 'organization_name': organizationName,
      if (verificationNote != null) 'verification_note': verificationNote,
      if (verificationRequestedAt != null)
        'verification_requested_at': verificationRequestedAt!.toIso8601String(),
      if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? name,
    String? photoUrl,
    String? phone,
    String? bio,
    String? accountType,
    String? organizationName,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      accountType: accountType ?? this.accountType,
      verificationStatus: verificationStatus,
      organizationName: organizationName ?? this.organizationName,
      verificationNote: verificationNote,
      verificationRequestedAt: verificationRequestedAt,
      verifiedAt: verifiedAt,
      trustedAccountStatus: trustedAccountStatus,
      trustReviewedAt: trustReviewedAt,
      trustNote: trustNote,
      createdAt: createdAt,
    );
  }
}
