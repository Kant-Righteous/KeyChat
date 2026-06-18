import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KeyChat'),
      ),
      body: const Center(
        child: Text('No conversations yet'),
      ),
    );
  }
}
