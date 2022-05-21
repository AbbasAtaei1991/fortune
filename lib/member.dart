import 'package:isar/isar.dart';
part 'member.g.dart';

@Collection()
class Member {
  @Id()
  int? id;

  late String name;
}
