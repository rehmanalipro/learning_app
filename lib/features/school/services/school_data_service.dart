import 'package:get/get.dart';

import '../../../core/services/firestore_collection_service.dart';
import '../models/school_data_model.dart';

class SchoolDataService extends GetxService {
  static const _documentPath = 'school_data/main';

  final FirestoreCollectionService _store = FirestoreCollectionService();
  final Rx<SchoolDataModel> schoolData = _defaultSchoolData().obs;
  final RxInt feedRevision = 0.obs;
  final Map<String, Set<String>> readNoticeIdsByRole = {
    'student': <String>{},
    'teacher': <String>{},
    'principal': <String>{},
  };

  static SchoolDataModel _defaultSchoolData() {
    return SchoolDataModel(
      announcement: 'Tomorrow assembly will start at 8:00 AM.',
      noticePosts: [
        NoticePostModel(
          id: 'notice-1',
          title: 'Morning Assembly Timing Updated',
          body:
              'Tomorrow assembly will start at 8:00 AM. All students must arrive on time in proper uniform and line formation.',
          authorName: 'Ayesha Khan',
          authorRole: 'Principal',
          category: 'Notice',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
      schoolName: 'Creative Reader\'s Public School',
      schoolLocation: 'Main Campus, Karachi',
      schoolFounded: 'Founded in 2012',
      publicationProfile:
          'Creative Reader\'s Publication supports school notes, books, and learning material for all classes.',
      emergencyContacts: const [
        EmergencyContactModel(name: 'School Office', phone: '+92 300 1111111'),
      ],
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
    final raw = await _store.getRawDocument(_documentPath);
    if (raw == null) {
      await persistSchoolData();
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
    feedRevision.value++;
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
  }) async {
    final post = NoticePostModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      authorName: authorName,
      authorRole: authorRole,
      category: category,
      createdAt: DateTime.now(),
    );

    schoolData.value = schoolData.value.copyWith(
      announcement: title,
      noticePosts: [post, ...sortedNoticePosts],
    );
    await persistSchoolData();
    feedRevision.value++;
  }

  List<NoticePostModel> unreadPostsForRole(String role) {
    final key = role.toLowerCase();
    final readIds = readNoticeIdsByRole[key] ?? <String>{};
    return sortedNoticePosts
        .where((post) => !readIds.contains(post.id))
        .toList(growable: false);
  }

  int unreadNoticeCountForRole(String role) {
    if (!schoolData.value.notificationsEnabled) return 0;
    return unreadPostsForRole(role).length;
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
    readNoticeIdsByRole[role.toLowerCase()] =
        sortedNoticePosts.map((item) => item.id).toSet();
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
