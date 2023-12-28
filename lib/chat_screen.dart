import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatBubble> _messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GeminiAIChatBot',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  return _messages[index];
                },
              ),
            ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty) {
      _sendMessage(text);
      _textController.clear();
    }
  }

  void _sendMessage(String message) async {
    setState(() {
      _messages.add(ChatBubble(
        message: message,
        isMe: true,
        bgColor: const Color(0xFF4CAF50),
      ));
    });

    try {
      dynamic response = await sendPrompt(message);
      _displayReply(message, response);
    } catch (error) {
      _displayReply(message, error.toString());
    }
  }

  void _displayReply(String question, String reply) {
    setState(() {
      if (_messages.isNotEmpty && _messages.last is ChatBubble) {
        final lastMessage = _messages.last as ChatBubble;
        if (lastMessage.isMe && lastMessage.message == question) {
          _messages.removeLast(); // Remove the last question message
        }
      }

      _messages.add(
        ChatBubble(
          message: question,
          isMe: true,
          bgColor: const Color(0xFF4CAF50),
          onLongPress: () {
            FlutterClipboard.copy(question);
          },
        ),
      );

      _messages.add(
        ChatBubble(
          message: reply,
          isMe: false,
          bgColor: const Color(0xFFDDDDDD),
          child: MarkdownBody(data: reply),
          onLongPress: () {
            FlutterClipboard.copy(reply);
          },
        ),
      );
    });
  }

  Future<dynamic> sendPrompt(String message) async {
    String url = 'https://chat.waithakasam.tech/api/android/chat';
    Map<String, dynamic> postData = {'prompt': message};

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(postData),
      );

      if (response.statusCode == 200) {
        dynamic jsonResponse = jsonDecode(response.body);
        return jsonResponse['message'];
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to post data: $error');
    }
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message',
                hintStyle: TextStyle(color: Colors.black54),
              ),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: const Color(0xFF4CAF50),
            onPressed: () {
              _handleSubmitted(_textController.text);
            },
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final Color bgColor;
  final Widget? child;
  final VoidCallback? onLongPress;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.bgColor,
    this.child,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: child ?? Text(message),
        ),
      ),
    );
  }
}