import 'package:flutter/material.dart';
import 'package:keychat/app/app_shell.dart';

class KeyChatApp extends StatelessWidget {
  const KeyChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyChat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
