import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/student_reward.dart';

void main() {
  group('StudentRewardDefinition', () {
    test('calculates locked and unlocked state from star count', () {
      const reward = StudentRewardDefinition(
        id: 'test-reward',
        category: StudentRewardCategory.badge,
        name: 'اختبار',
        description: 'مكافأة اختبار',
        requiredStars: 100,
      );

      expect(reward.isUnlocked(99), isFalse);
      expect(reward.isUnlocked(100), isTrue);
      expect(reward.isUnlocked(150), isTrue);
      expect(reward.remainingStars(40), 60);
      expect(reward.remainingStars(100), 0);
    });

    test('groups rewards by category safely', () {
      final gardenRewards = rewardsForCategory(StudentRewardCategory.garden);

      expect(gardenRewards, isNotEmpty);
      expect(
        gardenRewards.every(
          (reward) => reward.category == StudentRewardCategory.garden,
        ),
        isTrue,
      );
      expect(rewardCategoryLabel(StudentRewardCategory.garden), 'حديقة مناهجي');
    });
  });
}
