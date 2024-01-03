import 'package:flutter/material.dart';
import 'package:geminiaichatbot/shared_functions.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key});

  Future<dynamic> fetchChatHistory() async {
    try {
      dynamic response = await makeGETRequest('/history');
      if (response['responseType'] == 'success') {
        return response['message'];
      } else {
        return null; // Return null if response type is not success
      }
    } catch (error) {
      print('Error fetching chat history: $error');
      return null; // Return null if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
      ),
      body: FutureBuilder(
        future: fetchChatHistory(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Failed to fetch chat history'));
          } else {
            List<dynamic> chats = snapshot.data as List<dynamic>;
            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: const Color(0xFF4CAF50), // Setting the background color of the Card
                  child: ListTile(
                    title: Text(
                      chats[index]['chat_title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      // Handle what happens when a chat is tapped
                      // Access UUID via chats[index]['chat_session']
                      saveAccessTokenInMemory('session', chats[index]['chat_session']);
                      Navigator.pop(context, true); // Pass any data back to the previous screen
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}