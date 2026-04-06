class ExamScheduleModel {
  final String id;
  final String className;
  final String section;
  final String subject;
  final String uploadedByName;
  final String uploadedByRole;
  final DateTime examDate;
  final int startMinutes;
  final int endMinutes;
  final String shiftLabel;
  final String place;
  final String blockName;
  final String roomNumber;
  final String seatLabel;
  final String description;
  final String? dateSheetName;
  final String? dateSheetPath;
  final DateTime createdAt;

  const ExamScheduleModel({
    required this.id,
    required this.className,
    required this.section,
    required this.subject,
    required this.uploadedByName,
    required this.uploadedByRole,
    required this.examDate,
    required this.startMinutes,
    required this.endMinutes,
    required this.shiftLabel,
    required this.place,
    required this.blockName,
    required this.roomNumber,
    required this.seatLabel,
    required this.description,
    required this.createdAt,
    this.dateSheetName,
    this.dateSheetPath,
  });

  String _formatMinutes(int totalMinutes) {
    final hour24 = totalMinutes ~/ 60;
    final minute = (totalMinutes % 60).toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 == 0 ? 12 : hour24 > 12 ? hour24 - 12 : hour24;
    return '$hour12:$minute $period';
  }

  String get timeRangeLabel =>
      '${_formatMinutes(startMinutes)} - ${_formatMinutes(endMinutes)}';

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'section': section,
      'subject': subject,
      'uploadedByName': uploadedByName,
      'uploadedByRole': uploadedByRole,
      'examDate': examDate.toIso8601String(),
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'shiftLabel': shiftLabel,
      'place': place,
      'blockName': blockName,
      'roomNumber': roomNumber,
      'seatLabel': seatLabel,
      'description': description,
      'dateSheetName': dateSheetName,
      'dateSheetPath': dateSheetPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExamScheduleModel.fromMap(String id, Map<String, dynamic> map) {
    return ExamScheduleModel(
      id: id,
      className: map['className'] as String? ?? '',
      section: map['section'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      uploadedByName: map['uploadedByName'] as String? ?? '',
      uploadedByRole: map['uploadedByRole'] as String? ?? '',
      examDate: DateTime.tryParse(map['examDate'] as String? ?? '') ??
          DateTime.now(),
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 540,
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 600,
      shiftLabel: map['shiftLabel'] as String? ?? 'Morning',
      place: map['place'] as String? ?? '',
      blockName: map['blockName'] as String? ?? '',
      roomNumber: map['roomNumber'] as String? ?? '',
      seatLabel: map['seatLabel'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dateSheetName: map['dateSheetName'] as String?,
      dateSheetPath: map['dateSheetPath'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
