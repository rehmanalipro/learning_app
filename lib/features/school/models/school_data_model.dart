class EmergencyContactModel {
  final String name;
  final String phone;

  const EmergencyContactModel({
    required this.name,
    required this.phone,
  });

  EmergencyContactModel copyWith({
    String? name,
    String? phone,
  }) {
    return EmergencyContactModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) {
    return EmergencyContactModel(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }
}

class NoticePostModel {
  final String id;
  final String title;
  final String body;
  final String authorName;
  final String authorRole;
  final String category;
  final DateTime createdAt;
  /// 'school' (visible to all) or 'class' (scoped to className+section).
  final String scope;
  final String? className;
  final String? section;

  const NoticePostModel({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorRole,
    required this.category,
    required this.createdAt,
    this.scope = 'school',
    this.className,
    this.section,
  });

  NoticePostModel copyWith({
    String? id,
    String? title,
    String? body,
    String? authorName,
    String? authorRole,
    String? category,
    DateTime? createdAt,
    String? scope,
    String? className,
    String? section,
  }) {
    return NoticePostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      scope: scope ?? this.scope,
      className: className ?? this.className,
      section: section ?? this.section,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'authorName': authorName,
      'authorRole': authorRole,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'scope': scope,
      'className': className,
      'section': section,
    };
  }

  factory NoticePostModel.fromMap(Map<String, dynamic> map) {
    return NoticePostModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      authorRole: map['authorRole'] as String? ?? '',
      category: map['category'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      scope: map['scope'] as String? ?? 'school',
      className: map['className'] as String?,
      section: map['section'] as String?,
    );
  }
}

class SchoolDataModel {
  final String announcement;
  final List<NoticePostModel> noticePosts;
  final String schoolName;
  final String schoolLocation;
  final String schoolFounded;
  final String publicationProfile;
  final List<EmergencyContactModel> emergencyContacts;
  final String? schoolImagePath;
  final bool notificationsEnabled;
  final bool darkModeEnabled;

  const SchoolDataModel({
    required this.announcement,
    required this.noticePosts,
    required this.schoolName,
    required this.schoolLocation,
    required this.schoolFounded,
    required this.publicationProfile,
    required this.emergencyContacts,
    this.schoolImagePath,
    required this.notificationsEnabled,
    required this.darkModeEnabled,
  });

  SchoolDataModel copyWith({
    String? announcement,
    List<NoticePostModel>? noticePosts,
    String? schoolName,
    String? schoolLocation,
    String? schoolFounded,
    String? publicationProfile,
    List<EmergencyContactModel>? emergencyContacts,
    String? schoolImagePath,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
  }) {
    return SchoolDataModel(
      announcement: announcement ?? this.announcement,
      noticePosts: noticePosts ?? this.noticePosts,
      schoolName: schoolName ?? this.schoolName,
      schoolLocation: schoolLocation ?? this.schoolLocation,
      schoolFounded: schoolFounded ?? this.schoolFounded,
      publicationProfile: publicationProfile ?? this.publicationProfile,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      schoolImagePath: schoolImagePath ?? this.schoolImagePath,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
    );
  }

  Map<String, dynamic> toMap({
    required Map<String, List<String>> readNoticeIdsByRole,
  }) {
    return {
      'announcement': announcement,
      'noticePosts': noticePosts.map((item) => item.toMap()).toList(growable: false),
      'schoolName': schoolName,
      'schoolLocation': schoolLocation,
      'schoolFounded': schoolFounded,
      'publicationProfile': publicationProfile,
      'emergencyContacts': emergencyContacts
          .map((item) => item.toMap())
          .toList(growable: false),
      'schoolImagePath': schoolImagePath,
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
      'readNoticeIdsByRole': readNoticeIdsByRole,
    };
  }

  factory SchoolDataModel.fromMap(Map<String, dynamic> map) {
    return SchoolDataModel(
      announcement: map['announcement'] as String? ?? '',
      noticePosts: (map['noticePosts'] as List<dynamic>? ?? const [])
          .map((item) => NoticePostModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      schoolName: map['schoolName'] as String? ?? '',
      schoolLocation: map['schoolLocation'] as String? ?? '',
      schoolFounded: map['schoolFounded'] as String? ?? '',
      publicationProfile: map['publicationProfile'] as String? ?? '',
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>? ?? const [])
          .map((item) => EmergencyContactModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      schoolImagePath: map['schoolImagePath'] as String?,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      darkModeEnabled: map['darkModeEnabled'] as bool? ?? false,
    );
  }
}
