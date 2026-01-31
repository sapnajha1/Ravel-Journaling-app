import 'package:journal_app/journal_mode.dart';
import 'package:provider/provider.dart';
import 'package:journal_app/journal_mode.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  JournalMode selectMode = JournalMode.rant;

  double rantAngle = -0.12;
  double scribbleAngle = 0.15;
  double reflectAngle = 0.0;

  void onCardTap(JournalMode mode) {
    selectMode = mode;
    notifyListeners();
  }
}