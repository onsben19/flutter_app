import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/journal/journal_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel App',
      theme: AppTheme.lightTheme,
      home: JournalScreen(), //
    );
  }
}
