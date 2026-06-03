class InterviewModel {
  final int? id;
  final String jobTitle;
  final String companyName;
  final String? notes;
  final DateTime interviewDateTime;
  final DateTime? createdAt;

  InterviewModel({
    this.id,
    required this.jobTitle,
    required this.companyName,
    this.notes,
    required this.interviewDateTime,
    this.createdAt,
  });

  factory InterviewModel.fromMap(Map<String, dynamic> map) {
    return InterviewModel(
      id: map['id'] as int?,
      jobTitle: map['job_title'] as String,
      companyName: map['company_name'] as String,
      notes: map['notes'] as String?,
      interviewDateTime: DateTime.parse(map['interview_date_time'] as String),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'job_title': jobTitle,
      'company_name': companyName,
      'notes': notes,
      'interview_date_time': interviewDateTime.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  InterviewModel copyWith({
    int? id,
    String? jobTitle,
    String? companyName,
    String? notes,
    DateTime? interviewDateTime,
    DateTime? createdAt,
  }) {
    return InterviewModel(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      notes: notes ?? this.notes,
      interviewDateTime: interviewDateTime ?? this.interviewDateTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isUpcoming => interviewDateTime.isAfter(DateTime.now());

  Duration get timeUntilInterview => interviewDateTime.difference(DateTime.now());

  @override
  String toString() {
    return 'InterviewModel(id: $id, jobTitle: $jobTitle, companyName: $companyName, '
        'interviewDateTime: $interviewDateTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InterviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}