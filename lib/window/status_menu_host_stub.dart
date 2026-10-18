import 'status_menu.dart';

class StatusMenuHost {
  StatusMenuHost({required void Function(String id) onSelected});

  void show(List<MenuEntry> items) {}
}
