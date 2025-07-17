import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './LoginPage.dart';
import './HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dtzbdxysjcjwvmnishhs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR0emJkeHlzamNqd3ZtbmlzaGhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0NTg5MzMsImV4cCI6MjA2NDAzNDkzM30.oy1oSSLNbG98OdwpxeMloF1YWvydCBlYuin9pqvJpfo',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: Supabase.instance.client.auth.currentSession != null
          ? const HomePage()
          : const LoginPage(),
    );
  }
}