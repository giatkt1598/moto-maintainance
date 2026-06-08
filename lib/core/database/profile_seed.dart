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
    };
  }
}
