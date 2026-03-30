import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

Future<Database> openAppDatabase() async {
  return databaseFactoryWeb.openDatabase('artemis_work_planner.db');
}
