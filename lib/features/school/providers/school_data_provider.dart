import 'package:get/get.dart';

import '../models/school_data_model.dart';
import '../services/school_data_service.dart';

class SchoolDataProvider extends GetxController {
  late final SchoolDataService _service;
  Rx<SchoolDataModel> get schoolData => _service.schoolData;

  @override
  void onInit() {
    super.onInit();
    _service = Get.find<SchoolDataService>();
    loadSchoolData();
  }
  List<NoticePostModel> get sortedNoticePosts => _service.sortedNoticePosts;
  int get feedRevision => _service.feedRevision.value;
  Future<void> loadSchoolData() => _service.loadSchoolData();
  Future<void> updateAnnouncement(String value) =>
      _service.updateAnnouncement(value);
  Future<void> publishNotice({
    required String title,
    required String body,
    required String authorName,
    required String authorRole,
    required String category,
  }) => _service.publishNotice(
    title: title,
    body: body,
    authorName: authorName,
    authorRole: authorRole,
    category: category,
  );
  List<NoticePostModel> unreadPostsForRole(String role) =>
      _service.unreadPostsForRole(role);
  int unreadNoticeCountForRole(String role) =>
      _service.unreadNoticeCountForRole(role);
  bool isNoticeRead(String role, String noticeId) =>
      _service.isNoticeRead(role, noticeId);
  Future<void> markNoticeAsRead({
    required String role,
    required String noticeId,
  }) => _service.markNoticeAsRead(role: role, noticeId: noticeId);
  Future<void> markAllNoticesAsRead(String role) =>
      _service.markAllNoticesAsRead(role);
  Future<void> updateSchoolProfile({
    required String name,
    required String location,
    required String founded,
  }) => _service.updateSchoolProfile(
    name: name,
    location: location,
    founded: founded,
  );
  Future<void> updatePublicationProfile(String value) =>
      _service.updatePublicationProfile(value);
  Future<void> updateEmergencyContacts(List<EmergencyContactModel> contacts) =>
      _service.updateEmergencyContacts(contacts);
  Future<void> updateSchoolImage(String? imagePath) =>
      _service.updateSchoolImage(imagePath);
  Future<void> updateSettings({
    required bool notificationsEnabled,
    required bool darkModeEnabled,
  }) => _service.updateSettings(
    notificationsEnabled: notificationsEnabled,
    darkModeEnabled: darkModeEnabled,
  );
}
