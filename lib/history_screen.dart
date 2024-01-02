import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
      ),
      body: const Center(
        child: Text(
          'Your chat history will be displayed here.',
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
