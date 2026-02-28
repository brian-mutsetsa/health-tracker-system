import 'package:hive/hive.dart';

part 'checkin_model.g.dart';

@HiveType(typeId: 0)
class CheckinModel extends HiveObject {
  @HiveField(0)
  final String condition;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final Map<String, String> answers;

  @HiveField(3)
  final String riskLevel;

  @HiveField(4)
  final String riskColor;

  CheckinModel({
    required this.condition,
    required this.date,
    required this.answers,
    required this.riskLevel,
    required this.riskColor,
  });
}