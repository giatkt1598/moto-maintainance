part of 'app_database.dart';

class MaintenanceSeed {
  const MaintenanceSeed({
    required this.name,
    required this.description,
    required this.intervalMinKm,
    required this.intervalMaxKm,
    this.intervalMinDays = 0,
    this.intervalMaxDays = 0,
  });

  final String name;
  final String description;
  final int intervalMinKm;
  final int intervalMaxKm;
  final int intervalMinDays;
  final int intervalMaxDays;
}

const _mandatoryInsuranceSeed = MaintenanceSeed(
  name: 'Gia hạn bảo hiểm bắt buộc',
  description: 'Kiểm tra và gia hạn bảo hiểm trách nhiệm dân sự bắt buộc',
  intervalMinKm: 0,
  intervalMaxKm: 0,
  intervalMinDays: 365,
  intervalMaxDays: 365,
);

extension VehicleProfileSeeds on VehicleProfile {
  List<MaintenanceSeed> get seedItems {
    return switch (this) {
      VehicleProfile.scooter => const [
        MaintenanceSeed(
          name: 'Thay nhớt máy',
          description: 'Thay nhớt động cơ định kỳ',
          intervalMinKm: 2000,
          intervalMaxKm: 4000,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        MaintenanceSeed(
          name: 'Thay nhớt láp',
          description: 'Thay dầu hộp số xe ga',
          intervalMinKm: 8000,
          intervalMaxKm: 12000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay lọc gió',
          description: 'Kiểm tra vệ sinh hoặc thay lọc gió',
          intervalMinKm: 8000,
          intervalMaxKm: 12000,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        MaintenanceSeed(
          name: 'Vệ sinh/thay lọc gió CVT',
          description: 'Vệ sinh hoặc thay lọc gió hộp dây đai CVT',
          intervalMinKm: 4000,
          intervalMaxKm: 8000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay bugi',
          description: 'Kiểm tra và thay bugi khi cần',
          intervalMinKm: 8000,
          intervalMaxKm: 12000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay dây curoa CVT',
          description: 'Kiểm tra độ mòn và thay dây curoa truyền động CVT',
          intervalMinKm: 20000,
          intervalMaxKm: 24000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay má phanh',
          description: 'Kiểm tra độ mòn má phanh',
          intervalMinKm: 6000,
          intervalMaxKm: 12000,
        ),
        MaintenanceSeed(
          name: 'Thay dầu phanh',
          description: 'Thay dầu phanh định kỳ',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 730,
          intervalMaxDays: 730,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra lốp xe',
          description: 'Kiểm tra áp suất, gai lốp và tình trạng lốp',
          intervalMinKm: 3000,
          intervalMaxKm: 5000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra ắc quy',
          description: 'Kiểm tra điện áp và tình trạng ắc quy',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        _mandatoryInsuranceSeed,
      ],
      VehicleProfile.manualClutch => const [
        MaintenanceSeed(
          name: 'Thay nhớt máy',
          description: 'Thay nhớt động cơ định kỳ',
          intervalMinKm: 4000,
          intervalMaxKm: 6000,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        MaintenanceSeed(
          name: 'Thay lọc nhớt',
          description: 'Thay lọc nhớt động cơ',
          intervalMinKm: 8000,
          intervalMaxKm: 12000,
        ),
        MaintenanceSeed(
          name: 'Vệ sinh và tra sên',
          description: 'Vệ sinh và tra sên',
          intervalMinKm: 500,
          intervalMaxKm: 1000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay lọc gió',
          description: 'Kiểm tra vệ sinh hoặc thay lọc gió',
          intervalMinKm: 8000,
          intervalMaxKm: 12000,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay bugi',
          description: 'Kiểm tra và thay bugi khi cần',
          intervalMinKm: 12000,
          intervalMaxKm: 24000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra khe hở xu-páp',
          description: 'Kiểm tra và điều chỉnh khe hở xu-páp',
          intervalMinKm: 12000,
          intervalMaxKm: 24000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay má phanh',
          description: 'Kiểm tra độ mòn má phanh',
          intervalMinKm: 6000,
          intervalMaxKm: 12000,
        ),
        MaintenanceSeed(
          name: 'Thay dầu phanh',
          description: 'Thay dầu phanh định kỳ',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 730,
          intervalMaxDays: 730,
        ),
        MaintenanceSeed(
          name: 'Thay nước làm mát',
          description: 'Thay nước làm mát động cơ',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 1095,
          intervalMaxDays: 1095,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra lốp xe',
          description: 'Kiểm tra áp suất, gai lốp và tình trạng lốp',
          intervalMinKm: 3000,
          intervalMaxKm: 5000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra ắc quy',
          description: 'Kiểm tra điện áp và tình trạng ắc quy',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        _mandatoryInsuranceSeed,
      ],
      VehicleProfile.underbone => const [
        MaintenanceSeed(
          name: 'Thay nhớt máy',
          description: 'Thay nhớt động cơ định kỳ',
          intervalMinKm: 3000,
          intervalMaxKm: 4000,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        MaintenanceSeed(
          name: 'Vệ sinh và tra sên',
          description: 'Vệ sinh và tra sên',
          intervalMinKm: 500,
          intervalMaxKm: 1000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay lọc gió',
          description: 'Kiểm tra vệ sinh hoặc thay lọc gió',
          intervalMinKm: 8000,
          intervalMaxKm: 12000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay bugi',
          description: 'Kiểm tra và thay bugi khi cần',
          intervalMinKm: 8000,
          intervalMaxKm: 12000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra phanh',
          description: 'Kiểm tra phanh, bố thắng và độ ăn phanh',
          intervalMinKm: 4000,
          intervalMaxKm: 8000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra lốp xe',
          description: 'Kiểm tra áp suất, gai lốp và tình trạng lốp',
          intervalMinKm: 3000,
          intervalMaxKm: 5000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra dây ga/cáp điều khiển',
          description: 'Kiểm tra độ rơ và tình trạng dây ga, cáp điều khiển',
          intervalMinKm: 4000,
          intervalMaxKm: 6000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra ắc quy',
          description: 'Kiểm tra điện áp và tình trạng ắc quy',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        _mandatoryInsuranceSeed,
      ],
      VehicleProfile.electricMotorbike => const [
        MaintenanceSeed(
          name: 'Kiểm tra pin/ắc quy',
          description: 'Kiểm tra tình trạng pin hoặc ắc quy',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 180,
          intervalMaxDays: 180,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra bộ sạc và cổng sạc',
          description: 'Kiểm tra bộ sạc, cổng sạc và tiếp điểm sạc',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 180,
          intervalMaxDays: 180,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra dây điện và giắc cắm',
          description: 'Kiểm tra dây điện, giắc cắm và đầu nối',
          intervalMinKm: 5000,
          intervalMaxKm: 8000,
          intervalMinDays: 180,
          intervalMaxDays: 180,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay má phanh',
          description: 'Kiểm tra độ mòn má phanh',
          intervalMinKm: 5000,
          intervalMaxKm: 8000,
        ),
        MaintenanceSeed(
          name: 'Thay dầu phanh',
          description: 'Thay dầu phanh định kỳ',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 730,
          intervalMaxDays: 730,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra lốp xe',
          description: 'Kiểm tra áp suất, gai lốp và tình trạng lốp',
          intervalMinKm: 3000,
          intervalMaxKm: 5000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra dây curoa/xích truyền động',
          description:
              'Kiểm tra độ mòn và độ căng của dây curoa hoặc xích truyền động',
          intervalMinKm: 8000,
          intervalMaxKm: 12000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra phuộc/giảm xóc',
          description: 'Kiểm tra rò dầu, độ nhún và tình trạng phuộc/giảm xóc',
          intervalMinKm: 10000,
          intervalMaxKm: 12000,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        _mandatoryInsuranceSeed,
      ],
      VehicleProfile.bicycle => const [
        MaintenanceSeed(
          name: 'Vệ sinh và tra dầu xích',
          description: 'Vệ sinh và tra dầu xích',
          intervalMinKm: 300,
          intervalMaxKm: 800,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra lốp và áp suất',
          description: 'Kiểm tra áp suất, gai lốp, săm và tình trạng lốp',
          intervalMinKm: 200,
          intervalMaxKm: 500,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra/thay má phanh',
          description: 'Kiểm tra độ mòn má phanh và độ ăn phanh',
          intervalMinKm: 800,
          intervalMaxKm: 1500,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra cáp phanh/sang số',
          description:
              'Kiểm tra độ trơn, gỉ sét và tình trạng cáp phanh/sang số',
          intervalMinKm: 1500,
          intervalMaxKm: 2500,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra truyền động',
          description: 'Kiểm tra xích, líp, đĩa và bộ chuyển động',
          intervalMinKm: 1500,
          intervalMaxKm: 2500,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra bạc đạn',
          description: 'Kiểm tra độ rơ bánh xe, trục giữa, cổ phốt và pedal',
          intervalMinKm: 4000,
          intervalMaxKm: 6000,
        ),
        MaintenanceSeed(
          name: 'Bảo dưỡng tổng quát',
          description:
              'Kiểm tra tổng thể khung, bánh, phanh, truyền động và ốc siết',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
      ],
      VehicleProfile.other => const [
        MaintenanceSeed(
          name: 'Kiểm tra tổng quát',
          description: 'Kiểm tra tình trạng vận hành tổng thể',
          intervalMinKm: 1000,
          intervalMaxKm: 1500,
          intervalMinDays: 180,
          intervalMaxDays: 180,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra phanh',
          description: 'Kiểm tra độ ăn phanh và độ mòn má phanh',
          intervalMinKm: 3000,
          intervalMaxKm: 5000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra lốp xe',
          description: 'Kiểm tra áp suất và độ mòn lốp',
          intervalMinKm: 3000,
          intervalMaxKm: 5000,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra ắc quy/pin',
          description: 'Kiểm tra tình trạng ắc quy hoặc pin nếu có',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 365,
          intervalMaxDays: 365,
        ),
        MaintenanceSeed(
          name: 'Kiểm tra hệ thống điện',
          description: 'Kiểm tra dây điện, giắc cắm, đèn, còi và công tắc',
          intervalMinKm: 0,
          intervalMaxKm: 0,
          intervalMinDays: 180,
          intervalMaxDays: 180,
        ),
        _mandatoryInsuranceSeed,
      ],
    };
  }
}
