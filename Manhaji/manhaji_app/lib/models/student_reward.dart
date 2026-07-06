enum StudentRewardCategory { avatar, frame, badge, garden }

class StudentRewardDefinition {
  const StudentRewardDefinition({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.requiredStars,
  });

  final String id;
  final StudentRewardCategory category;
  final String name;
  final String description;
  final int requiredStars;

  bool isUnlocked(int totalStars) => totalStars >= requiredStars;

  int remainingStars(int totalStars) {
    final remaining = requiredStars - totalStars;
    return remaining > 0 ? remaining : 0;
  }
}

const List<StudentRewardDefinition> studentRewardCatalog = [
  StudentRewardDefinition(
    id: 'avatar-reader',
    category: StudentRewardCategory.avatar,
    name: 'قارئ صغير',
    description: 'صورة رمزية لمحبي القراءة',
    requiredStars: 50,
  ),
  StudentRewardDefinition(
    id: 'avatar-explorer',
    category: StudentRewardCategory.avatar,
    name: 'مستكشف المعرفة',
    description: 'صورة رمزية لرحلة التعلم',
    requiredStars: 100,
  ),
  StudentRewardDefinition(
    id: 'frame-olive',
    category: StudentRewardCategory.frame,
    name: 'إطار الزيتون',
    description: 'إطار بسيط حول صورتك الرمزية',
    requiredStars: 100,
  ),
  StudentRewardDefinition(
    id: 'frame-stars',
    category: StudentRewardCategory.frame,
    name: 'إطار النجوم',
    description: 'إطار مضيء لإنجازاتك',
    requiredStars: 150,
  ),
  StudentRewardDefinition(
    id: 'badge-streak',
    category: StudentRewardCategory.badge,
    name: 'شارة المثابر',
    description: 'شارة تشجع الاستمرار اليومي',
    requiredStars: 50,
  ),
  StudentRewardDefinition(
    id: 'badge-reader',
    category: StudentRewardCategory.badge,
    name: 'شارة القارئ',
    description: 'شارة للطلاب الذين يحبون الدروس',
    requiredStars: 120,
  ),
  StudentRewardDefinition(
    id: 'badge-quiz-hero',
    category: StudentRewardCategory.badge,
    name: 'شارة بطل الاختبارات',
    description: 'شارة شكلية للاجتهاد في الاختبارات',
    requiredStars: 180,
  ),
  StudentRewardDefinition(
    id: 'garden-flower',
    category: StudentRewardCategory.garden,
    name: 'زهرة',
    description: 'أول نبتة في حديقة مناهجي',
    requiredStars: 80,
  ),
  StudentRewardDefinition(
    id: 'garden-reading-chair',
    category: StudentRewardCategory.garden,
    name: 'كرسي قراءة',
    description: 'مكان هادئ للقراءة في الحديقة',
    requiredStars: 150,
  ),
  StudentRewardDefinition(
    id: 'garden-tree',
    category: StudentRewardCategory.garden,
    name: 'شجرة صغيرة',
    description: 'شجرة تنمو مع إنجازاتك',
    requiredStars: 200,
  ),
  StudentRewardDefinition(
    id: 'garden-glow-star',
    category: StudentRewardCategory.garden,
    name: 'نجمة مضيئة',
    description: 'زينة لطيفة في حديقة مناهجي',
    requiredStars: 250,
  ),
];

List<StudentRewardDefinition> rewardsForCategory(
  StudentRewardCategory category,
) {
  return studentRewardCatalog
      .where((reward) => reward.category == category)
      .toList(growable: false);
}

String rewardCategoryLabel(StudentRewardCategory category) {
  return switch (category) {
    StudentRewardCategory.avatar => 'الصور الرمزية',
    StudentRewardCategory.frame => 'الإطارات',
    StudentRewardCategory.badge => 'الشارات',
    StudentRewardCategory.garden => 'حديقة مناهجي',
  };
}
