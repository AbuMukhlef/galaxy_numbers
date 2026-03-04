import 'package:hive/hive.dart';
part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) final DateTime createdAt;
  @HiveField(3) String selectedPath;

  UserModel({required this.id, required this.name, required this.createdAt, required this.selectedPath});

  factory UserModel.create({required String name, required String selectedPath}) => UserModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: name, createdAt: DateTime.now(), selectedPath: selectedPath);

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'created_at': createdAt.toIso8601String(), 'selected_path': selectedPath};

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'], name: j['name'],
    createdAt: DateTime.parse(j['created_at']), selectedPath: j['selected_path']);
}
