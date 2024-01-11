import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
import 'package:geminiaichatbot/shared_functions.dart';
import 'history_screen.dart';
import 'login_screen.dart'; // Import your HistoryScreen here
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatBubble> _messages = [];
  final FlutterTts flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _fetchChatId(); // Call the function to make the GET request when the widget is initialized
    // _initializeTts();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    flutterTts.stop(); // Stop speech synthesis when the widget is disposed
    super.dispose();
  }

  Future<void> _initializeTts() async {
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _fetchChatId() async {
    try {
      dynamic response = await makeGETRequest('/initialize_chat');
      _loadChatHistory(); // Load chat history when chat is initialized
    } catch (error) {
      // Handle error
    }
  }

  Future<String> _getTitle() async {
    try {
      dynamic response = await makeGETRequest('/get_title');
      if (response['responseType'] == 'success') {
        return response['message'];
      } else {
        return 'GeminiAIChatBot';
      }
    } catch (error) {
      // Handle error
      return 'GeminiAIChatBot';
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      dynamic response = await makeGETRequest('/load_chat');
      if (response['responseType'] == 'success') {
        _clearChat();
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

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _textController.text = val.recognizedWords;
            });
          },
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        );
      }
    } else {
      print("Listening");
      setState(() => _isListening = false);
      _speech.stop();
      // Send the complete text to the server
      final jsonData = {
        'prompt': _textController.text, // Send the entire text recognized
      };
      makePostRequest(jsonData, '/chat').then((response) {
        if (response['responseType'] == 'success') {
          _displayReply(_textController.text, response['message']);
          _speak(response['message']);
        } else {
          _displayReply(_textController.text, 'An error occurred');
          _speak('An error occurred');
        }
      }).catchError((error) {
        print('Error: $error');
        _displayReply(_textController.text, 'An error occurred');
        _speak('An error occurred');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: FutureBuilder(
            future: _getTitle(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('GeminiAIChatBot');
              } else if (snapshot.hasError || snapshot.data == null) {
                return const Text('GeminiAIChatBot');
              } else {
                return Text(snapshot.data!);
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add), // Icon for new chat
              color: Colors.black,
              onPressed: () {
                flutterTts.stop();
                // set session to null to create a new chat
                saveAccessTokenInMemory('session', 'null');
                _clearChat();
                _fetchChatId();
              },
            ),
            IconButton(
              icon: const Icon(Icons.history), // Replace with your history icon
              color: Colors.black,
              onPressed: () async {
                flutterTts.stop();
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
            IconButton(
              icon: const Icon(Icons.logout), // Icon for new chat
              color: Colors.black,
              onPressed: () {
                flutterTts.stop();
                // Clear all saved values in memory
                saveAccessTokenInMemory('accessToken', "");
                saveAccessTokenInMemory("username", "");
                saveAccessTokenInMemory("password", "");
                //  go to login screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
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
      _speak(response['message']);
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
          // IconButton(
          //   onPressed: () {
          //     _listen();
          //   },
          //   icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
          //   color: const Color(0xFF4CAF50),
          // ),
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
