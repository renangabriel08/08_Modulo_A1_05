import 'package:a1/pages/genius.dart';
import 'package:a1/pages/home.dart';
import 'package:a1/pages/memo.dart';
import 'package:a1/pages/quiz.dart';
import 'package:a1/styles/styles.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Cores.azulClaro),
      ),
      routes: {
        '/quiz': (context) => Quiz(),
        '/home': (context) => Home(),
        '/genius': (context) => Genius(),
        '/memo': (context) => Memo(),
      },
      initialRoute: '/home',
    );
  }
}
