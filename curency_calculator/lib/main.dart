import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'currency_converter_screen.dart';
import 'currency_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CurrencyService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const CurrencyConverterScreen(),
    );
  }
}