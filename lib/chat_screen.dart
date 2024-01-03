import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
import 'package:geminiaichatbot/shared_functions.dart';
import 'history_screen.dart'; // Import your HistoryScreen here

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatBubble> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchChatId(); // Call the function to make the GET request when the widget is initialized
  }

  Future<void> _fetchChatId() async {
    try {
      dynamic response = await makeGETRequest('/initialize_chat');
      _clearChat();
      _loadChatHistory(); // Load chat history when chat is initialized
    } catch (error) {
      // Handle error
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      dynamic response = await makeGETRequest('/load_chat');
      if (response['responseType'] == 'success') {
        _parseChatHistory(response['message']);
      }
    } catch (error) {
      // Handle error
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear(); // Clear the existing chat messages
    });
  }

  void _parseChatHistory(dynamic messages) {
    try {
      if (messages is List) {
        for (var messagePair in messages) {
          if (messagePair is List && messagePair.length == 2) {
            String userText = messagePair[0]['text'];
            String aiResponse = messagePair[1]['text'];

            _messages.add(ChatBubble(
              message: userText,
              isMe: true, // Assuming user messages are always on the right side
              bgColor: const Color(0xFF4CAF50),
            ));

            _messages.add(ChatBubble(
              message: aiResponse,
              isMe: false, // AI responses are on the left side
              bgColor: const Color(0xFFDDDDDD),
              child: MarkdownBody(data: aiResponse),
            ));
          }
        }
        setState(() {}); // Update the UI after adding messages
      }
    } catch (error) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text(
            'GeminiAIChatBot',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add), // Icon for new chat
              onPressed: () {
                // set session to null to create a new chat
                saveAccessTokenInMemory('session', 'null');
                _fetchChatId();
              },
            ),
            IconButton(
              icon: const Icon(Icons.history), // Replace with your history icon
              onPressed: () async {
                // Navigate to chat history screen and wait for a result
                dynamic result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HistoryScreen()),
                );

                if (result != null) {
                  // Check if the result is not null, perform actions based on the result
                  // For example, call the function that needs to be triggered upon return
                  _fetchChatId();
                }
              },
            ),
          ],
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
      dynamic response = await makePostRequest({'prompt': message}, '/chat');
      _displayReply(message, response['message']);
    } catch (error) {
      _displayReply(message, error.toString());
    }
  }

  void _displayReply(String question, String reply) {
    setState(() {
      if (_messages.isNotEmpty) {
        final lastMessage = _messages.last;
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
