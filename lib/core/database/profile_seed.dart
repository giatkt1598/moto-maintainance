part of 'app_database.dart';

class MaintenanceSeed {
  const MaintenanceSeed({
    required this.name,
    required this.description,
    required this.intervalMinKm,
    required this.intervalMaxKm,
  });

  final String name;
  final String description;
  final int intervalMinKm;
  final int intervalMaxKm;
}

extension VehicleProfileSeeds on VehicleProfile {
  List<MaintenanceSeed> get seedItems {
    return switch (this) {
      VehicleProfile.scooter => const [
        MaintenanceSeed(
          name: 'Nhớt máy',
          description: 'Thay nhớt động cơ định kỳ',
          intervalMinKm: 1500,
          intervalMaxKm: 2000,
        ),
        MaintenanceSeed(
          name: 'Nhớt láp',
          description: 'Thay dầu hộp số xe ga',
          intervalMinKm: 5000,
          intervalMaxKm: 7000,
        ),
        MaintenanceSeed(
          name: 'Lọc gió',
          description: 'Kiểm tra vệ sinh hoặc thay lọc gió',
          intervalMinKm: 6000,
          intervalMaxKm: 8000,
        ),
        MaintenanceSeed(
          name: 'Bugi',
          description: 'Kiểm tra và thay bugi khi cần',
          intervalMinKm: 8000,
          intervalMaxKm: 10000,
        ),
      ],
      VehicleProfile.manualClutch => const [
        MaintenanceSeed(
          name: 'Nhớt máy',
          description: 'Thay nhớt động cơ định kỳ',
          intervalMinKm: 1500,
          intervalMaxKm: 2500,
        ),
        MaintenanceSeed(
          name: 'Sên/xên',
          description: 'Vệ sinh và tra sên',
          intervalMinKm: 500,
          intervalMaxKm: 800,
        ),
        MaintenanceSeed(
          name: 'Lọc gió',
          description: 'Kiểm tra vệ sinh hoặc thay lọc gió',
          intervalMinKm: 6000,
          intervalMaxKm: 8000,
        ),
        MaintenanceSeed(
          name: 'Bugi',
          description: 'Kiểm tra và thay bugi khi cần',
          intervalMinKm: 8000,
          intervalMaxKm: 10000,
        ),
      ],
      VehicleProfile.underbone => const [
        MaintenanceSeed(
          name: 'Nhớt máy',
          description: 'Thay nhớt động cơ định kỳ',
          intervalMinKm: 1500,
          intervalMaxKm: 2000,
        ),
        MaintenanceSeed(
          name: 'Sên/xên',
          description: 'Vệ sinh và tra sên',
          intervalMinKm: 500,
          intervalMaxKm: 800,
        ),
        MaintenanceSeed(
          name: 'Bugi',
          description: 'Kiểm tra và thay bugi khi cần',
          intervalMinKm: 8000,
          intervalMaxKm: 10000,
        ),
        MaintenanceSeed(
          name: 'Bố thắng',
          description: 'Kiểm tra độ mòn bố thắng',
          intervalMinKm: 6000,
          intervalMaxKm: 10000,
        ),
      ],
      VehicleProfile.electricMotorbike => const [
        MaintenanceSeed(
          name: 'Má phanh',
          description: 'Kiểm tra độ mòn má phanh',
          intervalMinKm: 5000,
          intervalMaxKm: 8000,
        ),
        MaintenanceSeed(
          name: 'Lốp xe',
          description: 'Kiểm tra áp suất và độ mòn lốp',
          intervalMinKm: 3000,
          intervalMaxKm: 5000,
        ),
        MaintenanceSeed(
          name: 'Pin/ắc quy',
          description: 'Kiểm tra tình trạng pin hoặc ắc quy',
          intervalMinKm: 8000,
          intervalMaxKm: 12000,
        ),
        MaintenanceSeed(
          name: 'Dây điện và giắc cắm',
          description: 'Kiểm tra dây điện, giắc cắm và cổng sạc',
          intervalMinKm: 5000,
          intervalMaxKm: 8000,
        ),
      ],
      VehicleProfile.bicycle => const [
        MaintenanceSeed(
          name: 'Xích',
          description: 'Vệ sinh và tra dầu xích',
          intervalMinKm: 200,
          intervalMaxKm: 400,
        ),
        MaintenanceSeed(
          name: 'Phanh',
          description: 'Kiểm tra má phanh và độ ăn phanh',
          intervalMinKm: 500,
          intervalMaxKm: 800,
        ),
        MaintenanceSeed(
          name: 'Lốp xe',
          description: 'Kiểm tra áp suất, gai lốp và săm',
          intervalMinKm: 500,
          intervalMaxKm: 1000,
        ),
        MaintenanceSeed(
          name: 'Bạc đạn',
          description: 'Kiểm tra độ rơ bánh xe, trục giữa và cổ phốt',
          intervalMinKm: 1500,
          intervalMaxKm: 2500,
        ),
      ],
      VehicleProfile.other => const [
        MaintenanceSeed(
          name: 'Kiểm tra tổng quát',
          description: 'Kiểm tra tình trạng vận hành tổng thể',
          intervalMinKm: 1000,
          intervalMaxKm: 1500,
        ),
        MaintenanceSeed(
          name: 'Phanh',
          description: 'Kiểm tra độ ăn phanh và độ mòn má phanh',
          intervalMinKm: 3000,
          intervalMaxKm: 5000,
        ),
        MaintenanceSeed(
          name: 'Lốp xe',
          description: 'Kiểm tra áp suất và độ mòn lốp',
          intervalMinKm: 3000,
          intervalMaxKm: 5000,
        ),
      ],
    };
  }
}
