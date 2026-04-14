import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/school_data_model.dart';

class SchoolDataService extends GetxService {
  static const _documentPath = 'school_data/main';
  static const _noticesCollection = 'school_notices';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final Rx<SchoolDataModel> schoolData = _defaultSchoolData().obs;
  final RxInt feedRevision = 0.obs;
  final Map<String, Set<String>> readNoticeIdsByRole = {
    'student': <String>{},
    'teacher': <String>{},
    'principal': <String>{},
  };
  Future<void>? _loadSchoolDataFuture;

  static SchoolDataModel _defaultSchoolData() {
    return SchoolDataModel(
      announcement: '',
      noticePosts: const [],
      schoolName: '',
      schoolLocation: '',
      schoolFounded: '',
      publicationProfile: '',
      emergencyContacts: const [],
      schoolImagePath: null,
      notificationsEnabled: true,
      darkModeEnabled: false,
    );
  }

  List<NoticePostModel> get sortedNoticePosts {
    final posts = schoolData.value.noticePosts.toList(growable: false);
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<void> loadSchoolData() async {
    final inFlight = _loadSchoolDataFuture;
    if (inFlight != null) return inFlight;

    final future = _loadSchoolDataInternal();
    _loadSchoolDataFuture = future;
    return future;
  }

  Future<void> _loadSchoolDataInternal() async {
    try {
      final raw = await _store.getRawDocument(_documentPath);
      if (raw == null) {
        await persistSchoolData();
        await _loadNoticePosts();
        feedRevision.value++;
        return;
      }

      schoolData.value = SchoolDataModel.fromMap(raw);
      final rawReadMap = Map<String, dynamic>.from(
        raw['readNoticeIdsByRole'] as Map? ?? const {},
      );
      readNoticeIdsByRole
        ..clear()
        ..addAll(
          rawReadMap.map<String, Set<String>>(
            (key, value) => MapEntry(
              key,
              (value as List<dynamic>? ?? const [])
                  .map((item) => item.toString())
                  .toSet(),
            ),
          ),
        );
      await _loadNoticePosts(legacyPosts: schoolData.value.noticePosts);
      feedRevision.value++;
    } finally {
      _loadSchoolDataFuture = null;
    }
  }

  Future<void> _loadNoticePosts({
    List<NoticePostModel> legacyPosts = const [],
  }) async {
    final fetched = await _store.getCollection<NoticePostModel>(
      path: _noticesCollection,
      fromMap: (_, data) => NoticePostModel.fromMap(data),
    );

    if (fetched.isEmpty && legacyPosts.isNotEmpty) {
      for (final post in legacyPosts) {
        await _store.setCollectionDocument(
          collectionPath: _noticesCollection,
          id: post.id,
          data: post.toMap(),
          merge: true,
        );
      }
      schoolData.value = schoolData.value.copyWith(
        noticePosts: legacyPosts
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
      return;
    }

    fetched.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    schoolData.value = schoolData.value.copyWith(noticePosts: fetched);
  }

  Future<void> persistSchoolData() {
    return _store.setDocument(
      path: _documentPath,
      data: schoolData.value.toMap(
        readNoticeIdsByRole: {
          for (final entry in readNoticeIdsByRole.entries)
            entry.key: entry.value.toList(growable: false),
        },
      ),
      merge: true,
    );
  }

  Future<void> updateAnnouncement(String value) async {
    schoolData.value = schoolData.value.copyWith(announcement: value);
    await persistSchoolData();
    feedRevision.value++;
  }

  Future<void> publishNotice({
    required String title,
    required String body,
    required String authorName,
    required String authorRole,
    required String category,
    String scope = 'school',
    String? className,
    String? section,
  }) async {
    final post = NoticePostModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      authorName: authorName,
      authorRole: authorRole,
      category: category,
      createdAt: DateTime.now(),
      scope: scope,
      className: className,
      section: section,
    );

    await _store.setCollectionDocument(
      collectionPath: _noticesCollection,
      id: post.id,
      data: post.toMap(),
    );
    schoolData.value = schoolData.value.copyWith(
      announcement: title,
      noticePosts: [post, ...sortedNoticePosts],
    );
    await persistSchoolData();
    feedRevision.value++;
  }

  /// Returns notices visible to [role].
  ///
  /// - principal: all notices.
  /// - others: all scope:'school' notices + scope:'class' notices matching
  ///   [className] and [section].
  List<NoticePostModel> noticesForRole({
    required String role,
    String? className,
    String? section,
  }) {
    if (role.toLowerCase() == 'principal') return sortedNoticePosts;
    return sortedNoticePosts
        .where((post) {
          if (post.scope == 'school') return true;
          return post.scope == 'class' &&
              post.className == className &&
              post.section == section;
        })
        .toList(growable: false);
  }

  List<NoticePostModel> unreadPostsForRole(
    String role, {
    String? className,
    String? section,
  }) {
    final key = role.toLowerCase();
    final readIds = readNoticeIdsByRole[key] ?? <String>{};
    return noticesForRole(
      role: role,
      className: className,
      section: section,
    ).where((post) => !readIds.contains(post.id)).toList(growable: false);
  }

  int unreadNoticeCountForRole(
    String role, {
    String? className,
    String? section,
  }) {
    return unreadPostsForRole(
      role,
      className: className,
      section: section,
    ).length;
  }

  bool isNoticeRead(String role, String noticeId) {
    final key = role.toLowerCase();
    return readNoticeIdsByRole[key]?.contains(noticeId) ?? false;
  }

  Future<void> markNoticeAsRead({
    required String role,
    required String noticeId,
  }) async {
    final key = role.toLowerCase();
    final readIds = readNoticeIdsByRole.putIfAbsent(key, () => <String>{});
    if (readIds.add(noticeId)) {
      await persistSchoolData();
      feedRevision.value++;
    }
  }

  Future<void> markAllNoticesAsRead(String role) async {
    readNoticeIdsByRole[role.toLowerCase()] = sortedNoticePosts
        .map((item) => item.id)
        .toSet();
    await persistSchoolData();
    feedRevision.value++;
  }

  Future<void> updateSchoolProfile({
    required String name,
    required String location,
    required String founded,
  }) async {
    schoolData.value = schoolData.value.copyWith(
      schoolName: name,
      schoolLocation: location,
      schoolFounded: founded,
    );
    await persistSchoolData();
  }

  Future<void> updatePublicationProfile(String value) async {
    schoolData.value = schoolData.value.copyWith(publicationProfile: value);
    await persistSchoolData();
  }

  Future<void> updateEmergencyContacts(
    List<EmergencyContactModel> contacts,
  ) async {
    schoolData.value = schoolData.value.copyWith(emergencyContacts: contacts);
    await persistSchoolData();
  }

  Future<void> updateSchoolImage(String? imagePath) async {
    schoolData.value = schoolData.value.copyWith(schoolImagePath: imagePath);
    await persistSchoolData();
  }

  Future<void> updateSettings({
    required bool notificationsEnabled,
    required bool darkModeEnabled,
  }) async {
    schoolData.value = schoolData.value.copyWith(
      notificationsEnabled: notificationsEnabled,
      darkModeEnabled: darkModeEnabled,
    );
    await persistSchoolData();
    feedRevision.value++;
  }
}
